import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:oasis/themes/app_colors.dart';

class AppFluentTheme {
  static FluentThemeData getTheme(
    material.Brightness brightness, {
    material.ColorScheme? materialColorScheme,
    String? fontFamily,
    bool micaEnabled = false,
  }) {
    final isDark = brightness == material.Brightness.dark;
    
    // Core colors synchronized with Material 3 / Oasis Palette
    final primaryColor = materialColorScheme?.primary ?? 
        (isDark ? DarkColors.primary : LightColors.primary);
    
    final scaffoldColor = materialColorScheme?.surface ?? 
        (isDark ? DarkColors.background : LightColors.background);

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
      scaffoldBackgroundColor: micaEnabled ? Colors.transparent : scaffoldColor,
      micaBackgroundColor: micaEnabled ? Colors.transparent : scaffoldColor,
      
      // Typography synchronized with AppTextStyles
      typography: Typography.fromBrightness(
        brightness: isDark ? Brightness.dark : Brightness.light,
        color: isDark ? DarkColors.onBackground : LightColors.onBackground,
      ).apply(fontFamily: fontFamily),

      navigationPaneTheme: NavigationPaneThemeData(
        backgroundColor: micaEnabled 
            ? (isDark ? DarkColors.surface.withValues(alpha: 0.7) : LightColors.surface.withValues(alpha: 0.7))
            : (isDark ? DarkColors.surface : LightColors.surface),
        highlightColor: primaryColor,
        selectedIconColor: WidgetStateProperty.all(primaryColor),
        selectedTextStyle: WidgetStateProperty.all(TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.bold,
        )),
        unselectedIconColor: WidgetStateProperty.all(
          isDark ? DarkColors.hint : LightColors.hint,
        ),
      ),

      checkboxTheme: CheckboxThemeData(
        checkedIconColor: WidgetStateProperty.all(material.Colors.white),
      ),

      buttonTheme: ButtonThemeData(
        filledButtonStyle: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(primaryColor),
          foregroundColor: WidgetStateProperty.all(material.Colors.white),
        ),
      ),
      
      dividerTheme: const DividerThemeData(
        thickness: 1,
      ),
    );
  }
}
