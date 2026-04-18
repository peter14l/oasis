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
  final double animationValue;

  MeshPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);

    // Oasis Glow Orb 1
    final x1 = size.width * 0.3 + sin(animationValue * 2 * pi) * 150;
    final y1 = size.height * 0.4 + cos(animationValue * 2 * pi) * 100;
    paint.color = OasisColors.glow.withValues(alpha: 0.25);
    canvas.drawCircle(Offset(x1, y1), 350, paint);

    // Oasis Moss Orb 2
    final x2 = size.width * 0.7 - cos(animationValue * 2 * pi) * 180;
    final y2 = size.height * 0.6 - sin(animationValue * 2 * pi) * 120;
    paint.color = OasisColors.moss.withValues(alpha: 0.35);
    canvas.drawCircle(Offset(x2, y2), 450, paint);

    // Oasis Sage Orb 3
    final x3 = size.width * 0.5 + sin(animationValue * 2 * pi + 1) * 120;
    final y3 = size.height * 0.2 + cos(animationValue * 2 * pi + 1) * 150;
    paint.color = OasisColors.sage.withValues(alpha: 0.3);
    canvas.drawCircle(Offset(x3, y3), 300, paint);

    // Oasis Glow Orb 4 (Halo effect)
    final x4 = size.width * 0.8 + cos(animationValue * 2 * pi + 2) * 100;
    final y4 = size.height * 0.8 + sin(animationValue * 2 * pi + 2) * 130;
    paint.color = OasisColors.glow.withValues(alpha: 0.15);
    canvas.drawCircle(Offset(x4, y4), 250, paint);
  }

  @override
  bool shouldRepaint(covariant MeshPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
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
