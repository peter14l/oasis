import 'dart:math';
import 'dart:ui';
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
        Container(color: const Color(0xFF0C0F14)), // Deep Space Black

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
            filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
            child: Container(
              color: Colors.black.withValues(alpha: 0.1),
            ),
          ),
        ),

        // Overlay gradient for depth
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black.withValues(alpha: 0.2),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.4),
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
        Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);

    // Royal Blue Orb 1
    final x1 = size.width * 0.2 + sin(animationValue * 2 * pi) * 120;
    final y1 = size.height * 0.3 + cos(animationValue * 2 * pi) * 70;
    paint.color = const Color(0xFF2563EB).withValues(alpha: 0.5); // Royal Blue
    canvas.drawCircle(Offset(x1, y1), 220, paint);

    // Emerald Orb 2
    final x2 = size.width * 0.8 - cos(animationValue * 2 * pi) * 150;
    final y2 = size.height * 0.7 - sin(animationValue * 2 * pi) * 90;
    paint.color = const Color(0xFF10B981).withValues(alpha: 0.4); // Emerald
    canvas.drawCircle(Offset(x2, y2), 280, paint);

    // Amber Orb 3
    final x3 = size.width * 0.5 + sin(animationValue * 2 * pi + 1) * 100;
    final y3 = size.height * 0.5 + cos(animationValue * 2 * pi + 1) * 120;
    paint.color = const Color(0xFFF59E0B).withValues(alpha: 0.4); // Amber
    canvas.drawCircle(Offset(x3, y3), 200, paint);

    // Deep Blue Orb 4
    final x4 = size.width * 0.1 + cos(animationValue * 2 * pi + 2) * 80;
    final y4 = size.height * 0.8 + sin(animationValue * 2 * pi + 2) * 100;
    paint.color = const Color(0xFF1D4ED8).withValues(alpha: 0.3); // Deeper Royal Blue
    canvas.drawCircle(Offset(x4, y4), 150, paint);

    // Teal/Emerald Orb 5
    final x5 = size.width * 0.9 - sin(animationValue * 2 * pi + 0.5) * 100;
    final y5 = size.height * 0.1 + cos(animationValue * 2 * pi + 0.5) * 80;
    paint.color = const Color(0xFF0D9488).withValues(alpha: 0.4); // Teal
    canvas.drawCircle(Offset(x5, y5), 240, paint);
  }

  @override
  bool shouldRepaint(covariant MeshPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
