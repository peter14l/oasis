import 'dart:math';
import 'package:flutter/material.dart';

/// Custom painter for the breathing circle animation
/// Used in Zen Carousel breath interstitials
class BreathingCirclePainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color color;
  final bool isInhale; // true for inhale, false for exhale

  BreathingCirclePainter({
    required this.progress,
    required this.color,
    required this.isInhale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = min(size.width, size.height) / 2;

    // Calculate current radius based on breath phase
    final radiusProgress = isInhale ? progress : (1.0 - progress);
    final currentRadius = maxRadius * (0.3 + (radiusProgress * 0.7));

    // Draw outer glow
    final glowPaint =
        Paint()
          ..color = color.withValues(alpha: 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    canvas.drawCircle(center, currentRadius + 20, glowPaint);

    // Draw main circle with gradient
    final gradient = RadialGradient(
      colors: [
        color.withValues(alpha: 0.8),
        color.withValues(alpha: 0.4),
        color.withValues(alpha: 0.1),
      ],
      stops: const [0.0, 0.7, 1.0],
    );

    final circlePaint =
        Paint()
          ..shader = gradient.createShader(
            Rect.fromCircle(center: center, radius: currentRadius),
          );
    canvas.drawCircle(center, currentRadius, circlePaint);

    // Draw border
    final borderPaint =
        Paint()
          ..color = color.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    canvas.drawCircle(center, currentRadius, borderPaint);

    // Draw inner particles (rotating dots)
    _drawParticles(canvas, center, currentRadius * 0.6, progress);
  }

  void _drawParticles(
    Canvas canvas,
    Offset center,
    double radius,
    double progress,
  ) {
    final particlePaint =
        Paint()
          ..color = color.withValues(alpha: 0.5)
          ..style = PaintingStyle.fill;

    const particleCount = 8;
    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 2 * pi + (progress * 2 * pi);
      const particleRadius = 4.0;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      canvas.drawCircle(Offset(x, y), particleRadius, particlePaint);
    }
  }

  @override
  bool shouldRepaint(BreathingCirclePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isInhale != isInhale ||
        oldDelegate.color != color;
  }
}

/// Widget for the breathing circle interstitial
/// Appears every 5-8 posts in Zen Carousel
class ZenBreathWidget extends StatefulWidget {
  final VoidCallback onComplete;
  final Duration breathDuration;
  final Duration waitDuration;

  const ZenBreathWidget({
    super.key,
    required this.onComplete,
    this.breathDuration = const Duration(seconds: 4),
    this.waitDuration = const Duration(seconds: 5),
  });

  @override
  State<ZenBreathWidget> createState() => _ZenBreathWidgetState();
}

class _ZenBreathWidgetState extends State<ZenBreathWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathController;
  bool _isInhale = true;
  bool _canProceed = false;
  int _breathCycles = 0;

  @override
  void initState() {
    super.initState();

    _breathController = AnimationController(
      duration: widget.breathDuration,
      vsync: this,
    );

    _breathController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isInhale = false;
        });
        _breathController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        setState(() {
          _isInhale = true;
          _breathCycles++;
        });

        // After 2 breath cycles, enable the "Next" button
        if (_breathCycles >= 2) {
          Future.delayed(widget.waitDuration - (widget.breathDuration * 2), () {
            if (mounted) {
              setState(() {
                _canProceed = true;
              });
            }
          });
        } else {
          _breathController.forward();
        }
      }
    });

    _breathController.forward();
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.surface,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Breathing circle
            AnimatedBuilder(
              animation: _breathController,
              builder: (context, child) {
                return SizedBox(
                  width: 250,
                  height: 250,
                  child: CustomPaint(
                    painter: BreathingCirclePainter(
                      progress: _breathController.value,
                      color: colorScheme.primary,
                      isInhale: _isInhale,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 40),

            // Instruction text
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _isInhale ? 'Breathe In' : 'Breathe Out',
                key: ValueKey(_isInhale),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),

            const SizedBox(height: 60),

            // Next button (appears after wait duration)
            AnimatedOpacity(
              opacity: _canProceed ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: FilledButton.icon(
                onPressed: _canProceed ? widget.onComplete : null,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Continue'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
