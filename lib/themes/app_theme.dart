import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:oasis/themes/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData getTheme({
    required ColorScheme colorScheme,
    String? fontFamily,
  }) {
    final isDark = colorScheme.brightness == Brightness.dark;
    final defaultFont = fontFamily ?? 'Inter';

    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: _buildTextTheme(colorScheme.onSurface, defaultFont),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: colorScheme.surface.withValues(alpha: 0.8),
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: _getTextStyle(
          fontFamily: 'Cormorant Garamond',
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
          isItalic: true,
        ),
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
        ),
        color: colorScheme.surfaceContainerLow,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const StadiumBorder(),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return _getTextStyle(
            fontFamily: defaultFont,
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.bold : FontWeight.normal,
            color: colorScheme.onSurface,
          );
        }),
      ),
      extensions: [
        AppThemeExtension(
          card: colorScheme.surfaceContainer,
          divider: colorScheme.outlineVariant,
          info: const Color(0xFF2196F3), // Standard Blue Info color
        ),
      ],
    );
  }

  static TextTheme _buildTextTheme(Color color, String font) {
    return TextTheme(
      displayLarge: _getTextStyle(fontFamily: font, fontSize: 32, fontWeight: FontWeight.bold, color: color),
      bodyLarge: _getTextStyle(fontFamily: font, fontSize: 16, fontWeight: FontWeight.normal, color: color),
      bodyMedium: _getTextStyle(fontFamily: font, fontSize: 14, fontWeight: FontWeight.normal, color: color),
      labelLarge: _getTextStyle(fontFamily: font, fontSize: 14, fontWeight: FontWeight.bold, color: color),
    );
  }

  static TextStyle _getTextStyle({
    required String? fontFamily,
    required double fontSize,
    required FontWeight fontWeight,
    Color? color,
    bool isItalic = false,
  }) {
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
    );

    if (fontFamily == null || fontFamily == 'System') return style;

    try {
      return GoogleFonts.getFont(fontFamily, textStyle: style);
    } catch (e) {
      return style.copyWith(fontFamily: fontFamily);
    }
  }
}
