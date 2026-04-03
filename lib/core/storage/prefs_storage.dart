import 'package:shared_preferences/shared_preferences.dart';

/// Shared preferences wrapper for non-sensitive app settings and cache.
///
/// Use this for: theme preferences, onboarding state, cached data,
/// feature flags, and other non-sensitive persistent settings.
///
/// For sensitive data (tokens, passwords), use [SecureStorage] instead.
class PrefsStorage {
  static PrefsStorage? _instance;
  late SharedPreferences _prefs;

  PrefsStorage._internal();

  /// Initialize the storage. Must be called before first use.
  static Future<PrefsStorage> init() async {
    _instance ??= PrefsStorage._internal();
    _instance!._prefs = await SharedPreferences.getInstance();
    return _instance!;
  }

  factory PrefsStorage() {
    final instance = _instance;
    if (instance == null) {
      throw StateError(
        'PrefsStorage not initialized. Call PrefsStorage.init() first.',
      );
    }
    return instance;
  }

  /// Read a string value. Returns null if not found.
  String? readString(String key) => _prefs.getString(key);

  /// Read an int value. Returns null if not found.
  int? readInt(String key) => _prefs.getInt(key);

  /// Read a double value. Returns null if not found.
  double? readDouble(String key) => _prefs.getDouble(key);

  /// Read a bool value. Returns null if not found.
  bool? readBool(String key) => _prefs.getBool(key);

  /// Read a list of strings. Returns null if not found.
  List<String>? readStringList(String key) => _prefs.getStringList(key);

  /// Write a string value.
  Future<bool> writeString(String key, String value) =>
      _prefs.setString(key, value);

  /// Write an int value.
  Future<bool> writeInt(String key, int value) => _prefs.setInt(key, value);

  /// Write a double value.
  Future<bool> writeDouble(String key, double value) =>
      _prefs.setDouble(key, value);

  /// Write a bool value.
  Future<bool> writeBool(String key, bool value) => _prefs.setBool(key, value);

  /// Write a list of strings.
  Future<bool> writeStringList(String key, List<String> value) =>
      _prefs.setStringList(key, value);

  /// Delete a value by key.
  Future<bool> delete(String key) => _prefs.remove(key);

  /// Check if a key exists.
  bool contains(String key) => _prefs.containsKey(key);

  /// Clear all stored values.
  Future<bool> clear() => _prefs.clear();

  /// Get all keys.
  Set<String> get keys => _prefs.getKeys();
}
