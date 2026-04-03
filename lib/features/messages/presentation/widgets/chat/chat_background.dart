import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Chat background image with opacity and brightness control.
/// Extracted from the Positioned.fill background in chat_screen.dart.
class ChatBackground extends StatelessWidget {
  const ChatBackground({
    super.key,
    this.backgroundUrl,
    this.bgOpacity = 1.0,
    this.bgBrightness = 0.7,
  });

  final String? backgroundUrl;
  final double bgOpacity;
  final double bgBrightness;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned.fill(
      child: Stack(
        children: [
          // Base background color
          Container(color: colorScheme.background),
          // Background image overlay
          if (backgroundUrl != null)
            Positioned.fill(
              child: Opacity(
                opacity: bgOpacity,
                child: CachedNetworkImage(
                  imageUrl: backgroundUrl!,
                  fit: BoxFit.cover,
                  color: Colors.black.withValues(
                    alpha: (1 - bgBrightness).clamp(0.0, 1.0),
                  ),
                  colorBlendMode: BlendMode.darken,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
