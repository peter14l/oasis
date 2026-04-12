import 'package:flutter/foundation.dart';

/// Centralized application configuration.
///
/// Driven by environment variables for production readiness.
class AppConfig {
  AppConfig._();

  /// The base URL for the web portal/landing page.
  /// Used for deep links, auth callbacks, and checkout redirects.
  static String get webBaseUrl {
    const fromEnv = String.fromEnvironment('WEB_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;

    return 'https://oasis-web-red.vercel.app';
  }

  /// Helper to generate a full URL for specific paths.
  static String getWebUrl(String path) {
    final base = webBaseUrl;
    final normalizedBase =
        base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '$normalizedBase$normalizedPath';
  }
}
