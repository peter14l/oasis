import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // Make constructor private to prevent instantiation
  AppTheme._();

  // Helper method to get theme based on brightness
  static ThemeData getTheme(Brightness brightness, {bool isM3E = false, bool highContrast = false, String? fontFamily, ColorScheme? dynamicColorScheme}) {
    if (highContrast) {
      return brightness == Brightness.dark ? highContrastDark(fontFamily: fontFamily) : highContrastLight(fontFamily: fontFamily);
    }
    if (isM3E) {
      return brightness == Brightness.dark 
          ? m3eDark(fontFamily: fontFamily, dynamicColorScheme: dynamicColorScheme) 
          : m3eLight(fontFamily: fontFamily, dynamicColorScheme: dynamicColorScheme);
    }
    return brightness == Brightness.dark 
        ? dark(fontFamily: fontFamily, dynamicColorScheme: dynamicColorScheme) 
        : light(fontFamily: fontFamily, dynamicColorScheme: dynamicColorScheme);
  }

  static ThemeData light({String? fontFamily, ColorScheme? dynamicColorScheme}) => _createTheme(Brightness.light, false, fontFamily, dynamicColorScheme);
  static ThemeData dark({String? fontFamily, ColorScheme? dynamicColorScheme}) => _createTheme(Brightness.dark, false, fontFamily, dynamicColorScheme);
  static ThemeData m3eLight({String? fontFamily, ColorScheme? dynamicColorScheme}) => _createTheme(Brightness.light, true, fontFamily, dynamicColorScheme);
  static ThemeData m3eDark({String? fontFamily, ColorScheme? dynamicColorScheme}) => _createTheme(Brightness.dark, true, fontFamily, dynamicColorScheme);
  
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

  static ThemeData _createTheme(Brightness brightness, bool isM3E, String? fontFamily, ColorScheme? dynamicColorScheme) {
    final isDark = brightness == Brightness.dark;
    
    if (isM3E) {
      var colorScheme = isDark ? m3eDarkColorScheme : m3eLightColorScheme;
      if (dynamicColorScheme != null) {
        colorScheme = dynamicColorScheme;
      }
      final textTheme = m3eTextTheme(colorScheme.onSurface, fontFamily);
      
      return ThemeData(
        useMaterial3: true,
        brightness: brightness,
        colorScheme: colorScheme,
        textTheme: textTheme,
        scaffoldBackgroundColor: isDark ? _m3eDarkSurface : _m3eLightSurface,
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
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: isDark ? _m3eDarkSurfaceContainer : _m3eLightSurfaceContainer,
          indicatorColor: isDark ? _m3eDarkSecondaryContainer : _m3eLightSecondaryContainer,
          indicatorShape: const StadiumBorder(),
          elevation: 0,
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
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(m3eShapeExtraLarge),
            side: BorderSide(color: colorScheme.outlineVariant, width: 1),
          ),
          color: isDark ? _m3eDarkSurfaceContainerLow : _m3eLightSurfaceContainerLow,
          clipBehavior: Clip.antiAlias,
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: isDark ? _m3eDarkSurface : _m3eLightSurface,
          foregroundColor: colorScheme.onSurface,
          titleTextStyle: _getTextStyle(
            fontFamily: fontFamily,
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
          systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: isDark ? _m3eDarkSurfaceContainerLow : _m3eLightSurfaceContainerLow,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(m3eShapeLarge),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(m3eShapeLarge),
            borderSide: BorderSide(color: colorScheme.outlineVariant, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(m3eShapeLarge),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(m3eShapeLarge),
            borderSide: BorderSide(color: colorScheme.error, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(m3eShapeLarge),
            borderSide: BorderSide(color: colorScheme.error, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          hintStyle: _getTextStyle(
            fontFamily: fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          labelStyle: _getTextStyle(
            fontFamily: fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: colorScheme.onSurfaceVariant,
          ),
          errorStyle: _getTextStyle(
            fontFamily: fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: colorScheme.error,
          ),
        ),
      );
    }

    var colorScheme = isDark ? darkColorScheme : lightColorScheme;
    if (dynamicColorScheme != null) {
      colorScheme = dynamicColorScheme;
    }
    final textTheme = standardTextTheme(colorScheme.onSurface, fontFamily);
    
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: isDark ? Colors.black.withValues(alpha: 0.2) : _lightBackgroundColor,
        foregroundColor: isDark ? _darkOnSurfaceColor : _lightOnSurfaceColor,
        titleTextStyle: _getTextStyle(
          fontFamily: fontFamily,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: isDark ? _darkOnSurfaceColor : _lightOnSurfaceColor,
        ),
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: isDark ? _darkSurfaceColor.withValues(alpha: 0.5) : _lightSurfaceColor),
        ),
        color: isDark ? _darkSurfaceVariant : _lightSurfaceColor,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: (isDark ? _darkSurfaceColor : _lightSurfaceColor).withValues(alpha: isDark ? 0.6 : 0.3),
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
          borderSide: BorderSide(color: isDark ? _darkPrimaryColor : _lightPrimaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDark ? _darkErrorColor : _lightErrorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDark ? _darkErrorColor : _lightErrorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: _getTextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: (isDark ? _darkOnSurfaceVariantColor : _lightOnSurfaceVariantColor).withValues(alpha: 0.6),
        ),
        labelStyle: _getTextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: (isDark ? _darkOnSurfaceColor : _lightOnSurfaceColor).withValues(alpha: 0.9),
        ),
        errorStyle: _getTextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: isDark ? _darkErrorColor : _lightErrorColor,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: (isDark ? _darkPrimaryColor : _lightPrimaryColor).withValues(alpha: isDark ? 0.2 : 0.12),
        backgroundColor: Colors.transparent,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
          final color = states.contains(WidgetState.selected)
              ? (isDark ? _darkPrimaryColor : _lightPrimaryColor)
              : (isDark ? _darkOnSurfaceVariantColor : _lightOnSurfaceVariantColor);
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

  // M3E Colors - Light
  static const Color _m3eLightPrimary = Color(0xFF6750A4);
  static const Color _m3eLightOnPrimary = Color(0xFFFFFFFF);
  static const Color _m3eLightPrimaryContainer = Color(0xFFEADDFF);
  static const Color _m3eLightOnPrimaryContainer = Color(0xFF21005D);
  static const Color _m3eLightSecondary = Color(0xFF625B71);
  static const Color _m3eLightOnSecondary = Color(0xFFFFFFFF);
  static const Color _m3eLightSecondaryContainer = Color(0xFFE8DEF8);
  static const Color _m3eLightOnSecondaryContainer = Color(0xFF1D192B);
  static const Color _m3eLightTertiary = Color(0xFF7D5260);
  static const Color _m3eLightOnTertiary = Color(0xFFFFFFFF);
  static const Color _m3eLightTertiaryContainer = Color(0xFFFFD8E4);
  static const Color _m3eLightOnTertiaryContainer = Color(0xFF31111D);
  static const Color _m3eLightError = Color(0xFFB3261E);
  static const Color _m3eLightOnError = Color(0xFFFFFFFF);
  static const Color _m3eLightErrorContainer = Color(0xFFF9DEDC);
  static const Color _m3eLightOnErrorContainer = Color(0xFF410E0B);
  static const Color _m3eLightSurface = Color(0xFFFEF7FF);
  static const Color _m3eLightOnSurface = Color(0xFF1D1B20);
  static const Color _m3eLightSurfaceDim = Color(0xFFDED8E1);
  static const Color _m3eLightSurfaceBright = Color(0xFFFEF7FF);
  static const Color _m3eLightSurfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color _m3eLightSurfaceContainerLow = Color(0xFFF7F2FA);
  static const Color _m3eLightSurfaceContainer = Color(0xFFF3EDF7);
  static const Color _m3eLightSurfaceContainerHigh = Color(0xFFECE6F0);
  static const Color _m3eLightSurfaceContainerHighest = Color(0xFFE6E0E9);
  static const Color _m3eLightOnSurfaceVariant = Color(0xFF49454F);
  static const Color _m3eLightOutline = Color(0xFF79747E);
  static const Color _m3eLightOutlineVariant = Color(0xFFCAC4D0);
  static const Color _m3eLightInverseSurface = Color(0xFF322F35);
  static const Color _m3eLightInverseOnSurface = Color(0xFFF5EFF7);
  static const Color _m3eLightInversePrimary = Color(0xFFD0BCFF);
  static const Color _m3eLightShadow = Color(0xFF000000);
  static const Color _m3eLightScrim = Color(0xFF000000);
  static const Color _m3eLightSurfaceTint = Color(0xFF6750A4);

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
    outline: _m3eLightOutline,
    outlineVariant: _m3eLightOutlineVariant,
  );

  // M3E Colors - Dark
  static const Color _m3eDarkPrimary = Color(0xFFD0BCFF);
  static const Color _m3eDarkOnPrimary = Color(0xFF381E72);
  static const Color _m3eDarkPrimaryContainer = Color(0xFF4F378B);
  static const Color _m3eDarkOnPrimaryContainer = Color(0xFFEADDFF);
  static const Color _m3eDarkSecondary = Color(0xFFCCC2DC);
  static const Color _m3eDarkOnSecondary = Color(0xFF332D41);
  static const Color _m3eDarkSecondaryContainer = Color(0xFF4A4458);
  static const Color _m3eDarkOnSecondaryContainer = Color(0xFFE8DEF8);
  static const Color _m3eDarkTertiary = Color(0xFFEFB8C8);
  static const Color _m3eDarkOnTertiary = Color(0xFF492532);
  static const Color _m3eDarkTertiaryContainer = Color(0xFF633B48);
  static const Color _m3eDarkOnTertiaryContainer = Color(0xFFFFD8E4);
  static const Color _m3eDarkError = Color(0xFFF2B8B5);
  static const Color _m3eDarkOnError = Color(0xFF601410);
  static const Color _m3eDarkErrorContainer = Color(0xFF8C1D18);
  static const Color _m3eDarkOnErrorContainer = Color(0xFFF9DEDC);
  static const Color _m3eDarkSurface = Color(0xFF141218);
  static const Color _m3eDarkOnSurface = Color(0xFFE6E1E5);
  static const Color _m3eDarkSurfaceDim = Color(0xFF141218);
  static const Color _m3eDarkSurfaceBright = Color(0xFF3B383E);
  static const Color _m3eDarkSurfaceContainerLowest = Color(0xFF0F0D13);
  static const Color _m3eDarkSurfaceContainerLow = Color(0xFF1D1B20);
  static const Color _m3eDarkSurfaceContainer = Color(0xFF211F26);
  static const Color _m3eDarkSurfaceContainerHigh = Color(0xFF2B2930);
  static const Color _m3eDarkSurfaceContainerHighest = Color(0xFF36343B);
  static const Color _m3eDarkOnSurfaceVariant = Color(0xFFCAC4D0);
  static const Color _m3eDarkOutline = Color(0xFF938F99);
  static const Color _m3eDarkOutlineVariant = Color(0xFF49454F);
  static const Color _m3eDarkInverseSurface = Color(0xFFE6E1E5);
  static const Color _m3eDarkInverseOnSurface = Color(0xFF313033);
  static const Color _m3eDarkInversePrimary = Color(0xFF6750A4);
  static const Color _m3eDarkShadow = Color(0xFF000000);
  static const Color _m3eDarkScrim = Color(0xFF000000);
  static const Color _m3eDarkSurfaceTint = Color(0xFFD0BCFF);

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
    outline: _m3eDarkOutline,
    outlineVariant: _m3eDarkOutlineVariant,
  );

  // Standard Colors
  static const Color _lightPrimaryColor = Color(0xFF1C6758);
  static const Color _lightSecondaryColor = Color(0xFF3D8361);
  static const Color _lightTertiaryColor = Color(0xFFD6CDA4);
  static const Color _lightBackgroundColor = Color(0xFFEEF2E6);
  static const Color _lightSurfaceColor = Color(0xFFFFFFFF);
  static const Color _lightOnSurfaceColor = Color(0xFF000000);
  static const Color _lightOnSurfaceVariantColor = Color(0xFF44474E);
  static const Color _lightErrorColor = Color(0xFFBA1A1A);

  static const Color _darkPrimaryColor = Color(0xFF5ED4BB);
  static const Color _darkSecondaryColor = Color(0xFF81C784);
  static const Color _darkTertiaryColor = Color(0xFFE6EE9C);
  static const Color _darkBackgroundColor = Color(0xFF080A0E);
  static const Color _darkSurfaceColor = Color(0xFF111418);
  static const Color _darkOnSurfaceColor = Color(0xFFE2E2E6);
  static const Color _darkOnSurfaceVariantColor = Color(0xFFC4C6D0);
  static const Color _darkSurfaceVariant = Color(0xFF1D2125);
  static const Color _darkErrorColor = Color(0xFFFFB4AB);

  static const double m3eShapeExtraSmall = 4.0;
  static const double m3eShapeSmall = 8.0;
  static const double m3eShapeMedium = 12.0;
  static const double m3eShapeLarge = 16.0;
  static const double m3eShapeExtraLarge = 28.0;

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
}
