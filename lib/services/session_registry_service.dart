import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Model representing a logged-in account in the registry
class RegisteredAccount {
  final String userId;
  final String email;
  final String username;
  final String? fullName;
  final String? avatarUrl;
  final Session session;
  final DateTime lastUsed;

  RegisteredAccount({
    required this.userId,
    required this.email,
    required this.username,
    this.fullName,
    this.avatarUrl,
    required this.session,
    required this.lastUsed,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'email': email,
        'username': username,
        'fullName': fullName,
        'avatarUrl': avatarUrl,
        'session': session.toJson(),
        'lastUsed': lastUsed.toIso8601String(),
      };

  factory RegisteredAccount.fromJson(Map<String, dynamic> json) =>
      RegisteredAccount(
        userId: json['userId'],
        email: json['email'],
        username: json['username'],
        fullName: json['fullName'],
        avatarUrl: json['avatarUrl'],
        session: Session.fromJson(json['session'])!,
        lastUsed: DateTime.parse(json['lastUsed']),
      );

  RegisteredAccount copyWith({
    String? username,
    String? fullName,
    String? avatarUrl,
    Session? session,
    DateTime? lastUsed,
  }) =>
      RegisteredAccount(
        userId: userId,
        email: email,
        username: username ?? this.username,
        fullName: fullName ?? this.fullName,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        session: session ?? this.session,
        lastUsed: lastUsed ?? this.lastUsed,
      );
}

/// Service to manage the registry of active user sessions on this device
class SessionRegistryService {
  static final SessionRegistryService _instance = SessionRegistryService._internal();
  factory SessionRegistryService() => _instance;
  SessionRegistryService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _registryKey = 'oasis_account_registry';

  /// Get all registered accounts
  Future<List<RegisteredAccount>> getAllAccounts() async {
    try {
      final data = await _storage.read(key: _registryKey);
      if (data == null) return [];

      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((item) => RegisteredAccount.fromJson(item)).toList();
    } catch (e) {
      debugPrint('[SessionRegistry] Error reading registry: $e');
      return [];
    }
  }

  /// Add or update an account in the registry
  Future<void> saveAccount(RegisteredAccount account) async {
    final accounts = await getAllAccounts();
    final index = accounts.indexWhere((a) => a.userId == account.userId);

    if (index >= 0) {
      accounts[index] = account;
    } else {
      accounts.add(account);
    }

    await _persist(accounts);
  }

  /// Remove an account from the registry
  Future<void> removeAccount(String userId) async {
    final accounts = await getAllAccounts();
    accounts.removeWhere((a) => a.userId == userId);
    await _persist(accounts);
  }

  /// Update just the last used timestamp for an account
  Future<void> markAsUsed(String userId) async {
    final accounts = await getAllAccounts();
    final index = accounts.indexWhere((a) => a.userId == userId);
    if (index >= 0) {
      accounts[index] = accounts[index].copyWith(lastUsed: DateTime.now());
      await _persist(accounts);
    }
  }

  /// Clear the entire registry
  Future<void> clearAll() async {
    await _storage.delete(key: _registryKey);
  }

  Future<void> _persist(List<RegisteredAccount> accounts) async {
    final data = jsonEncode(accounts.map((a) => a.toJson()).toList());
    await _storage.write(key: _registryKey, value: data);
  }
}
