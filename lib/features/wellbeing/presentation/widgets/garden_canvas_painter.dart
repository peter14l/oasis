import 'dart:math';
import 'package:flutter/material.dart';
import 'package:oasis/features/wellbeing/domain/models/garden_plot_entity.dart';

class GardenCanvasPainter extends CustomPainter {
  final List<GardenPlotEntity> plots;
  final ColorScheme colorScheme;

  GardenCanvasPainter({required this.plots, required this.colorScheme});

  @override
  void paint(Canvas canvas, Size size) {
    final seedPaint = Paint()
      ..color = colorScheme.primary.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
      
    final sproutPaint = Paint()
      ..color = Colors.lightGreenAccent.shade700
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final stemPaint = Paint()
      ..color = Colors.green.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
      
    final leafPaint = Paint()
      ..color = Colors.green.shade400
      ..style = PaintingStyle.fill;

    final bloomPaint = Paint()
      ..color = colorScheme.secondary
      ..style = PaintingStyle.fill;

    for (final plot in plots) {
      final x = plot.xPos * size.width;
      final y = plot.yPos * size.height;
      final center = Offset(x, y);

      switch (plot.stage) {
        case 0: // Seed
          canvas.drawCircle(center, 4, seedPaint);
          break;
        case 1: // Sprout
          final path = Path();
          path.moveTo(x, y);
          path.quadraticBezierTo(x + 10, y - 10, x, y - 20);
          canvas.drawPath(path, sproutPaint);
          break;
        case 2: // Young Plant
          // Draw stem
          final path = Path();
          path.moveTo(x, y);
          path.quadraticBezierTo(x - 10, y - 20, x + 5, y - 40);
          canvas.drawPath(path, stemPaint);
          
          // Draw leaf
          final leafPath = Path();
          leafPath.moveTo(x - 5, y - 20);
          leafPath.quadraticBezierTo(x - 20, y - 30, x - 25, y - 15);
          leafPath.quadraticBezierTo(x - 10, y - 10, x - 5, y - 20);
          canvas.drawPath(leafPath, leafPaint);
          break;
        case 3: // Blooming
          // Draw stem
          final path = Path();
          path.moveTo(x, y);
          path.quadraticBezierTo(x + 15, y - 30, x - 5, y - 60);
          canvas.drawPath(path, stemPaint);
          
          // Draw leaves
          final leafPath1 = Path();
          leafPath1.moveTo(x + 10, y - 20);
          leafPath1.quadraticBezierTo(x + 30, y - 30, x + 35, y - 15);
          leafPath1.quadraticBezierTo(x + 20, y - 10, x + 10, y - 20);
          canvas.drawPath(leafPath1, leafPaint);

          final leafPath2 = Path();
          leafPath2.moveTo(x - 2, y - 40);
          leafPath2.quadraticBezierTo(x - 20, y - 50, x - 25, y - 35);
          leafPath2.quadraticBezierTo(x - 10, y - 30, x - 2, y - 40);
          canvas.drawPath(leafPath2, leafPaint);
          
          // Draw flower/bloom
          for (var i = 0; i < 5; i++) {
            final angle = i * (2 * pi / 5);
            final dx = cos(angle) * 8;
            final dy = sin(angle) * 8;
            canvas.drawCircle(Offset(x - 5 + dx, y - 60 + dy), 6, bloomPaint);
          }
          canvas.drawCircle(Offset(x - 5, y - 60), 6, Paint()..color = Colors.amber);
          break;
      }
    }
  }

  @override
  bool shouldRepaint(covariant GardenCanvasPainter oldDelegate) {
    return oldDelegate.plots != plots || oldDelegate.colorScheme != colorScheme;
  }
}
