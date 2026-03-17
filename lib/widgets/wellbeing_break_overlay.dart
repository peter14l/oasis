import 'dart:async';
import 'package:flutter/material.dart';

/// A persistent top-of-screen banner displayed when the 30-minute
/// kill-switch is active.
///
/// Shows a friendly nudge and a "Reset my session" button that calls
/// [onReset] — which should call [ScreenTimeService.resetKillSwitch()].
///
/// Automatically dismisses (swipes up) after 10 seconds to avoid blocking content.
class WellbeingBreakOverlay extends StatefulWidget {
  final int limitMinutes;
  final VoidCallback onReset;

  const WellbeingBreakOverlay({
    super.key,
    required this.limitMinutes,
    required this.onReset,
  });

  @override
  State<WellbeingBreakOverlay> createState() => _WellbeingBreakOverlayState();
}

class _WellbeingBreakOverlayState extends State<WellbeingBreakOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  Timer? _dismissTimer;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    // Automatically dismiss after 10 seconds
    _dismissTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    if (_isDismissed) return;
    setState(() => _isDismissed = true);
    _controller.reverse();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed && _controller.isDismissed) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          bottom: false,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('🌿', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),

                // Message
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${widget.limitMinutes} minutes — time for a break!',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.onTertiaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Feed & Search are paused. Messages still open.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onTertiaryContainer.withValues(
                            alpha: 0.75,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Reset button
                TextButton(
                  onPressed: () {
                    _dismiss();
                    widget.onReset();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.tertiary,
                    backgroundColor: colorScheme.tertiary.withValues(
                      alpha: 0.12,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Reset',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
