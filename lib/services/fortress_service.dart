import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:oasis/core/network/supabase_client.dart';
import 'package:oasis/core/config/supabase_config.dart';
import 'package:oasis/services/presence_service.dart';

/// Fortress status for a user (used when viewing friends)
class FortressStatus {
  final bool isActive;
  final String? message;
  final DateTime? until;

  const FortressStatus({
    required this.isActive,
    this.message,
    this.until,
  });

  bool get isExpired => until != null && until!.isBefore(DateTime.now());
}

/// Predefined away messages for fortress mode
class FortressMessage {
  final String emoji;
  final String text;
  final bool isCustom;

  const FortressMessage({
    required this.emoji,
    required this.text,
    this.isCustom = false,
  });

  String get display => '$emoji $text';

  static const List<FortressMessage> predefined = [
    FortressMessage(emoji: '🏰', text: 'In my fortress'),
    FortressMessage(emoji: '📵', text: 'Digital detox'),
    FortressMessage(emoji: '🔋', text: 'Recharging'),
    FortressMessage(emoji: '🎯', text: 'In the zone'),
    FortressMessage(emoji: '🌙', text: 'Sleep mode'),
    FortressMessage(emoji: '📚', text: 'Deep in a book'),
    FortressMessage(emoji: '🏖️', text: 'Taking a break'),
  ];
}

/// Fortress Mode service - One-tap lock with away messages
class FortressService with ChangeNotifier {
  final _supabase = SupabaseService().client;

  bool _isFortressActive = false;
  String? _fortressMessage;
  DateTime? _fortressUntil;
  bool _isLoading = false;

  // Triple-tap detection
  int _tapCount = 0;
  DateTime? _lastTapTime;
  static const int _tripleTapThreshold = 500; // ms between taps

  // Long-press detection state
  bool _isLongPressing = false;

  FortressService() {
    _loadFortressStatus();
  }

  // Getters
  bool get isFortressActive => _isFortressActive;
  String? get fortressMessage => _fortressMessage;
  DateTime? get fortressUntil => _fortressUntil;
  bool get isLoading => _isLoading;
  bool get isLongPressing => _isLongPressing;

  /// Get the display message for fortress mode
  String get fortressDisplayMessage {
    if (_fortressMessage == null) {
      return FortressMessage.predefined.first.display;
    }
    return _fortressMessage!;
  }

  /// Load fortress status from the database
  Future<void> _loadFortressStatus() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from(SupabaseConfig.profilesTable)
          .select('fortress_mode, fortress_message, fortress_until')
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        _isFortressActive = response['fortress_mode'] ?? false;
        _fortressMessage = response['fortress_message'];
        _fortressUntil = response['fortress_until'] != null
            ? DateTime.parse(response['fortress_until'])
            : null;

