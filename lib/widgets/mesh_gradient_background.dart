import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:oasis/themes/app_colors.dart';

class MeshGradientBackground extends StatefulWidget {
  final Widget child;
  final bool animate;

  const MeshGradientBackground({
    super.key,
    required this.child,
    this.animate = true,
  });

  @override
  State<MeshGradientBackground> createState() => _MeshGradientBackgroundState();
}

class _MeshGradientBackgroundState extends State<MeshGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If animation is disabled, just show a static gradient
    if (!widget.animate) {
      return Container(
        decoration: const BoxDecoration(
          color: OasisColors.deep,
        ),
        child: widget.child,
      );
    }

    return Stack(
      children: [
        // Background base color
        Container(color: OasisColors.deep),

        // Animated Mesh Orbs
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: MeshPainter(_controller.value),
              size: Size.infinite,
            );
          },
        ),

        // Blur overlay to blend the orbs
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: Container(
              color: OasisColors.deep.withValues(alpha: 0.1),
            ),
          ),
        ),

        // Overlay gradient for depth
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.5,
              colors: [
                Colors.transparent,
                OasisColors.deep.withValues(alpha: 0.5),
                OasisColors.deep.withValues(alpha: 0.8),
              ],
            ),
          ),
        ),
        
        // Grain Texture (Procedural Noise)
        const Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: GrainPainter(),
              ),
            ),
          ),
        ),

        // Child content
        widget.child,
      ],
    );
  }
}

class MeshPainter extends CustomPainter {
  // ... rest of code unchanged
}

class GrainPainter extends CustomPainter {
  static Picture? _cachedPicture;
  static Size? _cachedSize;

  const GrainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (_cachedPicture != null && _cachedSize == size) {
      canvas.drawPicture(_cachedPicture!);
      return;
    }

    final recorder = PictureRecorder();
    final recordingCanvas = Canvas(recorder);
    final random = Random(42); // Deterministic seed for consistent grain
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.03);
    
    // Draw tiny dots randomly to simulate grain
    for (var i = 0; i < 5000; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      recordingCanvas.drawRect(Rect.fromLTWH(x, y, 1, 1), paint);
    }

    _cachedPicture = recorder.endRecording();
    _cachedSize = size;
    canvas.drawPicture(_cachedPicture!);
  }

  @override
  bool shouldRepaint(covariant GrainPainter oldDelegate) => false;
}
