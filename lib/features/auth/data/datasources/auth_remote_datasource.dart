import 'package:flutter/foundation.dart';
import 'package:gotrue/gotrue.dart' as gotrue;
import 'package:oasis_v2/core/network/supabase_client.dart';
import 'package:oasis_v2/features/auth/domain/models/auth_models.dart';
import 'package:oasis_v2/services/session_registry_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRemoteDatasource {
  final SupabaseClient _supabase = SupabaseService().client;

  Future<RegisteredAccount> signInWithEmail(AuthCredentials credentials) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: credentials.email,
        password: credentials.password,
      );

      final user = response.user;
      final session = response.session;

      if (user == null || session == null) {
        throw Exception('Sign in failed: no user or session returned');
      }

      return _toRegisteredAccount(user, session);
    } on AuthException catch (e) {
      debugPrint('[AuthRemoteDatasource] Sign in error: ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      debugPrint('[AuthRemoteDatasource] Sign in error: $e');
      rethrow;
    }
  }

  Future<RegisteredAccount> signUp({
    required String email,
    required String password,
    String? username,
    String? fullName,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          if (username != null) 'username': username,
          if (fullName != null) 'full_name': fullName,
        },
      );

      final user = response.user;
      final session = response.session;

      if (user == null) {
        throw Exception('Sign up failed: no user returned');
      }

      if (session == null) {
        throw Exception('Please check your email to verify your account');
      }

      return _toRegisteredAccount(user, session);
    } on AuthException catch (e) {
      debugPrint('[AuthRemoteDatasource] Sign up error: ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      debugPrint('[AuthRemoteDatasource] Sign up error: $e');
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(OAuthProvider.google);
    } on AuthException catch (e) {
      debugPrint('[AuthRemoteDatasource] Google sign in error: ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      debugPrint('[AuthRemoteDatasource] Google sign in error: $e');
      rethrow;
    }
  }

  Future<void> signInWithApple() async {
    try {
      await _supabase.auth.signInWithOAuth(OAuthProvider.apple);
    } on AuthException catch (e) {
      debugPrint('[AuthRemoteDatasource] Apple sign in error: ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      debugPrint('[AuthRemoteDatasource] Apple sign in error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } on AuthException catch (e) {
      debugPrint('[AuthRemoteDatasource] Sign out error: ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      debugPrint('[AuthRemoteDatasource] Sign out error: $e');
      rethrow;
    }
  }

  Future<RegisteredAccount?> restoreSession() async {
    try {
      final session = _supabase.auth.currentSession;
      final user = _supabase.auth.currentUser;

      if (session == null || user == null) return null;

      return _toRegisteredAccount(user, session);
    } catch (e) {
      debugPrint('[AuthRemoteDatasource] Restore session error: $e');
      return null;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      debugPrint('[AuthRemoteDatasource] Reset password error: ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      debugPrint('[AuthRemoteDatasource] Reset password error: $e');
      rethrow;
    }
  }

  Future<void> setSession(String refreshToken) async {
    try {
      await _supabase.auth.setSession(refreshToken);
    } on AuthException catch (e) {
      debugPrint('[AuthRemoteDatasource] Set session error: ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      debugPrint('[AuthRemoteDatasource] Set session error: $e');
      rethrow;
    }
  }

  Future<void> updateProfile({
    String? username,
    String? fullName,
    String? avatarUrl,
  }) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            if (username != null) 'username': username,
            if (fullName != null) 'full_name': fullName,
            if (avatarUrl != null) 'avatar_url': avatarUrl,
          },
        ),
      );
    } on AuthException catch (e) {
      debugPrint('[AuthRemoteDatasource] Update profile error: ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      debugPrint('[AuthRemoteDatasource] Update profile error: $e');
      rethrow;
    }
  }

  Stream<gotrue.AuthState> get onAuthStateChange =>
      _supabase.auth.onAuthStateChange;

  RegisteredAccount _toRegisteredAccount(User user, Session session) {
    final metadata = user.userMetadata ?? {};
    return RegisteredAccount(
      userId: user.id,
      email: user.email ?? '',
      username: metadata['username'] ?? user.email?.split('@')[0] ?? 'user',
      fullName: metadata['full_name'],
      avatarUrl: metadata['avatar_url'],
      session: session,
      lastUsed: DateTime.now(),
    );
  }
}
