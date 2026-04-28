import 'package:flutter/material.dart';
import 'package:oasis/features/wellbeing/presentation/providers/cozy_mode_state.dart';

/// Displays the cozy status of a user as a styled badge/chip.
class CozyStatusBadge extends StatelessWidget {
  final String status;
  final String? statusText;
  final bool compact;
  final VoidCallback? onTap;

  const CozyStatusBadge({
    super.key,
    required this.status,
    this.statusText,
    this.compact = false,
    this.onTap,
  });

  factory CozyStatusBadge.fromMode(CozyMode mode, {String? customText, bool compact = false, VoidCallback? onTap}) {
    return CozyStatusBadge(
      status: mode.id,
      statusText: customText,
      compact: compact,
      onTap: onTap,
    );
  }

  String get _displayText {
    CozyMode? mode;
    try {
      mode = CozyMode.values.firstWhere((m) => m.id == status);
    } catch (_) {
      mode = CozyMode.custom;
    }

    if (mode == CozyMode.custom && statusText != null && statusText!.isNotEmpty) {
      return statusText!;
    }
    return mode.defaultText;
  }

  String get _emoji {
    CozyMode? mode;
    try {
      mode = CozyMode.values.firstWhere((m) => m.id == status);
    } catch (_) {
      return '✨';
    }
    return mode.emoji;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (compact) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_emoji, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Text(
                _displayText,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              _displayText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.bedtime_rounded,
              size: 14,
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows an indicator that the other party in a conversation is in cozy mode.
class CozyIndicator extends StatelessWidget {
  final String cozyStatus;
  final String? cozyStatusText;
  final String recipientName;

  const CozyIndicator({
    super.key,
    required this.cozyStatus,
    this.cozyStatusText,
    required this.recipientName,
  });

  String get _statusDescription {
    CozyMode? mode;
    try {
      mode = CozyMode.values.firstWhere((m) => m.id == cozyStatus);
    } catch (_) {
      mode = CozyMode.custom;
    }

    if (mode == CozyMode.custom && cozyStatusText != null && cozyStatusText!.isNotEmpty) {
      return cozyStatusText!;
    }
    return mode.defaultText;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bedtime_rounded,
            size: 14,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            '$recipientName is $_statusDescription',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}