import 'package:gotrue/gotrue.dart' as gotrue;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:oasis_v2/features/auth/domain/models/auth_models.dart';
import 'package:oasis_v2/features/auth/domain/repositories/auth_repository.dart';
import 'package:oasis_v2/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:oasis_v2/features/auth/data/datasources/session_local_datasource.dart';
import 'package:oasis_v2/services/session_registry_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _remoteDatasource;
  final SessionLocalDatasource _localDatasource;

  AuthRepositoryImpl({
    AuthRemoteDatasource? remoteDatasource,
    SessionLocalDatasource? localDatasource,
  }) : _remoteDatasource = remoteDatasource ?? AuthRemoteDatasource(),
       _localDatasource = localDatasource ?? SessionLocalDatasource();

  @override
  Future<RegisteredAccount> signInWithEmail(AuthCredentials credentials) async {
    debugPrint('[AuthRepositoryImpl] Sign in with email');
    final account = await _remoteDatasource.signInWithEmail(credentials);
    debugPrint('[AuthRepositoryImpl] Got account: ${account.userId}');
    await _localDatasource.saveAccount(account);
    await _localDatasource.setLastActiveUserId(account.userId);
    debugPrint('[AuthRepositoryImpl] Account saved locally');
    return account;
  }

  @override
  Future<RegisteredAccount> signUp({
    required String email,
    required String password,
    String? username,
    String? fullName,
  }) async {
    final account = await _remoteDatasource.signUp(
      email: email,
      password: password,
      username: username,
      fullName: fullName,
    );
    await _localDatasource.saveAccount(account);
    await _localDatasource.setLastActiveUserId(account.userId);
    return account;
  }

  @override
  Future<void> signInWithGoogle() async {
    await _remoteDatasource.signInWithGoogle();
  }

  @override
  Future<void> signInWithApple() async {
    await _remoteDatasource.signInWithApple();
  }

  @override
  Future<void> signOut() async {
    await _remoteDatasource.signOut();
  }

  @override
  Future<RegisteredAccount?> restoreSession() async {
    return _remoteDatasource.restoreSession();
  }

  @override
  Future<void> resetPassword(String email) async {
    await _remoteDatasource.resetPassword(email);
  }

  @override
  Future<void> updatePassword(String password) async {
    await _remoteDatasource.updatePassword(password);
  }

  @override
  Future<void> switchAccount(String userId) async {
    final accounts = await _localDatasource.getRegisteredAccounts();
    final account = accounts.firstWhere(
      (a) => a.userId == userId,
      orElse: () => throw Exception('Account not found'),
    );

    await _remoteDatasource.setSession(account.session.refreshToken!);
    await _localDatasource.markAsUsed(userId);
    await _localDatasource.setLastActiveUserId(userId);
  }

  @override
  Future<List<RegisteredAccount>> getRegisteredAccounts() async {
    return _localDatasource.getRegisteredAccounts();
  }

  @override
  Future<void> removeAccount(String userId) async {
    await _localDatasource.removeAccount(userId);
  }

  @override
  Future<void> updateProfile({
    required String userId,
    String? username,
    String? fullName,
    String? avatarUrl,
  }) async {
    await _remoteDatasource.updateProfile(
      username: username,
      fullName: fullName,
      avatarUrl: avatarUrl,
    );
  }

  Stream<gotrue.AuthState> get onAuthStateChange =>
      _remoteDatasource.onAuthStateChange;
}
