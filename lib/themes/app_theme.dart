import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

// Light Theme Colors
const Color _lightPrimaryColor = Color(0xFF2563EB); // Royal Blue
const Color _lightSecondaryColor = Color(0xFF10B981); // Emerald
const Color _lightTertiaryColor = Color(0xFFF59E0B); // Amber
const Color _lightBackgroundColor = Color(0xFFFFFFFF);
const Color _lightSurfaceColor = Color(0xFFF5F5F5);
const Color _lightOnSurfaceColor = Color(0xFF111111);
const Color _lightOnSurfaceVariantColor = Color(0xFF666666);
const Color _lightErrorColor = Color(0xFFD32F2F);

// M3E Light Colors — Vibrant, High-Contrast Tonal Palettes
// Primary: Vibrant Coral-Red energy
const Color _m3eLightPrimary = Color(0xFF9C4030);
const Color _m3eLightOnPrimary = Color(0xFFFFFFFF);
const Color _m3eLightPrimaryContainer = Color(0xFFFFDAD3);
const Color _m3eLightOnPrimaryContainer = Color(0xFF410001);
// Secondary: Warm Terracotta
const Color _m3eLightSecondary = Color(0xFF775650);
const Color _m3eLightOnSecondary = Color(0xFFFFFFFF);
const Color _m3eLightSecondaryContainer = Color(0xFFFFDAD3);
const Color _m3eLightOnSecondaryContainer = Color(0xFF2C1511);
// Tertiary: Rich Teal
const Color _m3eLightTertiary = Color(0xFF6C5E2F);
const Color _m3eLightOnTertiary = Color(0xFFFFFFFF);
const Color _m3eLightTertiaryContainer = Color(0xFFF5E3A7);
const Color _m3eLightOnTertiaryContainer = Color(0xFF231C00);
// Error
const Color _m3eLightError = Color(0xFFBA1A1A);
const Color _m3eLightOnError = Color(0xFFFFFFFF);
const Color _m3eLightErrorContainer = Color(0xFFFFDAD6);
const Color _m3eLightOnErrorContainer = Color(0xFF410002);
// Surface tones — 5 distinct levels
const Color _m3eLightSurface = Color(0xFFFFF8F6);
const Color _m3eLightOnSurface = Color(0xFF201A19);
const Color _m3eLightSurfaceDim = Color(0xFFF0DED9);
const Color _m3eLightSurfaceBright = Color(0xFFFFF8F6);
const Color _m3eLightSurfaceContainerLowest = Color(0xFFFFFFFF);
const Color _m3eLightSurfaceContainerLow = Color(0xFFFFF1ED);
const Color _m3eLightSurfaceContainer = Color(0xFFFFEAE5);
const Color _m3eLightSurfaceContainerHigh = Color(0xFFFFE4DE);
const Color _m3eLightSurfaceContainerHighest = Color(0xFFF8DED8);
const Color _m3eLightOnSurfaceVariant = Color(0xFF534340);
// Outline
const Color _m3eLightOutline = Color(0xFF85736F);
const Color _m3eLightOutlineVariant = Color(0xFFD8C2BD);
// Inverse
const Color _m3eLightInverseSurface = Color(0xFF362F2D);
const Color _m3eLightInverseOnSurface = Color(0xFFFBEDE9);
const Color _m3eLightInversePrimary = Color(0xFFFFB4A8);
// Accent
const Color _m3eLightShadow = Color(0xFF000000);
const Color _m3eLightScrim = Color(0xFF000000);
const Color _m3eLightSurfaceTint = Color(0xFF9C4030);

// M3E Dark Colors — Deep, Rich Tonal Palettes
// Primary: Warm luminous coral
const Color _m3eDarkPrimary = Color(0xFFFFB4A8);
const Color _m3eDarkOnPrimary = Color(0xFF5E140A);
const Color _m3eDarkPrimaryContainer = Color(0xFF7D291C);
const Color _m3eDarkOnPrimaryContainer = Color(0xFFFFDAD3);
// Secondary: Luminous warm terracotta
const Color _m3eDarkSecondary = Color(0xFFE7BDB5);
const Color _m3eDarkOnSecondary = Color(0xFF442924);
const Color _m3eDarkSecondaryContainer = Color(0xFF5D3F3A);
const Color _m3eDarkOnSecondaryContainer = Color(0xFFFFDAD3);
// Tertiary: Luminous gold-teal
const Color _m3eDarkTertiary = Color(0xFFD8C68D);
const Color _m3eDarkOnTertiary = Color(0xFF3B3005);
const Color _m3eDarkTertiaryContainer = Color(0xFF53461A);
const Color _m3eDarkOnTertiaryContainer = Color(0xFFF5E3A7);
// Error
const Color _m3eDarkError = Color(0xFFFFB4AB);
const Color _m3eDarkOnError = Color(0xFF690005);
const Color _m3eDarkErrorContainer = Color(0xFF93000A);
const Color _m3eDarkOnErrorContainer = Color(0xFFFFDAD6);
// Surface tones — 5 distinct levels on deep base
const Color _m3eDarkSurface = Color(0xFF141211);
const Color _m3eDarkOnSurface = Color(0xFFEDE0DC);
const Color _m3eDarkSurfaceDim = Color(0xFF141211);
const Color _m3eDarkSurfaceBright = Color(0xFF3B3230);
const Color _m3eDarkSurfaceContainerLowest = Color(0xFF0E0D0C);
const Color _m3eDarkSurfaceContainerLow = Color(0xFF1D1A19);
const Color _m3eDarkSurfaceContainer = Color(0xFF211E1D);
const Color _m3eDarkSurfaceContainerHigh = Color(0xFF2C2827);
const Color _m3eDarkSurfaceContainerHighest = Color(0xFF373331);
const Color _m3eDarkOnSurfaceVariant = Color(0xFFD8C2BD);
// Outline
const Color _m3eDarkOutline = Color(0xFFA08C88);
const Color _m3eDarkOutlineVariant = Color(0xFF534340);
// Inverse
const Color _m3eDarkInverseSurface = Color(0xFFEDE0DC);
const Color _m3eDarkInverseOnSurface = Color(0xFF362F2D);
const Color _m3eDarkInversePrimary = Color(0xFF9C4030);
// Accent
const Color _m3eDarkShadow = Color(0xFF000000);
const Color _m3eDarkScrim = Color(0xFF000000);
const Color _m3eDarkSurfaceTint = Color(0xFFFFB4A8);

