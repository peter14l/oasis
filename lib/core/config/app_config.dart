import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized application configuration.
/// 
/// Driven by environment variables for production readiness.
class AppConfig {
  AppConfig._();

  /// The base URL for the web portal/landing page.
  /// Used for deep links, auth callbacks, and checkout redirects.
  static String get webBaseUrl {
    // 1. Try compile-time defines (flutter run --dart-define=WEB_BASE_URL=...)
    const fromEnv = String.fromEnvironment('WEB_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;

    // 2. Try runtime .env file (only if initialized)
    try {
      if (dotenv.isInitialized) {
        final fromDotEnv = dotenv.env['WEB_BASE_URL'];
        if (fromDotEnv != null && fromDotEnv.isNotEmpty) {
          return fromDotEnv;
        }
      }
    } catch (_) {
      // Ignore dotenv errors
    }

    // 3. Fallback to default
    return 'https://oasis-web-red.vercel.app';
  }

  /// Helper to generate a full URL for specific paths.
  static String getWebUrl(String path) {
    final base = webBaseUrl;
    final normalizedBase = base.endsWith('/') 
        ? base.substring(0, base.length - 1) 
        : base;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '$normalizedBase$normalizedPath';
  }
}
