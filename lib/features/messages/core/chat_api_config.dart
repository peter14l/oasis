import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized configuration for Chat-related APIs (Giphy, Klipy, etc.)
/// Supports multi-platform key management for Web, Android, iOS, Windows, and macOS.
/// Uses a hybrid approach: check String.fromEnvironment first, then fallback to dotenv.
class ChatApiConfig {
  static String _getEnv(String key) {
    // Fallback to .env file
    try {
      return dotenv.env[key]?.trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  // ===========================================================================
  // GIPHY API KEYS
  // ===========================================================================
  static String get giphyApiKey {
    String key = '';
    if (kIsWeb) {
      key = const String.fromEnvironment('GIPHY_WEB_KEY');
      if (key.isEmpty) key = _getEnv('GIPHY_WEB_KEY');
    } else if (Platform.isAndroid) {
      key = const String.fromEnvironment('GIPHY_ANDROID_KEY');
      if (key.isEmpty) key = _getEnv('GIPHY_ANDROID_KEY');
    } else if (Platform.isIOS) {
      key = const String.fromEnvironment('GIPHY_IOS_KEY');
      if (key.isEmpty) key = _getEnv('GIPHY_IOS_KEY');
    } else if (Platform.isWindows) {
      key = const String.fromEnvironment('GIPHY_WINDOWS_KEY');
      if (key.isEmpty) key = _getEnv('GIPHY_WINDOWS_KEY');
    } else if (Platform.isMacOS) {
      key = const String.fromEnvironment('GIPHY_MACOS_KEY');
      if (key.isEmpty) key = _getEnv('GIPHY_MACOS_KEY');
    } else {
      key = const String.fromEnvironment('GIPHY_WEB_KEY');
      if (key.isEmpty) key = _getEnv('GIPHY_WEB_KEY');
    }
    return key.trim();
  }

  // ===========================================================================
  // KLIPY API KEYS
  // ===========================================================================
  static String get klipyApiKey {
    String key = '';
    if (kIsWeb) {
      key = const String.fromEnvironment('WEB_KEY');
      if (key.isEmpty) key = _getEnv('WEB_KEY');
    } else if (Platform.isAndroid) {
      key = const String.fromEnvironment('ANDROID_KEY');
      if (key.isEmpty) key = _getEnv('ANDROID_KEY');
    } else if (Platform.isIOS) {
      key = const String.fromEnvironment('IOS_KEY');
      if (key.isEmpty) key = _getEnv('IOS_KEY');
    } else if (Platform.isWindows) {
      key = const String.fromEnvironment('WINDOWS_KEY');
      if (key.isEmpty) key = _getEnv('WINDOWS_KEY');
    } else if (Platform.isMacOS) {
      key = const String.fromEnvironment('MACOS_KEY');
      if (key.isEmpty) key = _getEnv('MACOS_KEY');
    } else {
      key = const String.fromEnvironment('WEB_KEY');
      if (key.isEmpty) key = _getEnv('WEB_KEY');
    }
    return key.trim();
  }
}
