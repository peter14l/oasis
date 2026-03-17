import 'dart:math';
import 'package:flutter/material.dart';

class StarryNightBackground extends StatefulWidget {
  final double scrollOffset;
  final Widget? child;

  const StarryNightBackground({
    super.key,
    this.scrollOffset = 0,
    this.child,
  });

  @override
  State<StarryNightBackground> createState() => _StarryNightBackgroundState();
}

class _StarryNightBackgroundState extends State<StarryNightBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<StarModel> _stars = [];
  final int _starCount = 150;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _generateStars();
  }

  void _generateStars() {
    final random = Random();
    for (int i = 0; i < _starCount; i++) {
      _stars.add(StarModel(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: random.nextDouble() * 2.5 + 0.5,
        twinkleSpeed: random.nextDouble() * 2 + 1,
        twinkleOffset: random.nextDouble() * pi * 2,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // The deep black background
        Container(color: const Color(0xFF000000)),
        
        // The stars with parallax
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: StarPainter(
                stars: _stars,
                twinkleProgress: _controller.value,
                scrollOffset: widget.scrollOffset,
              ),
              size: Size.infinite,
            );
          },
        ),
        
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class StarModel {
  final double x; // 0.0 - 1.0
  final double y; // 0.0 - 1.0
  final double size;
  final double twinkleSpeed;
  final double twinkleOffset;

  StarModel({
    required this.x,
    required this.y,
    required this.size,
    required this.twinkleSpeed,
    required this.twinkleOffset,
  });
}

class StarPainter extends CustomPainter {
  final List<StarModel> stars;
  final double twinkleProgress;
  final double scrollOffset;

  StarPainter({
    required this.stars,
    required this.twinkleProgress,
    required this.scrollOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;

    for (var star in stars) {
      // Calculate twinkle opacity
      final opacity = (sin(twinkleProgress * 2 * pi * star.twinkleSpeed + star.twinkleOffset) + 1) / 2;
      paint.color = Colors.white.withValues(alpha: 0.2 + (opacity * 0.8));

      // Calculate position with parallax
      // We wrap the y position to keep stars visible as we scroll
      final xPos = star.x * size.width;
      double yPos = (star.y * size.height - (scrollOffset * 0.2)) % size.height;
      if (yPos < 0) yPos += size.height;

      canvas.drawCircle(Offset(xPos, yPos), star.size / 2, paint);
      
      // Add a slight glow to larger stars
      if (star.size > 2.0) {
        final glowPaint = Paint()
          ..color = Colors.white.withValues(alpha: opacity * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
        canvas.drawCircle(Offset(xPos, yPos), star.size, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant StarPainter oldDelegate) {
    return oldDelegate.twinkleProgress != twinkleProgress ||
        oldDelegate.scrollOffset != scrollOffset;
  }
}
