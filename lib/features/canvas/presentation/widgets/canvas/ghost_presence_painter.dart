import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GhostPresencePainter extends CustomPainter {
  final Map<String, dynamic> presenceState;
  final String currentUserId;
  final double initialOffset;
  final double canvasScale;
  final bool showStarFlare;
  final Offset? currentUserPosition;

  GhostPresencePainter({
    required this.presenceState,
    required this.currentUserId,
    required this.initialOffset,
    required this.canvasScale,
    this.showStarFlare = false,
    this.currentUserPosition,
  });

  // Detection threshold for overlap/proximity (in canvas coordinates)
  static const double _proximityThreshold = 0.05;
  bool _hadProximity = false;

  /// Check if any user is close to the current user (for haptics)
  bool checkProximity() {
    if (currentUserPosition == null) return false;

    final myX = currentUserPosition!.dx;
    final myY = currentUserPosition!.dy;

    for (final entry in presenceState.entries) {
      if (entry.key == currentUserId) continue;
      if (entry.value is! List) continue;

      for (final p in entry.value) {
        if (p is! Map) continue;
        final theirX = (p['x'] as num?)?.toDouble();
        final theirY = (p['y'] as num?)?.toDouble();

        if (theirX == null || theirY == null) continue;

        final distance = sqrt(pow(theirX - myX, 2) + pow(theirY - myY, 2));
        if (distance < _proximityThreshold) return true;
      }
    }
    return false;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

    // Track if any user is close for star flare
    bool anyoneClose = false;
    final myX = currentUserPosition?.dx ?? 0;
    final myY = currentUserPosition?.dy ?? 0;

    // Draw ghost orbs first
    presenceState.forEach((userId, presences) {
      if (userId == currentUserId) return;
      if (presences is! List) return;

      for (final p in presences) {
        if (p is! Map) continue;
        final x = p['x'];
        final y = p['y'];

        if (x == null || y == null) continue;

        // Check proximity for haptics
        final theirX = x as double;
        final theirY = y as double;
        final distance = sqrt(pow(theirX - myX, 2) + pow(theirY - myY, 2));
        if (distance < _proximityThreshold) anyoneClose = true;

        // Convert from Canvas relative coordinates to Stack pixels
        final screenX = initialOffset + (theirX * canvasScale);
        final screenY = initialOffset + (theirY * canvasScale);

        // Draw a glowing orb
        paint.color = Colors.white.withValues(alpha: 0.5);
        canvas.drawCircle(Offset(screenX, screenY), 20, paint);

        paint.color = Colors.white.withValues(alpha: 0.15);
        canvas.drawCircle(Offset(screenX, screenY), 40, paint);

        paint.color = Colors.cyanAccent.withValues(alpha: 0.1);
        canvas.drawCircle(Offset(screenX, screenY), 60, paint);
      }
    });

    // Draw Star Flare effect when users are close
    if (showStarFlare && anyoneClose) {
      _drawStarFlare(canvas, size);
    }

    // Trigger haptics on proximity change
    if (anyoneClose != _hadProximity) {
      _hadProximity = anyoneClose;
      if (anyoneClose) {
        // Light haptic for proximity
        HapticFeedback.lightImpact();
      }
    }
  }

  void _drawStarFlare(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final random = Random(DateTime.now().millisecondsSinceEpoch ~/ 100);

    // Draw radial flare lines
    final flarePaint = Paint()
      ..color = Colors.amber.withValues(alpha: 0.3)
      ..strokeWidth = 2;

    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * (3.14159 / 180);
      final startRadius = 50.0 + random.nextDouble() * 50;
      final endRadius = 200.0 + random.nextDouble() * 100;

      final start = Offset(
        center.dx + cos(angle) * startRadius,
        center.dy + sin(angle) * startRadius,
      );
      final end = Offset(
        center.dx + cos(angle) * endRadius,
        center.dy + sin(angle) * endRadius,
      );

      canvas.drawLine(start, end, flarePaint);
    }

    // Draw glowing center
    final glowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30)
      ..color = Colors.amber.withValues(alpha: 0.4);

    canvas.drawCircle(center, 80, glowPaint);
    canvas.drawCircle(center, 40, glowPaint..color = Colors.amber.withValues(alpha: 0.6));
  }

  @override
  bool shouldRepaint(covariant GhostPresencePainter oldDelegate) {
    return oldDelegate.presenceState != presenceState ||
        oldDelegate.showStarFlare != showStarFlare ||
        oldDelegate.currentUserPosition != currentUserPosition;
  }
}
