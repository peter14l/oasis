import 'package:flutter/material.dart';

class GhostPresencePainter extends CustomPainter {
  final Map<String, dynamic> presenceState;
  final String currentUserId;
  final double initialOffset;
  final double canvasScale;

  GhostPresencePainter({
    required this.presenceState,
    required this.currentUserId,
    required this.initialOffset,
    required this.canvasScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

    presenceState.forEach((userId, presences) {
      if (userId == currentUserId) return;
      if (presences is! List) return;

      for (final p in presences) {
        if (p is! Map) continue;
        final x = p['x'];
        final y = p['y'];
        
        if (x == null || y == null) continue;

        // Convert from Canvas relative coordinates to Stack pixels
        final screenX = initialOffset + (x as double) * canvasScale;
        final screenY = initialOffset + (y as double) * canvasScale;

        // Draw a glowing orb
        paint.color = Colors.white.withValues(alpha: 0.4);
        canvas.drawCircle(Offset(screenX, screenY), 20, paint);
        
        paint.color = Colors.white.withValues(alpha: 0.1);
        canvas.drawCircle(Offset(screenX, screenY), 40, paint);
      }
    });
  }

  @override
  bool shouldRepaint(covariant GhostPresencePainter oldDelegate) {
    return oldDelegate.presenceState != presenceState;
  }
}
