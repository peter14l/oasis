import 'dart:io';
import 'package:flutter/foundation.dart';

/// Centralized configuration for Chat-related APIs (Giphy, Klipy, etc.)
/// Supports multi-platform key management for Web, Android, iOS, Windows, and macOS.
/// Uses a hybrid approach: check String.fromEnvironment first.
class ChatApiConfig {
  // ===========================================================================
  // GIPHY API KEYS
  // ===========================================================================
  static String get giphyApiKey {
    String key = '';
    if (kIsWeb) {
      key = const String.fromEnvironment('GIPHY_WEB_KEY');
    } else if (Platform.isAndroid) {
      key = const String.fromEnvironment('GIPHY_ANDROID_KEY');
    } else if (Platform.isIOS) {
      key = const String.fromEnvironment('GIPHY_IOS_KEY');
    } else if (Platform.isWindows) {
      key = const String.fromEnvironment('GIPHY_WINDOWS_KEY');
    } else if (Platform.isMacOS) {
      key = const String.fromEnvironment('GIPHY_MACOS_KEY');
    } else {
      key = const String.fromEnvironment('GIPHY_WEB_KEY');
    }
    return key.trim();
  }

  // ===========================================================================
  // KLIPY API KEYS
  // ===========================================================================
  static String get klipyApiKey {
    String key = '';
    if (kIsWeb) {
      key = const String.fromEnvironment('KLIPY_WEB_KEY');
    } else if (Platform.isAndroid) {
      key = const String.fromEnvironment('KLIPY_ANDROID_KEY');
    } else if (Platform.isIOS) {
      key = const String.fromEnvironment('KLIPY_IOS_KEY');
    } else if (Platform.isWindows) {
      key = const String.fromEnvironment('KLIPY_WINDOWS_KEY');
    } else if (Platform.isMacOS) {
      key = const String.fromEnvironment('KLIPY_MACOS_KEY');
    } else {
      key = const String.fromEnvironment('KLIPY_WEB_KEY');
    }
    return key.trim();
  }
}