        // Check if fortress has expired
        if (_fortressUntil != null && _fortressUntil!.isBefore(DateTime.now())) {
          await deactivateFortress();
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('FortressService: Error loading fortress status: $e');
    }
  }

  /// Activate fortress mode with the default or specified message
  Future<bool> activateFortress({
    String? customMessage,
    Duration? duration,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    setState(() => _isLoading = true);

    try {
      final message = customMessage ?? FortressMessage.predefined.first.display;

      final updates = <String, dynamic>{
        'fortress_mode': true,
        'fortress_message': message,
      };

      if (duration != null) {
        updates['fortress_until'] = DateTime.now().add(duration).toIso8601String();
        _fortressUntil = DateTime.now().add(duration);
      } else {
        updates['fortress_until'] = null;
        _fortressUntil = null;
      }

      await _supabase
          .from(SupabaseConfig.profilesTable)
          .update(updates)
          .eq('id', userId);

      _isFortressActive = true;
      _fortressMessage = message;

      // Update presence to fortress so friends can see
      final presenceService = PresenceService();
      await presenceService.updateUserPresence(userId, 'fortress');

      debugPrint('FortressService: Activated fortress mode');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('FortressService: Error activating fortress: $e');
      return false;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Deactivate fortress mode
  Future<bool> deactivateFortress() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    setState(() => _isLoading = true);

    try {
      await _supabase
          .from(SupabaseConfig.profilesTable)
          .update({
            'fortress_mode': false,
            'fortress_message': null,
            'fortress_until': null,
          })
          .eq('id', userId);

      _isFortressActive = false;
      _fortressMessage = null;
      _fortressUntil = null;

      // Update presence back to online
      final presenceService = PresenceService();
      await presenceService.updateUserPresence(userId, 'online');

      debugPrint('FortressService: Deactivated fortress mode');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('FortressService: Error deactivating fortress: $e');
      return false;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Toggle fortress mode (for quick activate/deactivate)
  Future<bool> toggleFortress({String? customMessage}) async {
    if (_isFortressActive) {
      return await deactivateFortress();
    } else {
      return await activateFortress(customMessage: customMessage);
    }
  }

  /// Handle triple-tap gesture
  void onTripleTap() {
    final now = DateTime.now();

    if (_lastTapTime != null &&
        now.difference(_lastTapTime!).inMilliseconds > _tripleTapThreshold) {
      _tapCount = 0;
    }

    _tapCount++;
    _lastTapTime = now;

    if (_tapCount >= 3) {
      _tapCount = 0;
      toggleFortress();
      debugPrint('FortressService: Triple-tap activated fortress');
    }
  }

  /// Start long-press detection
  void onLongPressStart() {
    _isLongPressing = true;
    notifyListeners();
  }

  /// End long-press detection (call after long press duration)
  void onLongPressEnd() {
    _isLongPressing = false;
    notifyListeners();
  }

  /// Handle lock icon long-press - activates fortress after delay
  Future<void> onLockLongPress() async {
    onLongPressStart();

    // Wait for long press duration (500ms)
    await Future.delayed(const Duration(milliseconds: 500));

    if (_isLongPressing) {
      await toggleFortress();
      debugPrint('FortressService: Long-press activated fortress');
    }

    onLongPressEnd();
  }

  /// Check if PIN is set (required for fortress lock)
  Future<bool> isPinSet() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Check if user has a PIN configured via encryption service
      // We'll use the vault PIN as the app lock PIN
      final vaultPin = await _supabase.from('profiles')
          .select('encrypted_master_key')
          .eq('id', userId)
          .maybeSingle();

      // If they have encryption set up, they have a PIN
      return vaultPin?['encrypted_master_key'] != null;
    } catch (e) {
      debugPrint('FortressService: Error checking PIN: $e');
      return false;
    }
  }

  /// Set state helper
  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }

  /// Get fortress status for another user (for friends to see)
  static Future<FortressStatus> getFortressStatus(String userId) async {
    try {
      final supabase = SupabaseService().client;
      final response = await supabase
          .from(SupabaseConfig.profilesTable)
          .select('fortress_mode, fortress_message, fortress_until')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        return const FortressStatus(isActive: false);
      }

      final isActive = response['fortress_mode'] ?? false;
      final message = response['fortress_message'] as String?;
      final untilStr = response['fortress_until'] as String?;
      final until = untilStr != null ? DateTime.parse(untilStr) : null;

      // Check if expired
      if (until != null && until.isBefore(DateTime.now())) {
        return const FortressStatus(isActive: false);
      }

      return FortressStatus(
        isActive: isActive,
        message: message,
        until: until,
      );
    } catch (e) {
      debugPrint('FortressService: Error getting fortress status: $e');
      return const FortressStatus(isActive: false);
    }
  }

  /// Get display string for fortress status (for UI display)
  static String getFortressDisplayStatus(FortressStatus status) {
    if (!status.isActive) return 'offline';
    if (status.message != null) {
      return '${status.message} 🏰';
    }
    return 'In my fortress 🏰';
  }
}