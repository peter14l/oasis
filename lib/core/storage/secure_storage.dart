import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage wrapper for sensitive data (tokens, keys, credentials).
///
/// Uses flutter_secure_storage under the hood, which provides:
/// - Keychain on iOS
/// - Keystore on Android
/// - DPAPI on Windows
/// - Keyring on Linux
class SecureStorage {
  static final SecureStorage _instance = SecureStorage._internal();
  factory SecureStorage() => _instance;
  SecureStorage._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Read a value by key. Returns null if not found.
  Future<String?> read({required String key}) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      return null;
    }
  }

  /// Write a value by key.
  Future<void> write({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
  }

  /// Delete a value by key.
  Future<void> delete({required String key}) async {
    await _storage.delete(key: key);
  }

  /// Delete all stored values.
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  /// Check if a key exists.
  Future<bool> contains({required String key}) async {
    final value = await _storage.read(key: key);
    return value != null;
  }

  /// Read all key-value pairs.
  Future<Map<String, String>> readAll() async {
    return await _storage.readAll();
  }
}
