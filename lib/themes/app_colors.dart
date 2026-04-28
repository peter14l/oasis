import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Time-based Color Schemes
// ---------------------------------------------------------------------------

class TimeBasedColors {
  // 1. Dawn (6 AM - 10 AM): Soft, warm, energetic
  static const ColorScheme dawn = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFFE67E22), // Soft Orange
    onPrimary: Colors.white,
    secondary: Color(0xFFF1C40F), // Sun Yellow
    onSecondary: Colors.black,
    surface: Color(0xFFFFF5E6), // Creamy Dawn
    onSurface: Color(0xFF5D4037),
    error: Color(0xFFD32F2F),
    onError: Colors.white,
  );

  // 2. Day (10 AM - 5 PM): Bright, clear, focused
  static const ColorScheme day = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF2980B9), // Sky Blue
    onPrimary: Colors.white,
    secondary: Color(0xFF27AE60), // Nature Green
    onSecondary: Colors.white,
    surface: Color(0xFFF0F4F8), // Crisp White/Blue
    onSurface: Color(0xFF2C3E50),
    error: Color(0xFFC0392B),
    onError: Colors.white,
  );

  // 3. Dusk (5 PM - 9 PM): Warm, deep, relaxing
  static const ColorScheme dusk = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF8E44AD), // Sunset Purple
    onPrimary: Colors.white,
    secondary: Color(0xFFE74C3C), // Sunset Red
    onSecondary: Colors.white,
    surface: Color(0xFF2C3E50), // Twilight Blue
    onSurface: Color(0xFFECF0F1),
    error: Color(0xFFE67E22),
    onError: Colors.white,
  );

  // 4. Night (9 PM - 6 AM): Deep, soothing, low-light
  static const ColorScheme night = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF34495E), // Midnight Blue
    onPrimary: Color(0xFFBDC3C7),
    secondary: Color(0xFF16A085), // Dark Teal
    onSecondary: Colors.white,
    surface: Color(0xFF1A1A2E), // Deep Space
    onSurface: Color(0xFF95A5A6),
    error: Color(0xFF7F8C8D),
    onError: Colors.white,
  );

  static ColorScheme getSchemeForTime(DateTime time) {
    final hour = time.hour;
    if (hour >= 6 && hour < 10) return dawn;
    if (hour >= 10 && hour < 17) return day;
    if (hour >= 17 && hour < 21) return dusk;
    return night;
  }
}

// ---------------------------------------------------------------------------
// Legacy / Fallback Colors (Minimal)
// ---------------------------------------------------------------------------

class LightColors {
  static const Color primary = Color(0xFF2980B9);
  static const Color background = Color(0xFFF0F4F8);
  static const Color onSurface = Color(0xFF2C3E50);
}

class DarkColors {
  static const Color primary = Color(0xFF34495E);
  static const Color background = Color(0xFF1A1A2E);
  static const Color onSurface = Color(0xFFECF0F1);
}

// ---------------------------------------------------------------------------
// UI Utilities
// ---------------------------------------------------------------------------

class AppTextStyles {
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    height: 1.25,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );
}

class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final Color card;
  final Color divider;

  const AppThemeExtension({
    required this.card,
    required this.divider,
  });

  @override
  ThemeExtension<AppThemeExtension> copyWith({Color? card, Color? divider}) {
    return AppThemeExtension(
      card: card ?? this.card,
      divider: divider ?? this.divider,
    );
  }

  @override
  ThemeExtension<AppThemeExtension> lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      card: Color.lerp(card, other.card, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
    );
  }
}
