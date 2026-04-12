import 'package:oasis/core/config/app_config.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart'
    as all_platforms;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:universal_io/io.dart';

class AuthProvidersDelegate {
  final SupabaseClient _supabase;

  AuthProvidersDelegate(this._supabase);

  static String get _googleWebClientId {
    const fromEnv = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
    if (fromEnv.isNotEmpty) return fromEnv;
    return '';
  }

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? _googleWebClientId : null,
    serverClientId: kIsWeb ? null : _googleWebClientId,
    scopes: ['email', 'profile'],
  );

  static final all_platforms.GoogleSignIn _googleSignInDesktop =
      all_platforms.GoogleSignIn(
        params: all_platforms.GoogleSignInParams(
          clientId: _googleWebClientId,
          redirectPort: 3000,
          scopes: ['email', 'profile', 'openid'],
        ),
      );

  Future<AuthResponse> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> data,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: data,
      emailRedirectTo: AppConfig.getWebUrl('/auth/callback'),
    );
  }

  Future<void> signInWithGoogle({bool forceSignIn = false}) async {
    String? idToken;
    String? accessToken;

    if (!kIsWeb && Platform.isWindows) {
      final response = await _googleSignInDesktop.signIn();
      if (response == null)
        throw const AuthException('Google sign in was cancelled');
      idToken = response.idToken;
      accessToken = response.accessToken;
    } else {
      GoogleSignInAccount? googleUser;
      if (forceSignIn) {
        await _googleSignIn.signOut();
        googleUser = await _googleSignIn.signIn();
      } else {
        googleUser =
            await _googleSignIn.signInSilently() ??
            await _googleSignIn.signIn();
      }

      if (googleUser == null)
        throw const AuthException('Google sign in was cancelled');

      final googleAuth = await googleUser.authentication;
      idToken = googleAuth.idToken;
      accessToken = googleAuth.accessToken;
    }

    if (idToken == null) throw const AuthException('No ID Token found.');

    await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  Future<void> signInWithApple() async {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      webAuthenticationOptions: WebAuthenticationOptions(
        clientId: const String.fromEnvironment(
          'APPLE_SERVICE_ID',
          defaultValue: 'com.oasis.service',
        ),
        redirectUri: Uri.parse(AppConfig.getWebUrl('/auth/apple/callback')),
      ),
    );

    await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: credential.identityToken!,
    );
  }

  Future<void> signOut() async {
    if (kIsWeb || !Platform.isWindows) {
      await _googleSignIn.signOut().catchError((e) => null);
    } else {
      await _googleSignInDesktop.signOut().catchError((e) => null);
    }
    await _supabase.auth.signOut();
  }
}
