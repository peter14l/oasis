import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oasis/services/session_registry_service.dart';

class AccountRegistryManager with ChangeNotifier {
  final SessionRegistryService _registry = SessionRegistryService();
  List<RegisteredAccount> _registeredAccounts = [];
  List<RegisteredAccount> get registeredAccounts => _registeredAccounts;

  AccountRegistryManager() {
    loadRegistry();
  }

  Future<void> loadRegistry() async {
    _registeredAccounts = await _registry.getAllAccounts();
    notifyListeners();
  }

  Future<void> syncCurrentSessionToRegistry(Session session) async {
    final user = session.user;
    final metadata = user.userMetadata ?? {};

    final account = RegisteredAccount(
      userId: user.id,
      email: user.email ?? '',
      username: metadata['username'] ?? user.email?.split('@')[0] ?? 'user',
      fullName: metadata['full_name'],
      avatarUrl: metadata['avatar_url'],
      session: session,
      lastUsed: DateTime.now(),
    );

    await _registry.saveAccount(account);
    await loadRegistry();
  }

  Future<void> removeAccount(String userId) async {
    await _registry.removeAccount(userId);
    await loadRegistry();
  }

  Future<void> markAsUsed(String userId) async {
    await _registry.markAsUsed(userId);
    await loadRegistry();
  }

  RegisteredAccount getAccount(String userId) {
    return _registeredAccounts.firstWhere((a) => a.userId == userId);
  }
}
