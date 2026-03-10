import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

// Light Theme Colors
const Color _lightPrimaryColor = Color(0xFF1152D4);
const Color _lightBackgroundColor = Color(0xFFFFFFFF);
const Color _lightSurfaceColor = Color(0xFFF5F5F5);
const Color _lightOnSurfaceColor = Color(0xFF111111);
const Color _lightOnSurfaceVariantColor = Color(0xFF666666);
const Color _lightErrorColor = Color(0xFFD32F2F);

// Dark Theme Colors - Premium Dark Theme
const Color _darkPrimaryColor = Color(
  0xFF6B9EFF,
); // Brighter blue for better contrast
const Color _darkBackgroundColor = Color(0xFF0C0F14); // Main background
const Color _darkSurfaceColor = Color(0xFF1A1D24); // Elevated surfaces
const Color _darkSurfaceVariant = Color(0xFF252930); // Cards and containers
const Color _darkOnSurfaceColor = Color(0xFFE8EAED); // Primary text
const Color _darkOnSurfaceVariantColor = Color(0xFF9AA0A6); // Secondary text
const Color _darkErrorColor = Color(0xFFFF6B6B);

// Semantic Colors - Used across both themes
class SemanticColors {
  // Success colors
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFF81C784);
  static const Color successDark = Color(0xFF388E3C);
  static const Color onSuccess = Colors.white;

  // Warning colors
  static const Color warning = Color(0xFFFF9800);
  static const Color warningLight = Color(0xFFFFB74D);
  static const Color warningDark = Color(0xFFF57C00);
  static const Color onWarning = Colors.black;

  // Info colors
  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFF64B5F6);
  static const Color infoDark = Color(0xFF1976D2);
  static const Color onInfo = Colors.white;
}

class AppTheme {
  // Make constructor private to prevent instantiation
  AppTheme._();

  // Theme getters
  static ThemeData get light => lightTheme;
  static ThemeData get dark => darkTheme;

  // Helper method to get theme based on brightness
  static ThemeData getTheme(Brightness brightness) {
    return brightness == Brightness.dark ? darkTheme : lightTheme;
  }

  // Text Styles
  static const String fontFamily = 'Comfortaa';

  // Text Theme
  static TextTheme textTheme = TextTheme(
    displayLarge: GoogleFonts.comfortaa(
      fontSize: 57,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.25,
      color: _lightOnSurfaceColor,
      height: 1.12,
    ),
    displayMedium: GoogleFonts.comfortaa(
      fontSize: 45,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: _lightOnSurfaceColor,
      height: 1.15,
    ),
    displaySmall: GoogleFonts.comfortaa(
      fontSize: 36,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: _lightOnSurfaceColor,
      height: 1.22,
    ),
    headlineLarge: GoogleFonts.comfortaa(
      fontSize: 32,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: _lightOnSurfaceColor,
      height: 1.25,
    ),
    headlineMedium: GoogleFonts.comfortaa(
      fontSize: 28,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: _lightOnSurfaceColor,
      height: 1.28,
    ),
    headlineSmall: GoogleFonts.comfortaa(
      fontSize: 24,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: _lightOnSurfaceColor,
      height: 1.33,
    ),
    titleLarge: GoogleFonts.comfortaa(
      fontSize: 22,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: _lightOnSurfaceColor,
      height: 1.27,
    ),
    titleMedium: GoogleFonts.comfortaa(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
      color: _lightOnSurfaceColor,
      height: 1.5,
    ),
    titleSmall: GoogleFonts.comfortaa(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      color: _lightOnSurfaceColor,
      height: 1.42,
    ),
    bodyLarge: GoogleFonts.comfortaa(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
      color: _lightOnSurfaceVariantColor,
      height: 1.5,
    ),
    bodyMedium: GoogleFonts.comfortaa(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      color: _lightOnSurfaceVariantColor,
      height: 1.42,
    ),
    bodySmall: GoogleFonts.comfortaa(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      color: _lightOnSurfaceVariantColor,
      height: 1.33,
    ),
    labelLarge: GoogleFonts.comfortaa(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      color: _lightOnSurfaceVariantColor,
      height: 1.42,
    ),
    labelMedium: GoogleFonts.comfortaa(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      color: _lightOnSurfaceVariantColor,
      height: 1.33,
    ),
    labelSmall: GoogleFonts.comfortaa(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      color: _lightOnSurfaceVariantColor,
      height: 1.45,
    ),
  );

  // Button Styles
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

  // Input Decoration
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

  // Card Theme
  static CardThemeData get cardTheme => CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: _lightSurfaceColor),
    ),
    color: _lightSurfaceColor,
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
  static NavigationBarThemeData
  get navigationBarTheme => NavigationBarThemeData(
    indicatorColor: _lightPrimaryColor.withValues(alpha: 0.12),
    // Glass effect will be handled by container in router if needed, but theme supports transparency
    backgroundColor: Colors.transparent, // transparent for glass effect
    indicatorShape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ), // Reduce width visually via shape? Or just styling.

    // Note: indicatorShape is property of NavigationBarThemeData? No, it's specific to M3.
    // Standard NavigationBar theme has indicatorShape.
    labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
      if (states.contains(WidgetState.selected)) {
        return textTheme.labelSmall!.copyWith(color: _lightPrimaryColor);
      }
      return textTheme.labelSmall!.copyWith(color: _lightOnSurfaceVariantColor);
    }),
  );

  // Tab Bar Theme
  static TabBarThemeData get tabBarTheme => TabBarThemeData(
    labelColor: _lightPrimaryColor,
    unselectedLabelColor: _lightOnSurfaceVariantColor,
    indicator: UnderlineTabIndicator(
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
  static BottomSheetThemeData get bottomSheetTheme => BottomSheetThemeData(
    backgroundColor: _lightSurfaceColor,
    elevation: 0,
    shape: const RoundedRectangleBorder(
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

  // Theme Data
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: _lightPrimaryColor,
      secondary: _lightPrimaryColor,
      tertiary: _lightPrimaryColor,
      surface: _lightSurfaceColor,
      // background: _lightBackgroundColor, // Deprecated
      error: _lightErrorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: _lightOnSurfaceColor,
      // onBackground: _lightOnSurfaceColor, // Deprecated
      onError: Colors.white,
    ),
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

  // Dark Theme
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: _darkPrimaryColor,
      secondary: _darkPrimaryColor,
      tertiary: _darkPrimaryColor,
      surface: _darkSurfaceColor,
      // background: _darkBackgroundColor, // Deprecated
      error: _darkErrorColor,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: _darkOnSurfaceColor,
      // onBackground: _darkOnSurfaceColor, // Deprecated
      onError: Colors.white,
    ),
    scaffoldBackgroundColor:
        Colors.transparent, // Transparent to show MeshGradientBackground
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
      backgroundColor: Colors.black.withValues(alpha: 0.2), // Tinted glass
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
        borderSide: BorderSide(color: _darkPrimaryColor, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _darkPrimaryColor,
        foregroundColor: _darkBackgroundColor,
        elevation: 0,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: _darkPrimaryColor),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _darkPrimaryColor,
        side: BorderSide(color: _darkPrimaryColor),
      ),
    ),
    navigationBarTheme: navigationBarTheme.copyWith(
      backgroundColor: Colors.transparent, // Transparent for glass
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
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: _darkPrimaryColor, width: 2),
      ),
    ),
  );

  // Text Styles
}
