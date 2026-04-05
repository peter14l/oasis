import 'dart:async';
import 'package:universal_io/io.dart';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase/supabase.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart'
    as all_platforms;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:oasis/models/user_model.dart' as app_models;
import 'package:oasis/core/config/supabase_config.dart';
// Provider is used in other files that import this one
import 'package:oasis/core/network/supabase_client.dart';
import 'package:oasis/services/encryption_service.dart';
import 'package:oasis/services/signal/signal_service.dart';
import 'package:oasis/services/notification_service.dart';
import 'package:oasis/services/session_registry_service.dart';
import 'package:provider/provider.dart';
import 'package:oasis/providers/conversation_provider.dart';
import 'package:oasis/features/profile/presentation/providers/profile_provider.dart';
import 'package:oasis/features/circles/presentation/providers/circle_provider.dart';
import 'package:oasis/providers/canvas_provider.dart';
import 'package:oasis/providers/notification_provider.dart';
import 'package:oasis/providers/community_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService with ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  SupabaseClient get _supabase => SupabaseService().client;
  final NotificationService _notificationService = NotificationService();
  final SessionRegistryService _registry = SessionRegistryService();
  StreamSubscription<AuthState>? _authStateSubscription;

  List<RegisteredAccount> _registeredAccounts = [];
  List<RegisteredAccount> get registeredAccounts => _registeredAccounts;

  factory AuthService() {
    return _instance;
  }

  AuthService._internal() {
    // Listen to auth state changes
    _authStateSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (kDebugMode) developer.log('Auth state changed: $event');
      if (session != null) {
        if (kDebugMode) developer.log('User ID: ${session.user.id}');
        _syncCurrentSessionToRegistry(session);
      }
      notifyListeners();
    });

    // Initial registry load
    _loadRegistry();
  }

  Future<void> _loadRegistry() async {
    _registeredAccounts = await _registry.getAllAccounts();
    notifyListeners();
  }

  Future<void> _syncCurrentSessionToRegistry(Session session) async {
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
    await _loadRegistry();
  }

  /// Switch to a different logged-in account
  Future<void> switchAccount(BuildContext context, String userId) async {
    final account = _registeredAccounts.firstWhere((a) => a.userId == userId);

    try {
      // 1. Save current session state if possible
      // (Supabase auto-manages the current session, but we sync it periodically)

      // 2. Clear all providers to prevent "ghost data"
      _resetAllProviders(context);

      // 3. Swap Supabase session
      await _supabase.auth.setSession(account.session.refreshToken!);

      // 4. Mark as last used
      await _registry.markAsUsed(userId);
      await _loadRegistry();

      // 5. Provision keys for the new user context
      _provisionEncryptionKeys();
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

    await _registry.removeAccount(userId);
    await _loadRegistry();

    if (isCurrent) {
      if (_registeredAccounts.isNotEmpty) {
        // Switch to the next available account
        await switchAccount(context, _registeredAccounts.first.userId);
      } else {
        // No accounts left, full sign out
        await signOut();
      }
    }
  }

  static String get _googleWebClientId {
    const fromEnv = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
    if (fromEnv.isNotEmpty) return fromEnv;
    return dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '';
  }

  static String get _googleWebClientSecret {
    const fromEnv = String.fromEnvironment('GOOGLE_WEB_CLIENT_SECRET');
    if (fromEnv.isNotEmpty) return fromEnv;
    return dotenv.env['GOOGLE_WEB_CLIENT_SECRET'] ?? '';
  }

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? _googleWebClientId : null,
    serverClientId: kIsWeb ? null : _googleWebClientId,
    scopes: ['email', 'profile'],
  );

  // For Windows/Desktop fallback
  static all_platforms.GoogleSignIn _googleSignInDesktop =
      all_platforms.GoogleSignIn(
        params: all_platforms.GoogleSignInParams(
          clientId: _googleWebClientId,
          // clientSecret removed for public PKCE
          redirectPort: 3000,
          scopes: ['email', 'profile', 'openid'],
        ),
      );

  // Auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Restore session
  Future<void> restoreSession() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session != null) {
        developer.log('Session restored for user: ${session.user.id}');
        // Refresh FCM token on session restore
        _notificationService.updateFcmToken(session.user.id);
      } else {
        developer.log('No existing session found');
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

    final userMetadata = user.userMetadata ?? {};
    return app_models.AppUser(
      id: user.id,
      email: user.email ?? '',
      username:
          userMetadata['username'] ??
          user.email?.split('@')[0] ??
          'user_${user.id.substring(0, 8)}',
      displayName: userMetadata['full_name'] as String?,
      photoUrl: userMetadata['avatar_url'] as String?,
      isVerified: user.emailConfirmedAt != null,
      isPro: userMetadata['is_pro'] as bool? ?? false,
      userMetadata: userMetadata,
    );
  }

  // Sign in with email and password
  Future<app_models.AppUser> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw AuthException(
          'Failed to sign in. Please check your credentials.',
        );
      }

      // Provision/restore E2E keys in the background immediately after login
      // (WhatsApp-style: keys are always ready before the user opens any chat)
      _provisionEncryptionKeys();
      _notificationService.updateFcmToken(response.user!.id);

      return _userFromSupabaseUser(response.user!);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Failed to sign in and provision keys.');
    }
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
      final usernameCheck =
          await _supabase
              .from(SupabaseConfig.profilesTable)
              .select('id')
              .eq('username', username)
              .maybeSingle();

      if (usernameCheck != null) {
        throw AuthException('Username is already taken');
      }

      // Create user in Auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username.toLowerCase(),
          'full_name': displayName ?? username,
        },
        emailRedirectTo: 'https://oasis-web-red.vercel.app/auth/callback',
      );

      if (response.user == null) {
        throw AuthException('Failed to create user');
      }

      // Create user profile in database
      await _createUserProfile(
        userId: response.user!.id,
        email: email,
        username: username,
        displayName: displayName,
      );

      // Generate E2E encryption keys immediately for new users
      _provisionEncryptionKeys();
      _notificationService.updateFcmToken(response.user!.id);

      return _userFromSupabaseUser(response.user!);
    } on AuthException catch (e) {
      rethrow;
    } catch (e) {
      throw AuthException('Failed to register: ${e.toString()}');
    }
  }

  // Sign in with Google
  Future<app_models.AppUser> signInWithGoogle({
    bool forceSignIn = false,
  }) async {
    try {
      String? idToken;
      String? accessToken;

      if (!kIsWeb && Platform.isWindows) {
        // Desktop Flow
        // We might need to manually trigger sign-in with prompt=select_account if supported by the package
        final response = await _googleSignInDesktop.signIn();
        if (response == null) {
          throw AuthException('Google sign in was cancelled');
        }
        idToken = response.idToken;
        accessToken = response.accessToken;
      } else {
        // Mobile/Web Flow
        GoogleSignInAccount? googleUser;

        if (forceSignIn) {
          await _googleSignIn.signOut(); // Ensure we don't auto-sign in
          googleUser = await _googleSignIn.signIn();
        } else {
          googleUser =
              await _googleSignIn.signInSilently() ??
              await _googleSignIn.signIn();
        }

        if (googleUser == null) {
          throw AuthException('Google sign in was cancelled');
        }

        final googleAuth = await googleUser.authentication;
        idToken = googleAuth.idToken;
        accessToken = googleAuth.accessToken;
      }

      if (idToken == null) {
        throw AuthException('No ID Token found.');
      }

      // Sign in to Supabase with the Google token
      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      // Get the user after successful sign in
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw AuthException('Failed to sign in with Google');
      }

      // Check if user exists in our profiles table
      var profile =
          await _supabase
              .from(SupabaseConfig.profilesTable)
              .select()
              .eq('id', user.id)
              .maybeSingle();

      // If not found by ID, try checking by email (in case linking wasn't automatic but user exists)
      if (profile == null && user.email != null) {
        profile =
            await _supabase
                .from(SupabaseConfig.profilesTable)
                .select()
                .eq('email', user.email!)
                .maybeSingle();

        if (profile != null) {
          // If found by email, update the ID to the new social ID if they differ
          // (This handles cases where the user was created via password and now signs in via Google)
          if (profile['id'] != user.id) {
            await _supabase
                .from(SupabaseConfig.profilesTable)
                .update({'id': user.id})
                .eq('email', user.email!);
          }
        }
      }

      // Create profile if it doesn't exist at all
      if (profile == null) {
        String rawUsername =
            user.userMetadata?['preferred_username'] ??
            user.userMetadata?['name'] ??
            user.email?.split('@')[0] ??
            'user_${user.id.substring(0, 8)}';

        // Sanitize: Lowercase and replace non-alphanumeric with underscores
        String sanitizedUsername = rawUsername.toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9_]'),
          '_',
        );

        // Ensure length constraints
        if (sanitizedUsername.length < 3) sanitizedUsername += '_user';
        if (sanitizedUsername.length > 30)
          sanitizedUsername = sanitizedUsername.substring(0, 30);

        // Check for uniqueness (fallback logic)
        final existing =
            await _supabase
                .from(SupabaseConfig.profilesTable)
                .select('id')
                .eq('username', sanitizedUsername)
                .maybeSingle();

        if (existing != null) {
          sanitizedUsername += DateTime.now().millisecondsSinceEpoch
              .toString()
              .substring(10);
        }

        await _createUserProfile(
          userId: user.id,
          email: user.email!,
          username: sanitizedUsername,
          displayName: user.userMetadata?['full_name'],
          avatarUrl: user.userMetadata?['avatar_url'],
        );
      }

      // Provision/restore E2E keys in the background
      _provisionEncryptionKeys();
      _notificationService.updateFcmToken(user.id);

      return _userFromSupabaseUser(user);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Failed to sign in with Google: ${e.toString()}');
    }
  }

  // Sign in with Apple
  Future<app_models.AppUser> signInWithApple() async {
    try {
      // Start the Apple sign in process
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: WebAuthenticationOptions(
          // Register this Service ID in Apple Developer Portal:
          // https://developer.apple.com/account/resources/identifiers/list/serviceId
          clientId: const String.fromEnvironment(
            'APPLE_SERVICE_ID',
            defaultValue: 'com.oasis.service',
          ),
          redirectUri: Uri.parse(
            'https://oasis-web-red.vercel.app/auth/apple/callback',
          ),
        ),
      );

      // Sign in to Supabase with the Apple token
      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: credential.identityToken!,
      );

      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw AuthException('Failed to sign in with Apple');
      }

      // Check if user exists in our profiles table
      final profile =
          await _supabase
              .from(SupabaseConfig.profilesTable)
              .select()
              .eq('id', user.id)
              .maybeSingle();

      // Create profile if it doesn't exist
      if (profile == null) {
        final givenName = credential.givenName ?? '';
        final familyName = credential.familyName ?? '';
        final fullName = '$givenName $familyName'.trim();
        final username =
            fullName.isNotEmpty
                ? fullName.replaceAll(' ', '_').toLowerCase()
                : 'user_${user.id.substring(0, 8)}';

        await _createUserProfile(
          userId: user.id,
          email: user.email ?? '${user.id}@appleid.com',
          username: username,
          displayName: fullName.isNotEmpty ? fullName : 'Apple User',
        );
      }

      // Provision/restore E2E keys in the background
      _provisionEncryptionKeys();
      _notificationService.updateFcmToken(user.id);

      return _userFromSupabaseUser(user);
    } on AuthException catch (e) {
      rethrow;
    } catch (e) {
      throw AuthException('Failed to sign in with Apple: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Safe sign out for Google
      if (kIsWeb || !Platform.isWindows) {
        try {
          await _googleSignIn.signOut();
        } catch (e) {
          developer.log('Non-critical: Google sign out failed: $e');
        }
      } else {
        try {
          await _googleSignInDesktop.signOut();
        } catch (e) {
          developer.log('Non-critical: Google desktop sign out failed: $e');
        }
      }

      // Clear encryption keys and Signal state before Supabase signout
      // to ensure they are wiped while we still have the session (if needed)
      await EncryptionService().clearKeys();
      await SignalService().clearData();

      await _supabase.auth.signOut();
      notifyListeners();
    } catch (e) {
      throw AuthException('Failed to sign out: ${e.toString()}');
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'https://oasis-web-red.vercel.app/auth/reset-password',
      );
    } catch (e) {
      throw AuthException(
        'Failed to send password reset email: ${e.toString()}',
      );
    }
  }

  // Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
    } catch (e) {
      throw AuthException('Failed to update password: ${e.toString()}');
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      await _supabase.rpc('delete_user_account');
      await _supabase.auth.signOut();
    } catch (e) {
      throw AuthException('Failed to delete account: ${e.toString()}');
    }
  }

  // Update profile
  Future<void> updateProfile({
    String? username,
    String? displayName,
    String? avatarUrl,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw AuthException('Not authenticated');

      final updates = <String, dynamic>{};

      if (username != null) {
        // Check if username is available
        final usernameCheck =
            await _supabase
                .from(SupabaseConfig.profilesTable)
                .select('id')
                .eq('username', username)
                .neq('id', userId)
                .maybeSingle();

        if (usernameCheck != null) {
          throw AuthException('Username is already taken');
        }
        updates['username'] = username;
      }

      if (displayName != null) {
        updates['full_name'] = displayName;
      }

      if (avatarUrl != null) {
        updates['avatar_url'] = avatarUrl;
      }

      if (updates.isNotEmpty) {
        await _supabase
            .from(SupabaseConfig.profilesTable)
            .update(updates)
            .eq('id', userId);

        // Update auth user metadata
        await _supabase.auth.updateUser(
          UserAttributes(
            data: {
              'username':
                  username ??
                  _supabase.auth.currentUser?.userMetadata?['username'],
              'full_name':
                  displayName ??
                  _supabase.auth.currentUser?.userMetadata?['full_name'],
              'avatar_url':
                  avatarUrl ??
                  _supabase.auth.currentUser?.userMetadata?['avatar_url'],
            },
          ),
        );
      }
    } on AuthException catch (e) {
      rethrow;
    } catch (e) {
      throw AuthException('Failed to update profile: ${e.toString()}');
    }
  }

  // Upload profile picture
  Future<String> uploadProfilePicture(String filePath) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw AuthException('Not authenticated');

      final fileExt = filePath.split('.').last;
      final fileName = '${DateTime.now().toIso8601String()}.$fileExt';
      final file = File(filePath);

      await _supabase.storage
          .from(SupabaseConfig.profilePicturesBucket)
          .upload(
            'profiles/$userId/$fileName',
            file,
            fileOptions: FileOptions(
              contentType: 'image/$fileExt',
              upsert: true,
            ),
          );

      final publicUrl =
          '${SupabaseConfig.supabaseUrl}/storage/v1/object/public/${SupabaseConfig.profilePicturesBucket}/profiles/$userId/$fileName';

      // Update profile with new avatar URL
      await updateProfile(avatarUrl: publicUrl);

      return publicUrl;
    } catch (e) {
      throw AuthException('Failed to upload profile picture: ${e.toString()}');
    }
  }

  /// Silently provision or restore E2E encryption keys in the background.
  /// Called immediately after every sign-in / sign-up so keys are ready
  /// before the user ever opens a chat (identical to WhatsApp's approach).
  void _provisionEncryptionKeys() {
    EncryptionService()
        .init()
        .then((status) {
          developer.log('[Auth] Encryption init status after login: $status');
        })
        .catchError((e) {
          developer.log('[Auth] Encryption init error after login: $e');
        });
  }

  // Helper method to create a user profile
  Future<void> _createUserProfile({
    required String userId,
    required String email,
    required String username,
    String? displayName,
    String? avatarUrl,
  }) async {
    try {
      await _supabase.from(SupabaseConfig.profilesTable).upsert({
        'id': userId,
        'email': email,
        'username': username.toLowerCase(),
        'full_name': displayName ?? username,
        'avatar_url': avatarUrl,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Profile creation failed — rethrow so the caller can handle it.
      // Auth user cleanup is handled by the on_auth_user_created trigger
      // cascade; do NOT call auth.admin here (requires service_role key).
      rethrow;
    }
  }

  // Helper method to create an AppUser from Supabase User
  app_models.AppUser _userFromSupabaseUser(User user) {
    final userMetadata = user.userMetadata ?? {};
    return app_models.AppUser(
      id: user.id,
      email: user.email ?? '',
      username:
          userMetadata['username'] as String? ??
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
