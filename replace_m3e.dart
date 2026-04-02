import 'dart:io';

void main() {
  final file = File('lib/themes/app_theme.dart');
  String content = file.readAsStringSync();

  // Replace M3E Colors
  content = content.replaceFirst(
    RegExp(
      r'// M3E Light Colors \(Vibrant & High Contrast\).*?const Color _m3eLightSecondaryContainer = Color\(0xFFE8DEF8\);',
      dotAll: true,
    ),
    '''// M3E Shape Tokens
const double _m3eShapeExtraSmall = 4.0;
const double _m3eShapeSmall = 8.0;
const double _m3eShapeMedium = 12.0;
const double _m3eShapeLarge = 16.0;
const double _m3eShapeExtraLarge = 28.0;
const double _m3eShapeFull = 100.0;

// M3E Light Colors (Vibrant & High Contrast)
const Color _m3eLightPrimary = Color(0xFFFF6B4A);
const Color _m3eLightSecondary = Color(0xFFFF8B50);
const Color _m3eLightTertiary = Color(0xFF7C4DFF);
const Color _m3eLightSurfaceDim = Color(0xFFDED8E1);
const Color _m3eLightSurfaceBright = Color(0xFFFEF7FF);
const Color _m3eLightSurfaceContainerLowest = Color(0xFFFFFFFF);
const Color _m3eLightSurfaceContainerLow = Color(0xFFF7F2FA);
const Color _m3eLightSurfaceContainer = Color(0xFFF3EDF7);
const Color _m3eLightSurfaceContainerHigh = Color(0xFFECE6F0);
const Color _m3eLightSurfaceContainerHighest = Color(0xFFE6E0E9);
const Color _m3eLightPrimaryContainer = Color(0xFFFFDAD4);
const Color _m3eLightSecondaryContainer = Color(0xFFFFDBCF);
const Color _m3eLightTertiaryContainer = Color(0xFFEADDFF);
const Color _m3eLightErrorContainer = Color(0xFFFFDAD6);
const Color _m3eLightInverseSurface = Color(0xFF313033);
const Color _m3eLightInversePrimary = Color(0xFFFFB4A8);
const Color _m3eLightInverseOnSurface = Color(0xFFF4EFF4);
const Color _m3eLightOutline = Color(0xFF79747E);
const Color _m3eLightOutlineVariant = Color(0xFFCAC4D0);''',
  );

  content = content.replaceFirst(
    RegExp(
      r'// M3E Dark Colors.*?const Color _m3eDarkPrimaryContainer = Color\(0xFF4F378B\);',
      dotAll: true,
    ),
    '''// M3E Dark Colors
const Color _m3eDarkPrimary = Color(0xFFFFB4A8);
const Color _m3eDarkSecondary = Color(0xFFFFB884);
const Color _m3eDarkTertiary = Color(0xFFD0BCFF);
const Color _m3eDarkSurfaceDim = Color(0xFF141218);
const Color _m3eDarkSurfaceBright = Color(0xFF3B383E);
const Color _m3eDarkSurfaceContainerLowest = Color(0xFF0F0D13);
const Color _m3eDarkSurfaceContainerLow = Color(0xFF1D1B20);
const Color _m3eDarkSurfaceContainer = Color(0xFF211F26);
const Color _m3eDarkSurfaceContainerHigh = Color(0xFF2B2930);
const Color _m3eDarkSurfaceContainerHighest = Color(0xFF36343B);
const Color _m3eDarkPrimaryContainer = Color(0xFF733423);
const Color _m3eDarkSecondaryContainer = Color(0xFF753816);
const Color _m3eDarkTertiaryContainer = Color(0xFF4F378B);
const Color _m3eDarkErrorContainer = Color(0xFF93000A);
const Color _m3eDarkInverseSurface = Color(0xFFE6E0E9);
const Color _m3eDarkInversePrimary = Color(0xFFFF6B4A);
const Color _m3eDarkInverseOnSurface = Color(0xFF313033);
const Color _m3eDarkOutline = Color(0xFF938F99);
const Color _m3eDarkOutlineVariant = Color(0xFF49454F);''',
  );

  content = content.replaceFirst(
    RegExp(
      r'// M3E Text Theme \(Emphasized\).*?    labelSmall: GoogleFonts\.comfortaa\([\s\S]*?height: 1\.45,\n    \),\n  \);',
      dotAll: true,
    ),
    '''// M3E Text Theme (Emphasized)
  static TextTheme m3eTextTheme(Color color) => TextTheme(
    displayLarge: GoogleFonts.robotoFlex(
      fontSize: 57,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.25,
      color: color,
    ),
    displayMedium: GoogleFonts.robotoFlex(
      fontSize: 45,
      fontWeight: FontWeight.w400,
      color: color,
    ),
    displaySmall: GoogleFonts.robotoFlex(
      fontSize: 36,
      fontWeight: FontWeight.w400,
      color: color,
    ),
    headlineLarge: GoogleFonts.robotoFlex(
      fontSize: 32,
      fontWeight: FontWeight.w600,
      color: color,
    ),
    headlineMedium: GoogleFonts.robotoFlex(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      color: color,
    ),
    headlineSmall: GoogleFonts.robotoFlex(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: color,
    ),
    titleLarge: GoogleFonts.robotoFlex(
      fontSize: 22,
      fontWeight: FontWeight.w500,
      color: color,
    ),
    titleMedium: GoogleFonts.robotoFlex(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: color,
    ),
    titleSmall: GoogleFonts.robotoFlex(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: color,
    ),
    bodyLarge: GoogleFonts.robotoFlex(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: color.withValues(alpha: 0.8),
    ),
    bodyMedium: GoogleFonts.robotoFlex(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: color.withValues(alpha: 0.8),
    ),
    bodySmall: GoogleFonts.robotoFlex(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: color.withValues(alpha: 0.6),
    ),
    labelLarge: GoogleFonts.robotoFlex(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: color,
    ),
    labelMedium: GoogleFonts.robotoFlex(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: color,
    ),
    labelSmall: GoogleFonts.robotoFlex(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: color,
    ),
  );''',
  );

  content = content.replaceFirst(
    RegExp(
      r'// M3E Button Style \(Iconic Shapes\).*?        \),\n      \);',
      dotAll: true,
    ),
    '''// M3E Button Style (Iconic Shapes)
  static ButtonStyle m3eButtonStyle(Color bg, Color fg) =>
      ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_m3eShapeFull)),
        textStyle: GoogleFonts.robotoFlex(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
      );''',
  );

  content = content.replaceFirst(
    RegExp(
      r'// M3E Card Theme \(High Contrast\).*?        color: surface,\n      \);',
      dotAll: true,
    ),
    '''// M3E Card Theme (High Contrast)
  static CardThemeData m3eCardTheme(Color surface, Color outline) =>
      CardThemeData(
        elevation: 1,
        shadowColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_m3eShapeExtraLarge),
          side: BorderSide(color: outline, width: 1.0),
        ),
        color: surface,
      );''',
  );

  content = content.replaceFirst(
    RegExp(
      r'// M3E Light Theme\n  static final ThemeData m3eLightTheme = ThemeData\([\s\S]*?// M3E Dark Theme\n  static final ThemeData m3eDarkTheme = ThemeData\([\s\S]*?    \),\n  \);',
      dotAll: true,
    ),
    '''// M3E Light Theme
  static final ThemeData m3eLightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: _m3eLightPrimary,
      onPrimary: Colors.white,
      primaryContainer: _m3eLightPrimaryContainer,
      onPrimaryContainer: _m3eLightPrimary,
      secondary: _m3eLightSecondary,
      onSecondary: Colors.white,
      secondaryContainer: _m3eLightSecondaryContainer,
      onSecondaryContainer: _m3eLightSecondary,
      tertiary: _m3eLightTertiary,
      onTertiary: Colors.white,
      tertiaryContainer: _m3eLightTertiaryContainer,
      onTertiaryContainer: _m3eLightTertiary,
      surface: _m3eLightSurfaceContainerLowest,
      surfaceDim: _m3eLightSurfaceDim,
      surfaceBright: _m3eLightSurfaceBright,
      surfaceContainerLowest: _m3eLightSurfaceContainerLowest,
      surfaceContainerLow: _m3eLightSurfaceContainerLow,
      surfaceContainer: _m3eLightSurfaceContainer,
      surfaceContainerHigh: _m3eLightSurfaceContainerHigh,
      surfaceContainerHighest: _m3eLightSurfaceContainerHighest,
      onSurface: Colors.black,
      errorContainer: _m3eLightErrorContainer,
      inverseSurface: _m3eLightInverseSurface,
      inversePrimary: _m3eLightInversePrimary,
      onInverseSurface: _m3eLightInverseOnSurface,
      outline: _m3eLightOutline,
      outlineVariant: _m3eLightOutlineVariant,
    ),
    scaffoldBackgroundColor: _m3eLightSurfaceContainerLowest,
    textTheme: m3eTextTheme(Colors.black),
    appBarTheme: AppBarTheme(
      backgroundColor: _m3eLightSurfaceContainer,
      foregroundColor: Colors.black,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: m3eTextTheme(Colors.black).titleLarge,
    ),
    cardTheme: m3eCardTheme(
      _m3eLightSurfaceContainerLow,
      _m3eLightOutlineVariant,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: m3eButtonStyle(_m3eLightPrimary, Colors.white),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _m3eLightPrimary,
        side: const BorderSide(color: _m3eLightPrimary, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_m3eShapeFull)),
        textStyle: GoogleFonts.robotoFlex(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _m3eLightPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_m3eShapeFull)),
        textStyle: GoogleFonts.robotoFlex(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _m3eLightPrimaryContainer,
      foregroundColor: _m3eLightPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(_m3eShapeLarge))),
      elevation: 3,
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_m3eShapeMedium)),
      backgroundColor: _m3eLightSurfaceContainerHigh,
      selectedColor: _m3eLightSecondaryContainer,
      labelStyle: GoogleFonts.robotoFlex(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: _m3eLightSurfaceContainerHigh,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_m3eShapeExtraLarge)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: _m3eLightSurfaceContainerLow,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(_m3eShapeExtraLarge)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _m3eLightSurfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_m3eShapeLarge),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_m3eShapeLarge),
        borderSide: const BorderSide(color: _m3eLightPrimary, width: 2),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: _m3eLightSurfaceContainer,
      indicatorColor: _m3eLightSecondaryContainer,
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_m3eShapeFull)),
      elevation: 0,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _m3eLightInverseSurface,
      contentTextStyle: GoogleFonts.robotoFlex(color: _m3eLightInverseOnSurface),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_m3eShapeMedium)),
      behavior: SnackBarBehavior.floating,
    ),
    dividerTheme: const DividerThemeData(
      color: _m3eLightOutlineVariant,
      thickness: 1,
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? _m3eLightPrimary : _m3eLightSurfaceContainerHighest),
      thumbColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? Colors.white : _m3eLightOutline),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? _m3eLightPrimary : Colors.transparent),
      checkColor: WidgetStateProperty.all(Colors.white),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? _m3eLightPrimary : _m3eLightOutline),
    ),
  );

  // M3E Dark Theme
  static final ThemeData m3eDarkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: _m3eDarkPrimary,
      onPrimary: _m3eDarkPrimaryContainer,
      primaryContainer: _m3eDarkPrimaryContainer,
      onPrimaryContainer: _m3eDarkPrimary,
      secondary: _m3eDarkSecondary,
      onSecondary: _m3eDarkSecondaryContainer,
      secondaryContainer: _m3eDarkSecondaryContainer,
      onSecondaryContainer: _m3eDarkSecondary,
      tertiary: _m3eDarkTertiary,
      onTertiary: _m3eDarkTertiaryContainer,
      tertiaryContainer: _m3eDarkTertiaryContainer,
      onTertiaryContainer: _m3eDarkTertiary,
      surface: _m3eDarkSurfaceContainerLowest,
      surfaceDim: _m3eDarkSurfaceDim,
      surfaceBright: _m3eDarkSurfaceBright,
      surfaceContainerLowest: _m3eDarkSurfaceContainerLowest,
      surfaceContainerLow: _m3eDarkSurfaceContainerLow,
      surfaceContainer: _m3eDarkSurfaceContainer,
      surfaceContainerHigh: _m3eDarkSurfaceContainerHigh,
      surfaceContainerHighest: _m3eDarkSurfaceContainerHighest,
      onSurface: Colors.white,
      errorContainer: _m3eDarkErrorContainer,
      inverseSurface: _m3eDarkInverseSurface,
      inversePrimary: _m3eDarkInversePrimary,
      onInverseSurface: _m3eDarkInverseOnSurface,
      outline: _m3eDarkOutline,
      outlineVariant: _m3eDarkOutlineVariant,
    ),
    scaffoldBackgroundColor: _m3eDarkSurfaceContainerLowest,
    textTheme: m3eTextTheme(Colors.white),
    appBarTheme: AppBarTheme(
      backgroundColor: _m3eDarkSurfaceContainer,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: m3eTextTheme(Colors.white).titleLarge,
    ),
    cardTheme: m3eCardTheme(
      _m3eDarkSurfaceContainerLow,
      _m3eDarkOutlineVariant,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: m3eButtonStyle(_m3eDarkPrimary, _m3eDarkPrimaryContainer),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _m3eDarkPrimary,
        side: const BorderSide(color: _m3eDarkPrimary, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_m3eShapeFull)),
        textStyle: GoogleFonts.robotoFlex(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _m3eDarkPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_m3eShapeFull)),
        textStyle: GoogleFonts.robotoFlex(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _m3eDarkPrimaryContainer,
      foregroundColor: _m3eDarkPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(_m3eShapeLarge))),
      elevation: 3,
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_m3eShapeMedium)),
      backgroundColor: _m3eDarkSurfaceContainerHigh,
      selectedColor: _m3eDarkSecondaryContainer,
      labelStyle: GoogleFonts.robotoFlex(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: _m3eDarkSurfaceContainerHigh,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_m3eShapeExtraLarge)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: _m3eDarkSurfaceContainerLow,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(_m3eShapeExtraLarge)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _m3eDarkSurfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_m3eShapeLarge),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_m3eShapeLarge),
        borderSide: const BorderSide(color: _m3eDarkPrimary, width: 2),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: _m3eDarkSurfaceContainer,
      indicatorColor: _m3eDarkSecondaryContainer,
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_m3eShapeFull)),
      elevation: 0,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _m3eDarkInverseSurface,
      contentTextStyle: GoogleFonts.robotoFlex(color: _m3eDarkInverseOnSurface),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_m3eShapeMedium)),
      behavior: SnackBarBehavior.floating,
    ),
    dividerTheme: const DividerThemeData(
      color: _m3eDarkOutlineVariant,
      thickness: 1,
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? _m3eDarkPrimary : _m3eDarkSurfaceContainerHighest),
      thumbColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? _m3eDarkPrimaryContainer : _m3eDarkOutline),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? _m3eDarkPrimary : Colors.transparent),
      checkColor: WidgetStateProperty.all(_m3eDarkPrimaryContainer),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? _m3eDarkPrimary : _m3eDarkOutline),
    ),
  );''',
  );

  file.writeAsStringSync(content);
}
