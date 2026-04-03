import 'package:flutter/foundation.dart';
import 'package:oasis_v2/core/storage/prefs_storage.dart';
import 'package:oasis_v2/services/session_registry_service.dart';

class SessionLocalDatasource {
  final SessionRegistryService _registry = SessionRegistryService();
  final PrefsStorage _prefs = PrefsStorage();

  Future<List<RegisteredAccount>> getRegisteredAccounts() async {
    try {
      return await _registry.getAllAccounts();
    } catch (e) {
      debugPrint('[SessionLocalDatasource] Error getting accounts: $e');
      return [];
    }
  }

  Future<void> saveAccount(RegisteredAccount account) async {
    try {
      await _registry.saveAccount(account);
    } catch (e) {
      debugPrint('[SessionLocalDatasource] Error saving account: $e');
      rethrow;
    }
  }

  Future<void> removeAccount(String userId) async {
    try {
      await _registry.removeAccount(userId);
    } catch (e) {
      debugPrint('[SessionLocalDatasource] Error removing account: $e');
      rethrow;
    }
  }

  Future<void> markAsUsed(String userId) async {
    try {
      await _registry.markAsUsed(userId);
    } catch (e) {
      debugPrint('[SessionLocalDatasource] Error marking as used: $e');
      rethrow;
    }
  }

  Future<String?> getLastActiveUserId() async {
    try {
      return _prefs.readString('last_active_user_id');
    } catch (e) {
      debugPrint('[SessionLocalDatasource] Error getting last active user: $e');
      return null;
    }
  }

  Future<void> setLastActiveUserId(String userId) async {
    try {
      await _prefs.writeString('last_active_user_id', userId);
    } catch (e) {
      debugPrint('[SessionLocalDatasource] Error setting last active user: $e');
    }
  }
}
