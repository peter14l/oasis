import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:morrow_v2/services/supabase_service.dart';

/// Vault mode service for biometric protection of sensitive content
/// Note: Biometric authentication requires the local_auth package to be added
class VaultService {
  final _storage = const FlutterSecureStorage();
  final _supabase = SupabaseService().client;

  static const _vaultEnabledKey = 'vault_enabled';
  static const _vaultItemsKey = 'vault_items';
  static const _vaultPinKey = 'vault_pin';

  bool _isUnlocked = false;

  /// Check if vault is enabled
  Future<bool> isVaultEnabled() async {
    final enabled = await _storage.read(key: _vaultEnabledKey);
    return enabled == 'true';
  }

  /// Enable vault mode
  Future<void> enableVault({String? pin}) async {
    await _storage.write(key: _vaultEnabledKey, value: 'true');
    if (pin != null) {
      await _storage.write(key: _vaultPinKey, value: pin);
    }
  }

  /// Disable vault mode
  Future<void> disableVault() async {
    await _storage.write(key: _vaultEnabledKey, value: 'false');
    await _storage.delete(key: _vaultPinKey);
    _isUnlocked = true;
  }

  /// Unlock vault with PIN (fallback when biometrics unavailable)
  Future<bool> unlockWithPin(String pin) async {
    final storedPin = await _storage.read(key: _vaultPinKey);
    if (storedPin == pin) {
      _isUnlocked = true;
      return true;
    }
    return false;
  }

  /// Check vault lock status
  bool get isUnlocked => _isUnlocked;

  /// Lock the vault
  void lock() {
    _isUnlocked = false;
  }

  /// Attempt to authenticate (PIN-based for now)
  /// In production, integrate local_auth package for biometrics
  Future<bool> authenticate({String? pin, BuildContext? context}) async {
    if (pin != null) {
      return unlockWithPin(pin);
    }

    // Check if PIN is required
    final hasPin = await _storage.read(key: _vaultPinKey);
    if (hasPin == null) {
      _isUnlocked = true;
      return true;
    }

    // Check if user is Pro for biometric
    final isPro = _supabase.auth.currentUser?.userMetadata?['is_pro'] == true;
    if (isPro) {
      final localAuth = LocalAuthentication();
      try {
        final canCheckBiometrics = await localAuth.canCheckBiometrics;
        final isDeviceSupported = await localAuth.isDeviceSupported();

        if (canCheckBiometrics && isDeviceSupported) {
          final authenticated = await localAuth.authenticate(
            localizedReason: 'Please authenticate to unlock Vault',
            persistAcrossBackgrounding: true,
            biometricOnly: false,
          );
          if (authenticated) {
            _isUnlocked = true;
            return true;
          }
        }
      } catch (e) {
        debugPrint('Biometric auth error: $e');
      }
    }

    // Show PIN dialog if context is provided
    if (context != null && context.mounted) {
      return await _showPinDialog(context);
    }

    return false;
  }

  /// Show PIN dialog for authentication
  Future<bool> _showPinDialog(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Enter PIN'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Enter your 4-digit PIN',
                counterText: '',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) async {
                final isValid = await unlockWithPin(controller.text);
                if (context.mounted) {
                  Navigator.pop(context, isValid);
                }
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final isValid = await unlockWithPin(controller.text);
                  if (context.mounted) {
                    if (!isValid) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Incorrect PIN'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    } else {
                      Navigator.pop(context, true);
                    }
                  }
                },
                child: const Text('Unlock'),
              ),
            ],
          ),
    );
    controller.dispose();
    return result ?? false;
  }

  /// Add item to vault
  Future<void> addToVault({
    required String itemId,
    required VaultItemType type,
  }) async {
    final items = await _getVaultItems();

    // Pro check for limits
    final user = _supabase.auth.currentUser;
    final isPro = user?.userMetadata?['is_pro'] == true;
    if (!isPro && items.length >= 10) {
      throw Exception(
        'Free tier is limited to 10 vault items. Upgrade to Morrow Pro for unlimited vault storage.',
      );
    }

    items.add(VaultItem(id: itemId, type: type, addedAt: DateTime.now()));
    await _saveVaultItems(items);

    // Sync to server (Pro Only)
    try {
      if (isPro) {
        final userId = user?.id;
        if (userId != null) {
          await _supabase.from('vault_items').upsert({
            'user_id': userId,
            'item_id': itemId,
            'item_type': type.value,
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }
    } catch (e) {
      debugPrint('Error syncing vault item: $e');
    }
  }

  /// Remove item from vault
  Future<void> removeFromVault(String itemId) async {
    final items = await _getVaultItems();
    items.removeWhere((i) => i.id == itemId);
    await _saveVaultItems(items);

    // Sync to server (Pro only)
    try {
      final user = _supabase.auth.currentUser;
      final isPro = user?.userMetadata?['is_pro'] == true;
      if (isPro) {
        final userId = user?.id;
        if (userId != null) {
          await _supabase
              .from('vault_items')
              .delete()
              .eq('user_id', userId)
              .eq('item_id', itemId);
        }
      }
    } catch (e) {
      debugPrint('Error removing vault item: $e');
    }
  }

  /// Check if item is in vault
  Future<bool> isInVault(String itemId) async {
    final items = await _getVaultItems();
    return items.any((i) => i.id == itemId);
  }

  /// Get all vault items
  Future<List<VaultItem>> getVaultItems() async {
    if (!_isUnlocked) return [];
    return _getVaultItems();
  }

  /// Get vault items by type
  Future<List<VaultItem>> getVaultItemsByType(VaultItemType type) async {
    if (!_isUnlocked) return [];
    final items = await _getVaultItems();
    return items.where((i) => i.type == type).toList();
  }

  Future<List<VaultItem>> _getVaultItems() async {
    final itemsJson = await _storage.read(key: _vaultItemsKey);
    if (itemsJson == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(itemsJson);
      return decoded.map((i) => VaultItem.fromJson(i)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _saveVaultItems(List<VaultItem> items) async {
    final encoded = jsonEncode(items.map((i) => i.toJson()).toList());
    await _storage.write(key: _vaultItemsKey, value: encoded);
  }

  /// Sync vault items from server
  Future<void> syncFromServer() async {
    try {
      final user = _supabase.auth.currentUser;
      final userId = user?.id;
      final isPro = user?.userMetadata?['is_pro'] == true;
      if (userId == null || !isPro) return;

      final response = await _supabase
          .from('vault_items')
          .select()
          .eq('user_id', userId);

      final items =
          response
              .map<VaultItem>(
                (v) => VaultItem(
                  id: v['item_id'],
                  type: VaultItemType.fromString(v['item_type']),
                  addedAt: DateTime.parse(v['created_at']),
                ),
              )
              .toList();

      await _saveVaultItems(items);
    } catch (e) {
      debugPrint('Error syncing vault from server: $e');
    }
  }
}

enum VaultItemType {
  post('post'),
  conversation('conversation'),
  collection('collection'),
  media('media');

  final String value;
  const VaultItemType(this.value);

  static VaultItemType fromString(String value) {
    return VaultItemType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => VaultItemType.post,
    );
  }
}

class VaultItem {
  final String id;
  final VaultItemType type;
  final DateTime addedAt;

  VaultItem({required this.id, required this.type, required this.addedAt});

  factory VaultItem.fromJson(Map<String, dynamic> json) {
    return VaultItem(
      id: json['id'],
      type: VaultItemType.fromString(json['type']),
      addedAt: DateTime.parse(json['added_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'added_at': addedAt.toIso8601String(),
    };
  }
}
