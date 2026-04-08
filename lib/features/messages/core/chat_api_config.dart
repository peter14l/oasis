import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized configuration for Chat-related APIs (Giphy, Klipy, etc.)
/// Supports multi-platform key management for Web, Android, iOS, Windows, and macOS.
/// Uses a hybrid approach: check String.fromEnvironment first, then fallback to dotenv.
class ChatApiConfig {
  static String _getEnv(String key) {
    // Check for --dart-define (fromEnvironment)
    final fromEnv = String.fromEnvironment(key);
    if (fromEnv.isNotEmpty) return fromEnv;
    
    // Fallback to .env file
    return dotenv.env[key] ?? '';
  }

  // ===========================================================================
  // GIPHY API KEYS
  // ===========================================================================
  static String get giphyApiKey {
    if (kIsWeb) return _getEnv('GIPHY_WEB_KEY');
    if (Platform.isAndroid) return _getEnv('GIPHY_ANDROID_KEY');
    if (Platform.isIOS) return _getEnv('GIPHY_IOS_KEY');
    if (Platform.isWindows) return _getEnv('GIPHY_WINDOWS_KEY');
    if (Platform.isMacOS) return _getEnv('GIPHY_MACOS_KEY');
    return _getEnv('GIPHY_WEB_KEY');
  }

  // ===========================================================================
  // KLIPY API KEYS
  // ===========================================================================
  static String get klipyApiKey {
    if (kIsWeb) return _getEnv('WEB_KEY');
    if (Platform.isAndroid) return _getEnv('ANDROID_KEY');
    if (Platform.isIOS) return _getEnv('IOS_KEY');
    if (Platform.isWindows) return _getEnv('WINDOWS_KEY');
    if (Platform.isMacOS) return _getEnv('MACOS_KEY');
    return _getEnv('WEB_KEY');
  }
}