// Dark Theme Colors - Premium Dark Theme
const Color _darkPrimaryColor = Color(0xFF3B82F6);
const Color _darkSecondaryColor = Color(0xFF34D399);
const Color _darkTertiaryColor = Color(0xFFFBBF24);
const Color _darkBackgroundColor = Color(0xFF0C0F14);
const Color _darkSurfaceColor = Color(0xFF1A1D24);
const Color _darkSurfaceVariant = Color(0xFF252930);
const Color _darkOnSurfaceColor = Color(0xFFE8EAED);
const Color _darkOnSurfaceVariantColor = Color(0xFF9AA0A6);
const Color _darkErrorColor = Color(0xFFFF6B6B);

// M3E Shape Tokens
const double m3eShapeExtraSmall = 4.0;
const double m3eShapeSmall = 8.0;
const double m3eShapeMedium = 12.0;
const double m3eShapeLarge = 16.0;
const double m3eShapeExtraLarge = 28.0;
const double m3eShapeFull = 100.0;

// M3E Elevation Shadows
const List<BoxShadow> m3eElevation0 = [];
const List<BoxShadow> m3eElevation1 = [
  BoxShadow(color: Color(0x0A000000), offset: Offset(0, 1), blurRadius: 3),
  BoxShadow(color: Color(0x08000000), offset: Offset(0, 1), blurRadius: 2),
];
const List<BoxShadow> m3eElevation2 = [
  BoxShadow(color: Color(0x0D000000), offset: Offset(0, 2), blurRadius: 4),
  BoxShadow(color: Color(0x0A000000), offset: Offset(0, 1), blurRadius: 3),
];
const List<BoxShadow> m3eElevation3 = [
  BoxShadow(color: Color(0x14000000), offset: Offset(0, 4), blurRadius: 8),
  BoxShadow(color: Color(0x0D000000), offset: Offset(0, 2), blurRadius: 4),
];
const List<BoxShadow> m3eElevation4 = [
  BoxShadow(color: Color(0x17000000), offset: Offset(0, 6), blurRadius: 12),
  BoxShadow(color: Color(0x0F000000), offset: Offset(0, 3), blurRadius: 6),
];
const List<BoxShadow> m3eElevation5 = [
  BoxShadow(color: Color(0x1A000000), offset: Offset(0, 8), blurRadius: 16),
  BoxShadow(color: Color(0x12000000), offset: Offset(0, 4), blurRadius: 8),
];

// ... (SemanticColors class remains same)

class AppTheme {
  // Make constructor private to prevent instantiation
  AppTheme._();

  // Helper method to get theme based on brightness
  static ThemeData getTheme(Brightness brightness, {bool isM3E = false, bool highContrast = false, String? fontFamily}) {
    if (highContrast) {
      return brightness == Brightness.dark ? highContrastDark(fontFamily: fontFamily) : highContrastLight(fontFamily: fontFamily);
    }
    if (isM3E) {
      return brightness == Brightness.dark ? m3eDark(fontFamily: fontFamily) : m3eLight(fontFamily: fontFamily);
    }
    return brightness == Brightness.dark ? dark(fontFamily: fontFamily) : light(fontFamily: fontFamily);
  }

  static ThemeData light({String? fontFamily}) => _createTheme(Brightness.light, false, fontFamily);
  static ThemeData dark({String? fontFamily}) => _createTheme(Brightness.dark, false, fontFamily);
  static ThemeData m3eLight({String? fontFamily}) => _createTheme(Brightness.light, true, fontFamily);
  static ThemeData m3eDark({String? fontFamily}) => _createTheme(Brightness.dark, true, fontFamily);
  
  static ThemeData highContrastLight({String? fontFamily}) {
    final theme = light(fontFamily: fontFamily);
    return theme.copyWith(
      colorScheme: theme.colorScheme.copyWith(
        primary: Colors.black,
        onPrimary: Colors.white,
        surface: Colors.white,
        onSurface: Colors.black,
      ),
    );
  }

  static ThemeData highContrastDark({String? fontFamily}) {
    final theme = dark(fontFamily: fontFamily);
    return theme.copyWith(
      colorScheme: theme.colorScheme.copyWith(
        primary: Colors.white,
        onPrimary: Colors.black,
        surface: Colors.black,
        onSurface: Colors.white,
      ),
    );
  }

  static TextStyle _getTextStyle({
    required String? fontFamily,
    required double fontSize,
    required FontWeight fontWeight,
    double? letterSpacing,
    Color? color,
    double? height,
  }) {
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      color: color,
      height: height,
    );

    if (fontFamily == null || fontFamily.isEmpty || fontFamily == 'System') {
      return style;
    }

