import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;

class AppFluentTheme {
  static FluentThemeData getTheme(
    material.Brightness brightness, {
    material.ColorScheme? materialColorScheme,
    String? fontFamily,
  }) {
    final isDark = brightness == material.Brightness.dark;
    
    // Fallback base color if material scheme isn't provided
    final primaryColor = materialColorScheme?.primary ?? (isDark ? const material.Color(0xFF6B9EFF) : const material.Color(0xFF0D47A1));
    
    final accentColor = AccentColor.swatch({
      'darkest': primaryColor.withValues(alpha: 0.9),
      'darker': primaryColor.withValues(alpha: 0.8),
      'dark': primaryColor.withValues(alpha: 0.7),
      'normal': primaryColor,
      'light': primaryColor.withValues(alpha: 0.7),
      'lighter': primaryColor.withValues(alpha: 0.6),
      'lightest': primaryColor.withValues(alpha: 0.5),
    });

    return FluentThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      accentColor: accentColor,
      fontFamily: fontFamily,
      visualDensity: VisualDensity.standard,
      focusTheme: FocusThemeData(
        glowFactor: isDark ? 2.0 : 1.0,
      ),
      // Map other material colors to fluent theme if needed
      scaffoldBackgroundColor: materialColorScheme?.surface,
      micaBackgroundColor: materialColorScheme?.surface,
      menuColor: materialColorScheme?.surfaceContainerHigh,
    );
  }
}
