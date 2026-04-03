import 'package:flutter/material.dart';

class ColorUtils {
  /// Get adaptive text color based on background color
  /// Returns white for dark backgrounds, black for light backgrounds
  static Color getAdaptiveTextColor(Color backgroundColor) {
    return isLightBackground(backgroundColor) ? Colors.black : Colors.white;
  }

  /// Get adaptive bubble color based on background
  /// Adjusts opacity and color to ensure visibility
  static Color getAdaptiveBubbleColor(
    Color backgroundColor,
    bool isMe,
    ColorScheme colorScheme,
  ) {
    final isLight = isLightBackground(backgroundColor);

    if (isMe) {
      // Sender bubble
      if (isLight) {
        return colorScheme.primary.withValues(alpha: 0.9);
      } else {
        return colorScheme.primary.withValues(alpha: 0.8);
      }
    } else {
      // Receiver bubble
      if (isLight) {
        return colorScheme.surfaceContainerHighest.withValues(alpha: 0.9);
      } else {
        return colorScheme.surfaceContainerHighest.withValues(alpha: 0.7);
      }
    }
  }

  /// Check if background is light
  static bool isLightBackground(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5;
  }

  /// Get contrast ratio between two colors
  static double getContrastRatio(Color color1, Color color2) {
    final lum1 = color1.computeLuminance();
    final lum2 = color2.computeLuminance();

    final lighter = lum1 > lum2 ? lum1 : lum2;
    final darker = lum1 > lum2 ? lum2 : lum1;

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Ensure minimum contrast ratio (WCAG AA standard is 4.5:1)
  static Color ensureContrast(
    Color foreground,
    Color background, {
    double minRatio = 4.5,
  }) {
    final ratio = getContrastRatio(foreground, background);

    if (ratio >= minRatio) {
      return foreground;
    }

    // If contrast is too low, return black or white based on background
    return isLightBackground(background) ? Colors.black : Colors.white;
  }

  /// Darken a color by a percentage
  static Color darken(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));

    return hslDark.toColor();
  }

  /// Lighten a color by a percentage
  static Color lighten(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness(
      (hsl.lightness + amount).clamp(0.0, 1.0),
    );

    return hslLight.toColor();
  }

  /// Get a color with adjusted opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity.clamp(0.0, 1.0));
  }

  /// Convert hex string to Color
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Convert Color to hex string
  static String toHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  /// Get complementary color
  static Color getComplementary(Color color) {
    final hsl = HSLColor.fromColor(color);
    final complementaryHue = (hsl.hue + 180) % 360;
    return hsl.withHue(complementaryHue).toColor();
  }

  /// Get analogous colors
  static List<Color> getAnalogous(Color color, {int count = 2}) {
    final hsl = HSLColor.fromColor(color);
    final colors = <Color>[];

    for (int i = 1; i <= count; i++) {
      final hue = (hsl.hue + (30 * i)) % 360;
      colors.add(hsl.withHue(hue).toColor());
    }

    return colors;
  }

  /// Get triadic colors
  static List<Color> getTriadic(Color color) {
    final hsl = HSLColor.fromColor(color);
    return [
      hsl.withHue((hsl.hue + 120) % 360).toColor(),
      hsl.withHue((hsl.hue + 240) % 360).toColor(),
    ];
  }

  /// Blend two colors
  static Color blend(Color color1, Color color2, double ratio) {
    assert(ratio >= 0 && ratio <= 1);

    final r = (color1.r * 255 * (1 - ratio) + color2.r * 255 * ratio).round();
    final g = (color1.g * 255 * (1 - ratio) + color2.g * 255 * ratio).round();
    final b = (color1.b * 255 * (1 - ratio) + color2.b * 255 * ratio).round();
    final a = (color1.a * 255 * (1 - ratio) + color2.a * 255 * ratio).round();

    return Color.fromARGB(a, r, g, b);
  }
}