    try {
      return GoogleFonts.getFont(
        fontFamily,
        textStyle: style,
      );
    } catch (e) {
      debugPrint('Error loading font $fontFamily: $e');
      return style;
    }
  }

  static ThemeData _createTheme(Brightness brightness, bool isM3E, String? fontFamily) {
    final isDark = brightness == Brightness.dark;
    
    if (isM3E) {
      final colorScheme = isDark ? m3eDarkColorScheme : m3eLightColorScheme;
      final baseTheme = isDark ? _baseM3EDarkTheme : _baseM3ELightTheme;
      
      return baseTheme.copyWith(
        colorScheme: colorScheme,
        textTheme: m3eTextTheme(colorScheme.onSurface, fontFamily),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: const StadiumBorder(),
            textStyle: _getTextStyle(
              fontFamily: fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.primary,
            side: BorderSide(color: colorScheme.outline, width: 2),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: const StadiumBorder(),
            textStyle: _getTextStyle(
              fontFamily: fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            shape: const StadiumBorder(),
            textStyle: _getTextStyle(
              fontFamily: fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
            ),
          ),
        ),
        navigationBarTheme: baseTheme.navigationBarTheme.copyWith(
          labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
            final color = states.contains(WidgetState.selected)
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant;
            return _getTextStyle(
              fontFamily: fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            );
          }),
        ),
      );
    }

    // Standard theme implementation (simplified for brevity, should follow similar pattern)
    final colorScheme = isDark ? darkColorScheme : lightColorScheme;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: standardTextTheme(isDark ? _darkOnSurfaceColor : _lightOnSurfaceColor, fontFamily),
    );
  }

  // Define color schemes if not already defined as standalone constants
  static const ColorScheme m3eLightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: _m3eLightPrimary,
    onPrimary: _m3eLightOnPrimary,
    primaryContainer: _m3eLightPrimaryContainer,
    onPrimaryContainer: _m3eLightOnPrimaryContainer,
    secondary: _m3eLightSecondary,
    onSecondary: _m3eLightOnSecondary,
    secondaryContainer: _m3eLightSecondaryContainer,
    onSecondaryContainer: _m3eLightOnSecondaryContainer,
    tertiary: _m3eLightTertiary,
    onTertiary: _m3eLightOnTertiary,
    tertiaryContainer: _m3eLightTertiaryContainer,
    onTertiaryContainer: _m3eLightOnTertiaryContainer,
    error: _m3eLightError,
    onError: _m3eLightOnError,
    errorContainer: _m3eLightErrorContainer,
    onErrorContainer: _m3eLightOnErrorContainer,
    surface: _m3eLightSurface,
    onSurface: _m3eLightOnSurface,
    surfaceContainerHighest: _m3eLightSurfaceContainerHighest,
    outline: _m3eLightOutline,
    outlineVariant: _m3eLightOutlineVariant,
  );

  static const ColorScheme m3eDarkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: _m3eDarkPrimary,
    onPrimary: _m3eDarkOnPrimary,
    primaryContainer: _m3eDarkPrimaryContainer,
    onPrimaryContainer: _m3eDarkOnPrimaryContainer,
    secondary: _m3eDarkSecondary,
    onSecondary: _m3eDarkOnSecondary,
    secondaryContainer: _m3eDarkSecondaryContainer,
    onSecondaryContainer: _m3eDarkOnSecondaryContainer,
    tertiary: _m3eDarkTertiary,
    onTertiary: _m3eDarkOnTertiary,
    tertiaryContainer: _m3eDarkTertiaryContainer,
    onTertiaryContainer: _m3eDarkOnTertiaryContainer,
    error: _m3eDarkError,
    onError: _m3eDarkOnError,
    errorContainer: _m3eDarkErrorContainer,
    onErrorContainer: _m3eDarkOnErrorContainer,
    surface: _m3eDarkSurface,
    onSurface: _m3eDarkOnSurface,
    surfaceContainerHighest: _m3eDarkSurfaceContainerHighest,
    outline: _m3eDarkOutline,
    outlineVariant: _m3eDarkOutlineVariant,
  );

  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: _lightPrimaryColor,
    onPrimary: Colors.white,
    secondary: _lightSecondaryColor,
    onSecondary: Colors.white,
    surface: _lightBackgroundColor,
    onSurface: _lightOnSurfaceColor,
    error: _lightErrorColor,
    onError: Colors.white,
  );

  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: _darkPrimaryColor,
    onPrimary: Colors.white,
    secondary: _darkSecondaryColor,
    onSecondary: Colors.white,
    surface: _darkBackgroundColor,
    onSurface: _darkOnSurfaceColor,
    error: _darkErrorColor,
    onError: Colors.white,
  );

  // M3E Text Theme
  static TextTheme m3eTextTheme(Color color, String? fontFamily) => TextTheme(
    displayLarge: _getTextStyle(fontFamily: fontFamily, fontSize: 57, fontWeight: FontWeight.w400, letterSpacing: -0.25, color: color, height: 1.12),
    displayMedium: _getTextStyle(fontFamily: fontFamily, fontSize: 45, fontWeight: FontWeight.w400, letterSpacing: 0, color: color, height: 1.15),
    displaySmall: _getTextStyle(fontFamily: fontFamily, fontSize: 36, fontWeight: FontWeight.w400, letterSpacing: 0, color: color, height: 1.22),
    headlineLarge: _getTextStyle(fontFamily: fontFamily, fontSize: 32, fontWeight: FontWeight.w600, letterSpacing: 0, color: color, height: 1.25),
    headlineMedium: _getTextStyle(fontFamily: fontFamily, fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: 0, color: color, height: 1.28),
    headlineSmall: _getTextStyle(fontFamily: fontFamily, fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: 0, color: color, height: 1.33),
    titleLarge: _getTextStyle(fontFamily: fontFamily, fontSize: 22, fontWeight: FontWeight.w500, letterSpacing: 0, color: color, height: 1.27),
    titleMedium: _getTextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.15, color: color, height: 1.5),
    titleSmall: _getTextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1, color: color, height: 1.42),
    bodyLarge: _getTextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5, color: color.withValues(alpha: 0.8), height: 1.5),
    bodyMedium: _getTextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25, color: color.withValues(alpha: 0.8), height: 1.42),
    bodySmall: _getTextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4, color: color.withValues(alpha: 0.6), height: 1.33),
    labelLarge: _getTextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1, color: color, height: 1.42),
    labelMedium: _getTextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: color, height: 1.33),
    labelSmall: _getTextStyle(fontFamily: fontFamily, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: color, height: 1.45),
  );

  static TextTheme standardTextTheme(Color color, String? fontFamily) => TextTheme(
    displayLarge: _getTextStyle(fontFamily: fontFamily, fontSize: 57, fontWeight: FontWeight.w400, letterSpacing: -0.25, color: color, height: 1.12),
    displayMedium: _getTextStyle(fontFamily: fontFamily, fontSize: 45, fontWeight: FontWeight.w400, letterSpacing: 0, color: color, height: 1.15),
    displaySmall: _getTextStyle(fontFamily: fontFamily, fontSize: 36, fontWeight: FontWeight.w400, letterSpacing: 0, color: color, height: 1.22),
    headlineLarge: _getTextStyle(fontFamily: fontFamily, fontSize: 32, fontWeight: FontWeight.w400, letterSpacing: 0, color: color, height: 1.25),
    headlineMedium: _getTextStyle(fontFamily: fontFamily, fontSize: 28, fontWeight: FontWeight.w400, letterSpacing: 0, color: color, height: 1.28),
    headlineSmall: _getTextStyle(fontFamily: fontFamily, fontSize: 24, fontWeight: FontWeight.w400, letterSpacing: 0, color: color, height: 1.33),
    titleLarge: _getTextStyle(fontFamily: fontFamily, fontSize: 22, fontWeight: FontWeight.w400, letterSpacing: 0, color: color, height: 1.27),
    titleMedium: _getTextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.15, color: color, height: 1.5),
    titleSmall: _getTextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1, color: color, height: 1.42),
    bodyLarge: _getTextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5, color: color, height: 1.5),
    bodyMedium: _getTextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25, color: color, height: 1.42),
    bodySmall: _getTextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4, color: color, height: 1.33),
    labelLarge: _getTextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1, color: color, height: 1.42),
    labelMedium: _getTextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: color, height: 1.33),
    labelSmall: _getTextStyle(fontFamily: fontFamily, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: color, height: 1.45),
  );

  static final ThemeData _baseM3ELightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: _m3eLightSurfaceContainer,
      indicatorColor: _m3eLightSecondaryContainer,
    ),
    // ... add other default m3e light values here
  );

  static final ThemeData _baseM3EDarkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: _m3eDarkSurfaceContainer,
      indicatorColor: _m3eDarkSecondaryContainer,
    ),
    // ... add other default m3e dark values here
  );

  // Standard Button Styles
  static ButtonStyle get elevatedButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: _lightPrimaryColor,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
    textStyle: GoogleFonts.comfortaa(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      color: Colors.white,
    ),
  );

  static ButtonStyle get textButtonStyle => TextButton.styleFrom(
    foregroundColor: _lightPrimaryColor,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    textStyle: GoogleFonts.comfortaa(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      color: _lightPrimaryColor,
    ),
  );

  static ButtonStyle get outlinedButtonStyle => OutlinedButton.styleFrom(
    foregroundColor: _lightPrimaryColor,
    side: const BorderSide(color: _lightPrimaryColor),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
    textStyle: GoogleFonts.comfortaa(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      color: _lightPrimaryColor,
    ),
  );

  // M3E Button Style (Iconic Shapes + RobotoFlex)
  static ButtonStyle m3eButtonStyle(Color bg, Color fg) =>
      ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: const StadiumBorder(), // Iconic M3E shape
        textStyle: GoogleFonts.robotoFlex(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
      );

  // Standard Input Decoration
  static InputDecorationTheme get inputDecorationTheme => InputDecorationTheme(
    filled: true,
    fillColor: _lightSurfaceColor.withValues(alpha: 0.3),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: _lightPrimaryColor, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: _lightErrorColor),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: _lightErrorColor, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    hintStyle: textTheme.bodyMedium?.copyWith(
      color: _lightOnSurfaceVariantColor.withValues(alpha: 0.6),
    ),
    labelStyle: textTheme.bodyMedium,
    errorStyle: textTheme.bodySmall?.copyWith(color: _lightErrorColor),
  );

  // Standard Card Theme
  static CardThemeData get cardTheme => CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: const BorderSide(color: _lightSurfaceColor),
    ),
    color: _lightSurfaceColor,
  );

  // M3E Card Theme (High Contrast)
  static CardThemeData m3eCardTheme(Color surface, Color outline) =>
      CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28), // M3E Large rounding
          side: BorderSide(
            color: outline,
            width: 1.5,
          ), // Expressive containment
        ),
        color: surface,
      );

  // App Bar Theme
  static AppBarTheme get appBarTheme => AppBarTheme(
    elevation: 0,
    centerTitle: true,
    backgroundColor: _lightBackgroundColor,
    foregroundColor: _lightOnSurfaceColor,
    titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
    ),
  );

  // Bottom Navigation Bar Theme
  static NavigationBarThemeData get navigationBarTheme =>
      NavigationBarThemeData(
        indicatorColor: _lightPrimaryColor.withValues(alpha: 0.12),
        backgroundColor: Colors.transparent, // transparent for glass effect
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelSmall!.copyWith(color: _lightPrimaryColor);
          }
          return textTheme.labelSmall!.copyWith(
            color: _lightOnSurfaceVariantColor,
          );
        }),
      );

  // Tab Bar Theme
  static TabBarThemeData get tabBarTheme => TabBarThemeData(
    labelColor: _lightPrimaryColor,
    unselectedLabelColor: _lightOnSurfaceVariantColor,
    indicator: const UnderlineTabIndicator(
      borderSide: BorderSide(color: _lightPrimaryColor, width: 2),
    ),
    labelStyle: textTheme.labelLarge,
    unselectedLabelStyle: textTheme.labelLarge,
  );

  // Dialog Theme
  static DialogThemeData get dialogTheme => DialogThemeData(
    backgroundColor: _lightSurfaceColor,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    titleTextStyle: textTheme.headlineSmall,
    contentTextStyle: textTheme.bodyMedium,
  );

  // SnackBar Theme
  static SnackBarThemeData get snackBarTheme => SnackBarThemeData(
    backgroundColor: _lightOnSurfaceColor,
    contentTextStyle: textTheme.bodyMedium?.copyWith(color: _lightSurfaceColor),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );

  // Bottom Sheet Theme
  static BottomSheetThemeData get bottomSheetTheme => const BottomSheetThemeData(
    backgroundColor: _lightSurfaceColor,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
  );

  // Chip Theme
  static ChipThemeData get chipTheme => ChipThemeData(
    backgroundColor: _lightSurfaceColor.withValues(alpha: 0.3),
    disabledColor: _lightSurfaceColor.withValues(alpha: 0.3),
    selectedColor: _lightPrimaryColor.withValues(alpha: 0.12),
    secondarySelectedColor: _lightPrimaryColor.withValues(alpha: 0.12),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    labelStyle: textTheme.labelMedium,
    secondaryLabelStyle: textTheme.labelMedium?.copyWith(
      color: _lightPrimaryColor,
    ),
    brightness: Brightness.light,
  );

  // Divider Theme
  static DividerThemeData dividerTheme = const DividerThemeData(
    color: Color(0x1F1C1B1F),
    thickness: 1,
    space: 0,
    indent: 16,
    endIndent: 16,
  );

  // Standard Light Theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: _lightPrimaryColor,
      onPrimary: Colors.white,
      primaryContainer: _lightPrimaryColor,
      onPrimaryContainer: Colors.white,
      secondary: _lightSecondaryColor,
      onSecondary: Colors.white,
      secondaryContainer: _lightSecondaryColor.withValues(alpha: 0.1),
      onSecondaryContainer: _lightSecondaryColor,
      tertiary: _lightTertiaryColor,
      onTertiary: Colors.white,
      tertiaryContainer: _lightTertiaryColor.withValues(alpha: 0.1),
      onTertiaryContainer: _lightTertiaryColor,
      surface: _lightBackgroundColor,
      onSurface: _lightOnSurfaceColor,
      surfaceContainerHighest: _lightSurfaceColor,
      error: _lightErrorColor,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.transparent,
    textTheme: textTheme,
    appBarTheme: appBarTheme,
    cardTheme: cardTheme,
    dialogTheme: dialogTheme,
    snackBarTheme: snackBarTheme,
    bottomSheetTheme: bottomSheetTheme,
    chipTheme: chipTheme,
    dividerTheme: dividerTheme,
    inputDecorationTheme: inputDecorationTheme,
    elevatedButtonTheme: ElevatedButtonThemeData(style: elevatedButtonStyle),
    textButtonTheme: TextButtonThemeData(style: textButtonStyle),
    outlinedButtonTheme: OutlinedButtonThemeData(style: outlinedButtonStyle),
    navigationBarTheme: navigationBarTheme,
    tabBarTheme: tabBarTheme,
  );

  // Standard Dark Theme
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: _darkPrimaryColor,
      onPrimary: Colors.black,
      primaryContainer: _darkPrimaryColor.withValues(alpha: 0.2),
      onPrimaryContainer: _darkPrimaryColor,
      secondary: _darkSecondaryColor,
      onSecondary: Colors.black,
      secondaryContainer: _darkSecondaryColor.withValues(alpha: 0.2),
      onSecondaryContainer: _darkSecondaryColor,
      tertiary: _darkTertiaryColor,
      onTertiary: Colors.black,
      tertiaryContainer: _darkTertiaryColor.withValues(alpha: 0.2),
      onTertiaryContainer: _darkTertiaryColor,
      surface: _darkSurfaceColor,
      onSurface: _darkOnSurfaceColor,
      surfaceContainerHighest: _darkSurfaceVariant,
      error: _darkErrorColor,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.transparent,
    textTheme: TextTheme(
      displayLarge: textTheme.displayLarge?.copyWith(color: Colors.white),
      displayMedium: textTheme.displayMedium?.copyWith(color: Colors.white),
      displaySmall: textTheme.displaySmall?.copyWith(color: Colors.white),
      headlineLarge: textTheme.headlineLarge?.copyWith(color: Colors.white),
      headlineMedium: textTheme.headlineMedium?.copyWith(color: Colors.white),
      headlineSmall: textTheme.headlineSmall?.copyWith(color: Colors.white),
      titleLarge: textTheme.titleLarge?.copyWith(color: Colors.white),
      titleMedium: textTheme.titleMedium?.copyWith(color: Colors.white),
      titleSmall: textTheme.titleSmall?.copyWith(color: Colors.white),
      bodyLarge: textTheme.bodyLarge?.copyWith(
        color: Colors.white.withValues(alpha: 0.9),
      ),
      bodyMedium: textTheme.bodyMedium?.copyWith(
        color: Colors.white.withValues(alpha: 0.8),
      ),
      bodySmall: textTheme.bodySmall?.copyWith(
        color: Colors.white.withValues(alpha: 0.6),
      ),
      labelLarge: textTheme.labelLarge?.copyWith(color: Colors.white),
      labelMedium: textTheme.labelMedium?.copyWith(
        color: Colors.white.withValues(alpha: 0.8),
      ),
      labelSmall: textTheme.labelSmall?.copyWith(
        color: Colors.white.withValues(alpha: 0.6),
      ),
    ),
    appBarTheme: appBarTheme.copyWith(
      backgroundColor: Colors.black.withValues(alpha: 0.2),
      foregroundColor: _darkOnSurfaceColor,
      titleTextStyle: appBarTheme.titleTextStyle?.copyWith(
        color: _darkOnSurfaceColor,
      ),
      systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    ),
    cardTheme: cardTheme.copyWith(
      color: _darkSurfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _darkSurfaceColor.withValues(alpha: 0.5)),
      ),
    ),
    dialogTheme: dialogTheme.copyWith(
      backgroundColor: _darkSurfaceVariant,
      titleTextStyle: dialogTheme.titleTextStyle?.copyWith(
        color: _darkOnSurfaceColor,
      ),
      contentTextStyle: dialogTheme.contentTextStyle?.copyWith(
        color: _darkOnSurfaceColor.withValues(alpha: 0.9),
      ),
    ),
    snackBarTheme: snackBarTheme.copyWith(
      backgroundColor: _darkSurfaceVariant,
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: _darkOnSurfaceColor,
      ),
    ),
    bottomSheetTheme: bottomSheetTheme.copyWith(
      backgroundColor: _darkSurfaceColor,
    ),
    chipTheme: chipTheme.copyWith(
      backgroundColor: _darkSurfaceColor.withValues(alpha: 0.8),
      disabledColor: _darkSurfaceColor.withValues(alpha: 0.5),
      selectedColor: _darkPrimaryColor.withValues(alpha: 0.2),
      secondarySelectedColor: _darkPrimaryColor.withValues(alpha: 0.2),
      secondaryLabelStyle: chipTheme.secondaryLabelStyle?.copyWith(
        color: _darkPrimaryColor,
      ),
    ),
    dividerTheme: dividerTheme.copyWith(
      color: _darkSurfaceColor.withValues(alpha: 0.8),
    ),
    inputDecorationTheme: inputDecorationTheme.copyWith(
      fillColor: _darkSurfaceColor.withValues(alpha: 0.6),
      hintStyle: inputDecorationTheme.hintStyle?.copyWith(
        color: _darkOnSurfaceVariantColor.withValues(alpha: 0.6),
      ),
      labelStyle: inputDecorationTheme.labelStyle?.copyWith(
        color: _darkOnSurfaceColor.withValues(alpha: 0.9),
      ),
      errorStyle: inputDecorationTheme.errorStyle?.copyWith(
        color: _darkErrorColor,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _darkPrimaryColor, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _darkPrimaryColor,
        foregroundColor: _darkBackgroundColor,
        elevation: 8,
        shadowColor: _darkPrimaryColor.withValues(alpha: 0.5),
        surfaceTintColor: _darkPrimaryColor,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: _darkPrimaryColor),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _darkPrimaryColor,
        side: const BorderSide(color: _darkPrimaryColor),
      ),
    ),
    navigationBarTheme: navigationBarTheme.copyWith(
      indicatorColor: _darkPrimaryColor.withValues(alpha: 0.2),
      labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
        if (states.contains(WidgetState.selected)) {
          return textTheme.labelSmall!.copyWith(color: _darkPrimaryColor);
        }
        return textTheme.labelSmall!.copyWith(
          color: _darkOnSurfaceVariantColor,
        );
      }),
    ),
    tabBarTheme: tabBarTheme.copyWith(
      labelColor: _darkPrimaryColor,
      unselectedLabelColor: _darkOnSurfaceVariantColor,
      indicator: const UnderlineTabIndicator(
        borderSide: BorderSide(color: _darkPrimaryColor, width: 2),
      ),
    ),
  );

  // M3E Light Theme — Rich, Vibrant, Expressive
  static final ThemeData m3eLightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: _m3eLightPrimary,
      onPrimary: _m3eLightOnPrimary,
      primaryContainer: _m3eLightPrimaryContainer,
      onPrimaryContainer: _m3eLightOnPrimaryContainer,
      secondary: _m3eLightSecondary,
      onSecondary: _m3eLightOnSecondary,
      secondaryContainer: _m3eLightSecondaryContainer,
      onSecondaryContainer: _m3eLightOnSecondaryContainer,
      tertiary: _m3eLightTertiary,
      onTertiary: _m3eLightOnTertiary,
      tertiaryContainer: _m3eLightTertiaryContainer,
      onTertiaryContainer: _m3eLightOnTertiaryContainer,
      error: _m3eLightError,
      onError: _m3eLightOnError,
      errorContainer: _m3eLightErrorContainer,
      onErrorContainer: _m3eLightOnErrorContainer,
      surface: _m3eLightSurface,
      onSurface: _m3eLightOnSurface,
      surfaceDim: _m3eLightSurfaceDim,
      surfaceBright: _m3eLightSurfaceBright,
      surfaceContainerLowest: _m3eLightSurfaceContainerLowest,
      surfaceContainerLow: _m3eLightSurfaceContainerLow,
      surfaceContainer: _m3eLightSurfaceContainer,
      surfaceContainerHigh: _m3eLightSurfaceContainerHigh,
      surfaceContainerHighest: _m3eLightSurfaceContainerHighest,
      onSurfaceVariant: _m3eLightOnSurfaceVariant,
      outline: _m3eLightOutline,
      outlineVariant: _m3eLightOutlineVariant,
      inverseSurface: _m3eLightInverseSurface,
      onInverseSurface: _m3eLightInverseOnSurface,
      inversePrimary: _m3eLightInversePrimary,
      shadow: _m3eLightShadow,
      scrim: _m3eLightScrim,
      surfaceTint: _m3eLightSurfaceTint,
    ),
    scaffoldBackgroundColor: _m3eLightSurface,
    textTheme: m3eTextTheme(_m3eLightOnSurface),
    // Cards — XL shape, tonal surface, Level 1 elevation
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(m3eShapeExtraLarge),
        side: const BorderSide(color: _m3eLightOutlineVariant, width: 1),
      ),
      color: _m3eLightSurfaceContainerLow,
      clipBehavior: Clip.antiAlias,
    ),
    // Elevated Buttons — Full (stadium) shape, vibrant primary
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _m3eLightPrimary,
        foregroundColor: _m3eLightOnPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: const StadiumBorder(),
        textStyle: GoogleFonts.robotoFlex(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
      ),
    ),
    // Outlined Buttons — Full shape, 2px stroke
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _m3eLightPrimary,
        side: const BorderSide(color: _m3eLightOutline, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: const StadiumBorder(),
        textStyle: GoogleFonts.robotoFlex(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
      ),
    ),
    // Text Buttons — Full shape, primary color
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _m3eLightPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: const StadiumBorder(),
        textStyle: GoogleFonts.robotoFlex(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
      ),
    ),
    // FAB — Large shape, vibrant, Level 3 elevation
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _m3eLightPrimaryContainer,
      foregroundColor: _m3eLightOnPrimaryContainer,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(m3eShapeLarge),
      ),
    ),
    // Chips — Medium shape, tonal selected
    chipTheme: ChipThemeData(
      backgroundColor: _m3eLightSurfaceContainerHighest,
      disabledColor: _m3eLightSurfaceContainerHighest.withValues(alpha: 0.5),
      selectedColor: _m3eLightSecondaryContainer,
      secondarySelectedColor: _m3eLightSecondaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(m3eShapeMedium),
      ),
      labelStyle: GoogleFonts.robotoFlex(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: _m3eLightOnSurfaceVariant,
      ),
      secondaryLabelStyle: GoogleFonts.robotoFlex(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: _m3eLightOnSecondaryContainer,
      ),
      brightness: Brightness.light,
    ),
    // Dialogs — XL shape, Level 3 elevation
    dialogTheme: DialogThemeData(
      backgroundColor: _m3eLightSurfaceContainerHigh,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(m3eShapeExtraLarge),
      ),
      titleTextStyle: GoogleFonts.robotoFlex(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: _m3eLightOnSurface,
      ),
      contentTextStyle: GoogleFonts.robotoFlex(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: _m3eLightOnSurfaceVariant,
      ),
    ),
    // Bottom Sheets — XL top radius, Level 4 elevation
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: _m3eLightSurfaceContainerHigh,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(m3eShapeExtraLarge),
        ),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    // Input Decorations — Large shape, tonal fill
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _m3eLightSurfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(m3eShapeLarge),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(m3eShapeLarge),
        borderSide: const BorderSide(color: _m3eLightOutlineVariant, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(m3eShapeLarge),
        borderSide: const BorderSide(color: _m3eLightPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(m3eShapeLarge),
        borderSide: const BorderSide(color: _m3eLightError, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(m3eShapeLarge),
        borderSide: const BorderSide(color: _m3eLightError, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: GoogleFonts.robotoFlex(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: _m3eLightOnSurfaceVariant.withValues(alpha: 0.6),
      ),
      labelStyle: GoogleFonts.robotoFlex(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: _m3eLightOnSurfaceVariant,
      ),
      errorStyle: GoogleFonts.robotoFlex(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: _m3eLightError,
      ),
    ),
    // App Bar — tonal surface, M3E typography
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: _m3eLightSurface,
      foregroundColor: _m3eLightOnSurface,
      titleTextStyle: GoogleFonts.robotoFlex(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: _m3eLightOnSurface,
      ),
      systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
    ),
    // Navigation Bar — Full indicator, tonal surface
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: _m3eLightSurfaceContainer,
      indicatorColor: _m3eLightSecondaryContainer,
      indicatorShape: const StadiumBorder(),
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.robotoFlex(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: _m3eLightOnSurface,
          );
        }
        return GoogleFonts.robotoFlex(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: _m3eLightOnSurfaceVariant,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: _m3eLightOnSurface, size: 24);
        }
        return const IconThemeData(color: _m3eLightOnSurfaceVariant, size: 24);
      }),
    ),
    // Tab Bar
    tabBarTheme: TabBarThemeData(
      labelColor: _m3eLightPrimary,
      unselectedLabelColor: _m3eLightOnSurfaceVariant,
      indicator: const UnderlineTabIndicator(
        borderSide: BorderSide(color: _m3eLightPrimary, width: 2),
      ),
      labelStyle: GoogleFonts.robotoFlex(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: GoogleFonts.robotoFlex(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
    // SnackBar — Medium shape, inverse surface
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _m3eLightInverseSurface,
      contentTextStyle: GoogleFonts.robotoFlex(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: _m3eLightInverseOnSurface,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(m3eShapeMedium),
      ),
      elevation: 3,
    ),
    // Divider
    dividerTheme: const DividerThemeData(
      color: Color(0x1F1C1B1F),
      thickness: 1,
      space: 0,
      indent: 16,
      endIndent: 16,
    ),
    // Switch
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return _m3eLightPrimary;
        }
        return _m3eLightOutline;
      }),
      trackColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return _m3eLightPrimaryContainer;
        }
        return _m3eLightSurfaceContainerHighest;
      }),
    ),
    // Checkbox
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return _m3eLightPrimary;
        }
        return _m3eLightOutline;
      }),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(m3eShapeSmall),
      ),
    ),
    // Radio
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return _m3eLightPrimary;
        }
        return _m3eLightOutline;
      }),
    ),
    // Slider
    sliderTheme: SliderThemeData(
      activeTrackColor: _m3eLightPrimary,
      inactiveTrackColor: _m3eLightPrimaryContainer,
      thumbColor: _m3eLightPrimary,
      overlayColor: _m3eLightPrimary.withValues(alpha: 0.12),
    ),
    // Progress Indicator
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: _m3eLightPrimary,
      linearTrackColor: _m3eLightPrimaryContainer,
    ),
  );

  // M3E Dark Theme — Deep, Rich, Expressive
  static final ThemeData m3eDarkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: _m3eDarkPrimary,
      onPrimary: _m3eDarkOnPrimary,
      primaryContainer: _m3eDarkPrimaryContainer,
      onPrimaryContainer: _m3eDarkOnPrimaryContainer,
      secondary: _m3eDarkSecondary,
      onSecondary: _m3eDarkOnSecondary,
      secondaryContainer: _m3eDarkSecondaryContainer,
      onSecondaryContainer: _m3eDarkOnSecondaryContainer,
      tertiary: _m3eDarkTertiary,
      onTertiary: _m3eDarkOnTertiary,
      tertiaryContainer: _m3eDarkTertiaryContainer,
      onTertiaryContainer: _m3eDarkOnTertiaryContainer,
      error: _m3eDarkError,
      onError: _m3eDarkOnError,
      errorContainer: _m3eDarkErrorContainer,
      onErrorContainer: _m3eDarkOnErrorContainer,
      surface: _m3eDarkSurface,
      onSurface: _m3eDarkOnSurface,
      surfaceDim: _m3eDarkSurfaceDim,
      surfaceBright: _m3eDarkSurfaceBright,
      surfaceContainerLowest: _m3eDarkSurfaceContainerLowest,
      surfaceContainerLow: _m3eDarkSurfaceContainerLow,
      surfaceContainer: _m3eDarkSurfaceContainer,
      surfaceContainerHigh: _m3eDarkSurfaceContainerHigh,
      surfaceContainerHighest: _m3eDarkSurfaceContainerHighest,
      onSurfaceVariant: _m3eDarkOnSurfaceVariant,
      outline: _m3eDarkOutline,
      outlineVariant: _m3eDarkOutlineVariant,
      inverseSurface: _m3eDarkInverseSurface,
      onInverseSurface: _m3eDarkInverseOnSurface,
      inversePrimary: _m3eDarkInversePrimary,
      shadow: _m3eDarkShadow,
      scrim: _m3eDarkScrim,
      surfaceTint: _m3eDarkSurfaceTint,
    ),
    scaffoldBackgroundColor: _m3eDarkSurface,
    textTheme: m3eTextTheme(_m3eDarkOnSurface),
    // Cards — XL shape, tonal surface, Level 1 elevation
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(m3eShapeExtraLarge),
        side: const BorderSide(color: _m3eDarkOutlineVariant, width: 1),
      ),
      color: _m3eDarkSurfaceContainerLow,
      clipBehavior: Clip.antiAlias,
    ),
    // Elevated Buttons — Full shape, vibrant primary
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _m3eDarkPrimary,
        foregroundColor: _m3eDarkOnPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: const StadiumBorder(),
        textStyle: GoogleFonts.robotoFlex(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
      ),
    ),
    // Outlined Buttons — Full shape, 2px stroke
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _m3eDarkPrimary,
        side: const BorderSide(color: _m3eDarkOutline, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: const StadiumBorder(),
        textStyle: GoogleFonts.robotoFlex(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
      ),
    ),
    // Text Buttons — Full shape, primary color
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _m3eDarkPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: const StadiumBorder(),
        textStyle: GoogleFonts.robotoFlex(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
      ),
    ),
    // FAB — Large shape, vibrant, Level 3 elevation
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _m3eDarkPrimaryContainer,
      foregroundColor: _m3eDarkOnPrimaryContainer,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(m3eShapeLarge),
      ),
    ),
    // Chips — Medium shape, tonal selected
    chipTheme: ChipThemeData(
      backgroundColor: _m3eDarkSurfaceContainerHighest,
      disabledColor: _m3eDarkSurfaceContainerHighest.withValues(alpha: 0.5),
      selectedColor: _m3eDarkSecondaryContainer,
      secondarySelectedColor: _m3eDarkSecondaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(m3eShapeMedium),
      ),
      labelStyle: GoogleFonts.robotoFlex(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: _m3eDarkOnSurfaceVariant,
      ),
      secondaryLabelStyle: GoogleFonts.robotoFlex(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: _m3eDarkOnSecondaryContainer,
      ),
      brightness: Brightness.dark,
    ),
    // Dialogs — XL shape, Level 3 elevation
    dialogTheme: DialogThemeData(
      backgroundColor: _m3eDarkSurfaceContainerHigh,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(m3eShapeExtraLarge),
      ),
      titleTextStyle: GoogleFonts.robotoFlex(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: _m3eDarkOnSurface,
      ),
      contentTextStyle: GoogleFonts.robotoFlex(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: _m3eDarkOnSurfaceVariant,
      ),
    ),
    // Bottom Sheets — XL top radius, Level 4 elevation
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: _m3eDarkSurfaceContainerHigh,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(m3eShapeExtraLarge),
        ),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    // Input Decorations — Large shape, tonal fill
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _m3eDarkSurfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(m3eShapeLarge),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(m3eShapeLarge),
        borderSide: const BorderSide(color: _m3eDarkOutlineVariant, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(m3eShapeLarge),
        borderSide: const BorderSide(color: _m3eDarkPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(m3eShapeLarge),
        borderSide: const BorderSide(color: _m3eDarkError, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(m3eShapeLarge),
        borderSide: const BorderSide(color: _m3eDarkError, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: GoogleFonts.robotoFlex(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: _m3eDarkOnSurfaceVariant.withValues(alpha: 0.6),
      ),
      labelStyle: GoogleFonts.robotoFlex(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: _m3eDarkOnSurfaceVariant,
      ),
      errorStyle: GoogleFonts.robotoFlex(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: _m3eDarkError,
      ),
    ),
    // App Bar — tonal surface, M3E typography
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: _m3eDarkSurface,
      foregroundColor: _m3eDarkOnSurface,
      titleTextStyle: GoogleFonts.robotoFlex(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: _m3eDarkOnSurface,
      ),
      systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    ),
    // Navigation Bar — Full indicator, tonal surface
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: _m3eDarkSurfaceContainer,
      indicatorColor: _m3eDarkSecondaryContainer,
      indicatorShape: const StadiumBorder(),
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.robotoFlex(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: _m3eDarkOnSurface,
          );
        }
        return GoogleFonts.robotoFlex(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: _m3eDarkOnSurfaceVariant,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: _m3eDarkOnSurface, size: 24);
        }
        return const IconThemeData(color: _m3eDarkOnSurfaceVariant, size: 24);
      }),
    ),
    // Tab Bar
    tabBarTheme: TabBarThemeData(
      labelColor: _m3eDarkPrimary,
      unselectedLabelColor: _m3eDarkOnSurfaceVariant,
      indicator: const UnderlineTabIndicator(
        borderSide: BorderSide(color: _m3eDarkPrimary, width: 2),
      ),
      labelStyle: GoogleFonts.robotoFlex(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: GoogleFonts.robotoFlex(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
    // SnackBar — Medium shape, inverse surface
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _m3eDarkInverseSurface,
      contentTextStyle: GoogleFonts.robotoFlex(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: _m3eDarkInverseOnSurface,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(m3eShapeMedium),
      ),
      elevation: 3,
    ),
    // Divider
    dividerTheme: const DividerThemeData(
      color: _m3eDarkOutlineVariant,
      thickness: 1,
      space: 0,
      indent: 16,
      endIndent: 16,
    ),
    // Switch
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return _m3eDarkPrimary;
        }
        return _m3eDarkOutline;
      }),
      trackColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return _m3eDarkPrimaryContainer;
        }
        return _m3eDarkSurfaceContainerHighest;
      }),
    ),
    // Checkbox
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return _m3eDarkPrimary;
        }
        return _m3eDarkOutline;
      }),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(m3eShapeSmall),
      ),
    ),
    // Radio
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return _m3eDarkPrimary;
        }
        return _m3eDarkOutline;
      }),
    ),
    // Slider
    sliderTheme: SliderThemeData(
      activeTrackColor: _m3eDarkPrimary,
      inactiveTrackColor: _m3eDarkPrimaryContainer,
      thumbColor: _m3eDarkPrimary,
      overlayColor: _m3eDarkPrimary.withValues(alpha: 0.12),
    ),
    // Progress Indicator
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: _m3eDarkPrimary,
      linearTrackColor: _m3eDarkPrimaryContainer,
    ),
  );

  static final ThemeData highContrastLightTheme = lightTheme.copyWith(
    colorScheme: lightTheme.colorScheme.copyWith(
      primary: Colors.black,
      onPrimary: Colors.white,
      surface: Colors.white,
      onSurface: Colors.black,
    ),
    textTheme: lightTheme.textTheme.apply(
      displayColor: Colors.black,
      bodyColor: Colors.black,
    ),
  );

  static final ThemeData highContrastDarkTheme = darkTheme.copyWith(
    colorScheme: darkTheme.colorScheme.copyWith(
      primary: Colors.white,
      onPrimary: Colors.black,
      surface: Colors.black,
      onSurface: Colors.white,
    ),
    textTheme: darkTheme.textTheme.apply(
      displayColor: Colors.white,
      bodyColor: Colors.white,
    ),
  );
}
