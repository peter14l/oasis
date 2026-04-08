import 'package:oasis/core/config/app_config.dart';
import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oasis/features/auth/domain/models/app_user.dart' as app_models;
import 'package:oasis/core/config/supabase_config.dart';
import 'package:oasis/core/network/supabase_client.dart';
import 'package:oasis/features/messages/data/encryption_service.dart';
import 'package:oasis/features/messages/data/signal/signal_service.dart';
import 'package:oasis/services/notification_service.dart';
import 'package:oasis/services/session_registry_service.dart';
import 'package:oasis/services/auth/account_registry_manager.dart';
import 'package:oasis/services/auth/encryption_provisioner.dart';
import 'package:oasis/services/auth/profile_manager.dart';
import 'package:oasis/services/auth/auth_providers_delegate.dart';
import 'package:provider/provider.dart';
import 'package:oasis/providers/conversation_provider.dart';
import 'package:oasis/features/profile/presentation/providers/profile_provider.dart';
import 'package:oasis/features/circles/presentation/providers/circle_provider.dart';
import 'package:oasis/features/canvas/presentation/providers/canvas_provider.dart';
import 'package:oasis/features/notifications/presentation/providers/notification_provider.dart';
import 'package:oasis/providers/community_provider.dart';

class AuthService with ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  SupabaseClient get _supabase => SupabaseService().client;
  final NotificationService _notificationService = NotificationService();
  
  final AccountRegistryManager _accountRegistry = AccountRegistryManager();
  final EncryptionProvisioner _encryptionProvisioner = EncryptionProvisioner();
  final ProfileManager _profileManager = ProfileManager();
  late final AuthProvidersDelegate _providersDelegate;

  StreamSubscription<AuthState>? _authStateSubscription;

  List<RegisteredAccount> get registeredAccounts => _accountRegistry.registeredAccounts;

  factory AuthService() {
    return _instance;
  }

  AuthService._internal() {
    _providersDelegate = AuthProvidersDelegate(_supabase);

    // Listen to auth state changes
    _authStateSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (kDebugMode) developer.log('Auth state changed: $event');
      if (session != null) {
        if (kDebugMode) developer.log('User ID: ${session.user.id}');
        _accountRegistry.syncCurrentSessionToRegistry(session);
      }
      notifyListeners();
    });

    _accountRegistry.addListener(notifyListeners);
  }

  /// Switch to a different logged-in account
  Future<void> switchAccount(BuildContext context, String userId) async {
    final account = _accountRegistry.getAccount(userId);

    try {
      _resetAllProviders(context);
      await _supabase.auth.setSession(account.session.refreshToken!);
      await _accountRegistry.markAsUsed(userId);
      
      _encryptionProvisioner.provisionEncryptionKeys();
      _notificationService.updateFcmToken(userId);

      notifyListeners();
    } catch (e) {
      developer.log('Error switching account: $e');
      rethrow;
    }
  }

  void _resetAllProviders(BuildContext context) {
    context.read<ConversationProvider>().clear();
    context.read<ProfileProvider>().clear();
    context.read<CircleProvider>().clear();
    context.read<CanvasProvider>().clear();
    context.read<NotificationProvider>().clear();
    context.read<CommunityProvider>().clear();
  }

  /// Remove an account from the registry (Logout specific account)
  Future<void> removeAccount(BuildContext context, String userId) async {
    final isCurrent = _supabase.auth.currentUser?.id == userId;

    await _accountRegistry.removeAccount(userId);

    if (isCurrent) {
      if (registeredAccounts.isNotEmpty) {
        await switchAccount(context, registeredAccounts.first.userId);
      } else {
        await signOut();
      }
    }
  }

  // Auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Restore session
  Future<void> restoreSession() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session != null) {
        developer.log('Session restored for user: ${session.user.id}');
        _notificationService.updateFcmToken(session.user.id);
      }
      notifyListeners();
    } catch (e) {
      developer.log('Error restoring session: $e', error: e);
      rethrow;
    }
  }

  // Current user
  app_models.AppUser? get currentUser {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    return _userFromSupabaseUser(user);
  }

  // Sign in with email and password
  Future<app_models.AppUser> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final response = await _providersDelegate.signInWithEmailAndPassword(email, password);
    if (response.user == null) {
      throw const AuthException('Failed to sign in. Please check your credentials.');
    }

    _encryptionProvisioner.provisionEncryptionKeys();
    _notificationService.updateFcmToken(response.user!.id);

    return _userFromSupabaseUser(response.user!);
  }

  // Register with email and password
  Future<app_models.AppUser> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
    String? displayName,
  }) async {
    try {
      // Check if username is available
      final usernameCheck = await _supabase
          .from(SupabaseConfig.profilesTable)
          .select('id')
          .eq('username', username)
          .maybeSingle();

      if (usernameCheck != null) {
        throw const AuthException('Username is already taken');
      }

      final response = await _providersDelegate.signUp(
        email: email,
        password: password,
        data: {
          'username': username.toLowerCase(),
          'full_name': displayName ?? username,
        },
      );

      if (response.user == null) {
        throw const AuthException('Failed to create user');
      }

      await _profileManager.createUserProfile(
        userId: response.user!.id,
        email: email,
        username: username,
        displayName: displayName,
      );

      _encryptionProvisioner.provisionEncryptionKeys();
      _notificationService.updateFcmToken(response.user!.id);

      return _userFromSupabaseUser(response.user!);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Failed to register: ${e.toString()}');
    }
  }

  // Sign in with Google
  Future<app_models.AppUser> signInWithGoogle({
    bool forceSignIn = false,
  }) async {
    await _providersDelegate.signInWithGoogle(forceSignIn: forceSignIn);

    final user = _supabase.auth.currentUser;
    if (user == null) throw const AuthException('Failed to sign in with Google');

    // Handle profile creation if needed
    await _ensureProfileExists(user);

    _encryptionProvisioner.provisionEncryptionKeys();
    _notificationService.updateFcmToken(user.id);

    return _userFromSupabaseUser(user);
  }

  Future<void> _ensureProfileExists(User user) async {
    var profile = await _supabase
        .from(SupabaseConfig.profilesTable)
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (profile == null && user.email != null) {
      profile = await _supabase
          .from(SupabaseConfig.profilesTable)
          .select()
          .eq('email', user.email!)
          .maybeSingle();

      if (profile != null && profile['id'] != user.id) {
        await _supabase
            .from(SupabaseConfig.profilesTable)
            .update({'id': user.id})
            .eq('email', user.email!);
      }
    }

    if (profile == null) {
      final String rawUsername = user.userMetadata?['preferred_username'] ??
          user.userMetadata?['name'] ??
          user.email?.split('@')[0] ??
          'user_${user.id.substring(0, 8)}';

      String sanitizedUsername = rawUsername.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');
      if (sanitizedUsername.length < 3) sanitizedUsername += '_user';
      if (sanitizedUsername.length > 30) sanitizedUsername = sanitizedUsername.substring(0, 30);

      final existing = await _supabase
          .from(SupabaseConfig.profilesTable)
          .select('id')
          .eq('username', sanitizedUsername)
          .maybeSingle();

      if (existing != null) {
        sanitizedUsername += DateTime.now().millisecondsSinceEpoch.toString().substring(10);
      }

      await _profileManager.createUserProfile(
        userId: user.id,
        email: user.email!,
        username: sanitizedUsername,
        displayName: user.userMetadata?['full_name'],
        avatarUrl: user.userMetadata?['avatar_url'],
      );
    }
  }

  // Sign in with Apple
  Future<app_models.AppUser> signInWithApple() async {
    await _providersDelegate.signInWithApple();

    final user = _supabase.auth.currentUser;
    if (user == null) throw const AuthException('Failed to sign in with Apple');

    final profile = await _supabase
        .from(SupabaseConfig.profilesTable)
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (profile == null) {
      await _profileManager.createUserProfile(
        userId: user.id,
        email: user.email ?? '${user.id}@appleid.com',
        username: 'user_${user.id.substring(0, 8)}',
        displayName: 'Apple User',
      );
    }

    _encryptionProvisioner.provisionEncryptionKeys();
    _notificationService.updateFcmToken(user.id);

    return _userFromSupabaseUser(user);
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _providersDelegate.signOut();
      await EncryptionService().clearKeys();
      await SignalService().clearData();
      notifyListeners();
    } catch (e) {
      throw AuthException('Failed to sign out: ${e.toString()}');
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _accountRegistry.removeListener(notifyListeners);
    super.dispose();
  }

  // Pass-through methods to Managers
  Future<void> updateProfile({String? username, String? displayName, String? avatarUrl}) =>
      _profileManager.updateProfile(username: username, displayName: displayName, avatarUrl: avatarUrl);

  Future<String> uploadProfilePicture(String filePath) =>
      _profileManager.uploadProfilePicture(filePath);

  // Auth Utilities
  Future<void> sendPasswordResetEmail(String email) async {
    await _supabase.auth.resetPasswordForEmail(email,
        redirectTo: AppConfig.getWebUrl('/auth/reset-password'));
  }

  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> deleteAccount() async {
    await _supabase.rpc('delete_user_account');
    await signOut();
  }

  app_models.AppUser _userFromSupabaseUser(User user) {
    final userMetadata = user.userMetadata ?? {};
    return app_models.AppUser(
      id: user.id,
      email: user.email ?? '',
      username: userMetadata['username'] as String? ??
          user.email?.split('@')[0] ??
          'user_${user.id.substring(0, 8)}',
      displayName: userMetadata['full_name'] as String?,
      photoUrl: userMetadata['avatar_url'] as String?,
      isVerified: user.emailConfirmedAt != null,
      isPro: userMetadata['is_pro'] as bool? ?? false,
      userMetadata: userMetadata,
    );
  }
}

