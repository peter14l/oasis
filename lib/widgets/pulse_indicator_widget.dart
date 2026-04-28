import 'package:flutter/material.dart';
import 'package:oasis/widgets/pulse_picker_sheet.dart';

/// Widget to display the current pulse status with a quick-picker button
class PulseIndicatorWidget extends StatelessWidget {
  final String? pulseStatus;
  final String? pulseText;
  final DateTime? pulseSince;
  final bool pulseVisible;
  final bool compact;
  final VoidCallback? onTap;

  const PulseIndicatorWidget({
    super.key,
    this.pulseStatus,
    this.pulseText,
    this.pulseSince,
    this.pulseVisible = true,
    this.compact = false,
    this.onTap,
  });

  String get _statusEmoji {
    if (pulseStatus == null) return '⚪';
    try {
      final status = PulseStatus.values.firstWhere(
        (s) => s.name == pulseStatus,
        orElse: () => PulseStatus.home,
      );
      return status.emoji;
    } catch (_) {
      return '⚪';
    }
  }

  String get _statusLabel {
    if (pulseStatus == null) return 'Set pulse';
    try {
      final status = PulseStatus.values.firstWhere(
        (s) => s.name == pulseStatus,
        orElse: () => PulseStatus.home,
      );
      if (status == PulseStatus.withFriend || status == PulseStatus.atLocation) {
        return pulseText ?? status.label;
      }
      return status.label;
    } catch (_) {
      return pulseStatus!;
    }
  }

  String get _timeAgo {
    if (pulseSince == null) return '';
    final diff = DateTime.now().difference(pulseSince!);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasPulse = pulseStatus != null && pulseStatus!.isNotEmpty;

    if (compact) {
      return _buildCompact(context, colorScheme, hasPulse);
    }

    return _buildFull(context, colorScheme, hasPulse);
  }

  Widget _buildCompact(BuildContext context, ColorScheme colorScheme, bool hasPulse) {
    final theme = Theme.of(context);

    return Material(
      color: hasPulse
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                hasPulse ? _statusEmoji : '⚪',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 6),
              Text(
                hasPulse ? _statusLabel : 'Set pulse',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: hasPulse
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                  fontWeight: hasPulse ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFull(BuildContext context, ColorScheme colorScheme, bool hasPulse) {
    final theme = Theme.of(context);

    return Material(
      color: hasPulse
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: hasPulse
                      ? colorScheme.primary.withValues(alpha: 0.2)
                      : colorScheme.surface,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    hasPulse ? _statusEmoji : '⚪',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasPulse ? _statusLabel : 'Set your pulse',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: hasPulse
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                      ),
                    ),
                    if (hasPulse && pulseSince != null)
                      Text(
                        _timeAgo,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                hasPulse ? Icons.edit_outlined : Icons.add_circle_outline,
                color: hasPulse
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Quick pulse button for the header
class PulseQuickButton extends StatelessWidget {
  final String? pulseStatus;
  final String? pulseText;
  final VoidCallback onTap;

  const PulseQuickButton({
    super.key,
    this.pulseStatus,
    this.pulseText,
    required this.onTap,
  });

  String get _statusEmoji {
    if (pulseStatus == null) return '';
    try {
      final status = PulseStatus.values.firstWhere(
        (s) => s.name == pulseStatus,
        orElse: () => PulseStatus.home,
      );
      return status.emoji;
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasPulse = pulseStatus != null && pulseStatus!.isNotEmpty;

    return Tooltip(
      message: hasPulse ? 'Change pulse' : 'Set pulse',
      child: Material(
        color: hasPulse
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasPulse) ...[
                  Text(
                    _statusEmoji,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 6),
                ],
                Icon(
                  hasPulse ? Icons.circle : Icons.add_circle_outline,
                  size: 16,
                  color: hasPulse
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
