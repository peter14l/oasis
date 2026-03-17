import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oasis_v2/services/screen_time_service.dart';

/// Wraps [child] in a [ColorFiltered] widget that gradually desaturates
/// to greyscale as the user approaches 30 minutes of continuous app usage.
///
/// Saturation transitions from full color at the 25-minute mark to
/// complete greyscale at the 30-minute mark, then stays in greyscale
/// until the user resets their session.
class GreyscaleWrapper extends StatelessWidget {
  final Widget child;

  const GreyscaleWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<ScreenTimeService>(
      builder: (context, svc, _) {
        final s = svc.saturationLevel; // 1.0 = full color, 0.0 = full B&W

        // When fully saturated (normal usage), skip the ColorFiltered overhead.
        if (s >= 1.0) return child;

        return ColorFiltered(
          colorFilter: ColorFilter.matrix([
            // Luminosity-preserving greyscale matrix interpolated by saturation s.
            // At s=1.0 → identity; at s=0.0 → standard greyscale.
            // R output
            0.2126 + 0.7874 * s, 0.7152 - 0.7152 * s, 0.0722 - 0.0722 * s, 0, 0,
            // G output
            0.2126 - 0.2126 * s, 0.7152 + 0.2848 * s, 0.0722 - 0.0722 * s, 0, 0,
            // B output
            0.2126 - 0.2126 * s, 0.7152 - 0.7152 * s, 0.0722 + 0.9278 * s, 0, 0,
            // Alpha (unchanged)
            0, 0, 0, 1, 0,
          ]),
          child: child,
        );
      },
    );
  }
}
