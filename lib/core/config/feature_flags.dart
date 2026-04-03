import 'package:flutter/foundation.dart';
import 'dart:io' as io;

class FeatureFlags {
  // Safe Platform check that won't crash on Web
  static bool get _isAndroid => !kIsWeb && io.Platform.isAndroid;
  static bool get _isIOS => !kIsWeb && io.Platform.isIOS;
  static bool get _isWindows => !kIsWeb && io.Platform.isWindows;
  static bool get _isMacOS => !kIsWeb && io.Platform.isMacOS;
  static bool get _isLinux => !kIsWeb && io.Platform.isLinux;

  // Check if we are on a mobile platform
  static bool get isMobile => _isAndroid || _isIOS;

  // Check if we are on a desktop platform
  static bool get isDesktop => _isWindows || _isMacOS || _isLinux;

  // --- UI & Experience ---

  // Kinetic scrolling and squish effects
  static bool get useKineticPhysics => isMobile;

  // High-fidelity mesh gradients
  static bool get allowMeshGradients => !kIsWeb;

  // --- Hardware & System ---

  // Biometric authentication
  static bool get useBiometrics => isMobile || _isMacOS || _isWindows;

  // System-level sharing intents
  static bool get supportSystemIntents => isMobile;

  // Gyroscope/Accelerometer features
  static bool get useSensors => isMobile;

  // --- Media ---

  // Advanced image cropping
  static bool get useNativeCropper => isMobile;

  // Audio compression
  static bool get supportAudioCompression => isMobile || isDesktop;
}
