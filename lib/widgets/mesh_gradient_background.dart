import 'dart:math';
import 'package:flutter/material.dart';

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
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If animation is disabled, just show a static gradient or the child directly
    if (!widget.animate) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: widget.child,
      );
    }

    return Stack(
      children: [
        // Background base color
        Container(color: const Color(0xFF0F0F1A)),

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
        // Using a highly blurred BackdropFilter to create the "mesh" effect
        // Note: BackdropFilter applies to everything underneath it within a Stack
        // Use with caution on low-end devices for performance.
        // Overlay gradient for depth
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black.withOpacity(0.2),
                Colors.transparent,
                Colors.black.withOpacity(0.4),
              ],
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
        Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);

    // Deep Blue Orb 1
    // Moves in a figure-8 or simpler Lissajous curve
    final x1 = size.width * 0.2 + sin(animationValue * 2 * pi) * 100;
    final y1 = size.height * 0.3 + cos(animationValue * 2 * pi) * 50;
    paint.color = const Color(
      0xFF2A52BE,
    ).withOpacity(0.6); // Deep ocean blue
    canvas.drawCircle(Offset(x1, y1), 200, paint);

    // Cyan Orb 2
    final x2 = size.width * 0.8 - cos(animationValue * 2 * pi) * 120;
    final y2 = size.height * 0.7 - sin(animationValue * 2 * pi) * 80;
    paint.color = const Color(0xFF00E5FF).withOpacity(0.5); // Bright cyan
    canvas.drawCircle(Offset(x2, y2), 250, paint);

    // Cornflower Blue Orb 3
    final x3 = size.width * 0.5 + sin(animationValue * 2 * pi + 1) * 80;
    final y3 = size.height * 0.5 + cos(animationValue * 2 * pi + 1) * 100;
    paint.color = const Color(0xFF6B9EFF).withOpacity(0.4); // Primary dark blue
    canvas.drawCircle(Offset(x3, y3), 180, paint);
  }

  @override
  bool shouldRepaint(covariant MeshPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
