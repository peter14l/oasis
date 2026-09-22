import 'package:flutter/material.dart';
import 'package:oasis/features/messages/presentation/providers/chat_state.dart';

/// WhatsApp-style 4-stage message status icon with smooth animated transitions.
///
/// States:
/// 1. [MessageStatus.sending] / pending: Clock icon (access_time_rounded)
/// 2. [MessageStatus.sent]: Single grey checkmark (done)
/// 3. [MessageStatus.delivered]: Double grey checkmark (done_all)
/// 4. [isRead == true]: Double blue checkmark (done_all, #34B7F1)
/// 5. [MessageStatus.failed]: Red alert icon (error_outline) with tap-to-retry
class WhatsAppStatusIcon extends StatelessWidget {
  const WhatsAppStatusIcon({
    super.key,
    required this.status,
    required this.isRead,
    this.onRetry,
    this.color,
    this.isDesktop = false,
  });

  final MessageStatus? status;
  final bool isRead;
  final VoidCallback? onRetry;
  final Color? color;
  final bool isDesktop;

  // WhatsApp's authentic read receipt blue
  static const Color whatsAppBlue = Color(0xFF34B7F1);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final defaultColor = color ?? colorScheme.onPrimaryContainer.withValues(alpha: 0.65);

    final currentStatus = status;

    if (currentStatus == MessageStatus.failed) {
      return GestureDetector(
        onTap: onRetry,
        behavior: HitTestBehavior.opaque,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Tooltip(
            message: 'Failed to send. Tap to retry.',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 14,
                  color: colorScheme.error,
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.refresh_rounded,
                  size: 12,
                  color: colorScheme.error,
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget iconWidget;

    if (currentStatus == MessageStatus.sending) {
      // WhatsApp Clock icon for pending / buffered / sending
      iconWidget = Icon(
        Icons.access_time_rounded,
        key: const ValueKey('status_clock'),
        size: 12,
        color: defaultColor.withValues(alpha: 0.7),
      );
    } else if (currentStatus == MessageStatus.sent) {
      // Single grey checkmark
      iconWidget = Icon(
        Icons.done_rounded,
        key: const ValueKey('status_sent'),
        size: 14,
        color: defaultColor,
      );
    } else {
      // Delivered or Read: double checkmark
      final isDeliveredOrRead = isRead || currentStatus == MessageStatus.delivered;
      final checkColor = isRead ? whatsAppBlue : defaultColor;

      iconWidget = TweenAnimationBuilder<Color?>(
        key: ValueKey('status_double_${isRead ? 'blue' : 'grey'}'),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        tween: ColorTween(
          begin: isRead ? defaultColor : whatsAppBlue,
          end: checkColor,
        ),
        builder: (context, animatedColor, child) {
          return Icon(
            isDeliveredOrRead ? Icons.done_all_rounded : Icons.done_rounded,
            size: 15,
            color: animatedColor ?? checkColor,
          );
        },
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: animation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: iconWidget,
    );
  }
}
