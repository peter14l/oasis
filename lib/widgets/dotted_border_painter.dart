import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;

class DottedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dash;
  final Radius borderRadius;

  DottedBorderPainter({
    this.color = Colors.white,
    this.strokeWidth = 1.0,
    this.gap = 3.0,
    this.dash = 3.0,
    this.borderRadius = Radius.zero,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        borderRadius,
      ));

    final Path dashPath = Path();
    double distance = 0.0;
    
    for (final PathMetric metric in path.computeMetrics()) {
      while (distance < metric.length) {
        dashPath.addPath(
          metric.extractPath(distance, distance + dash),
          Offset.zero,
        );
        distance += dash + gap;
      }
      distance = 0.0;
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant DottedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap ||
        oldDelegate.dash != dash ||
        oldDelegate.borderRadius != borderRadius;
  }
}

class DottedBorder extends StatelessWidget {
  final Widget child;
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dash;
  final Radius borderRadius;
  final EdgeInsets padding;

  const DottedBorder({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.strokeWidth = 1.0,
    this.gap = 3.0,
    this.dash = 3.0,
    this.borderRadius = Radius.zero,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DottedBorderPainter(
        color: color,
        strokeWidth: strokeWidth,
        gap: gap,
        dash: dash,
        borderRadius: borderRadius,
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
