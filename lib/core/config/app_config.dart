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
    const fromEnv = String.fromEnvironment('WEB_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    return dotenv.env['WEB_BASE_URL'] ?? 'https://oasis-web-red.vercel.app';
  }

  /// Helper to generate a full URL for specific paths.
  static String getWebUrl(String path) {
    final base = webBaseUrl.endsWith('/') 
        ? webBaseUrl.substring(0, webBaseUrl.length - 1) 
        : webBaseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$base$cleanPath';
  }
}
