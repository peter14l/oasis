import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:oasis/services/fortress_service.dart';

/// Widget to display fortress status in friend lists and chat
class FortressStatusDisplay extends StatelessWidget {
  final FortressStatus fortressStatus;
  final bool compact;

  const FortressStatusDisplay({
    super.key,
    required this.fortressStatus,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!fortressStatus.isActive) {
      return const SizedBox.shrink();
    }

    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            FluentIcons.lock_closed_24_regular,
            size: 14,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              fortressStatus.message ?? 'In my fortress',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.primary,
                fontStyle: FontStyle.italic,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            FluentIcons.lock_closed_24_regular,
            size: 18,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'In Fortress Mode',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  fortressStatus.message ?? 'In my fortress',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip widget showing fortress status for presence display
class FortressStatusChip extends StatelessWidget {
  final FortressStatus fortressStatus;

  const FortressStatusChip({
    super.key,
    required this.fortressStatus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!fortressStatus.isActive) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            FluentIcons.lock_closed_24_regular,
            size: 14,
            color: colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            fortressStatus.message ?? 'In my fortress',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

/// Stream builder widget that shows fortress status for a user
class UserFortressStatus extends StatelessWidget {
  final String userId;
  final Widget Function(FortressStatus status) builder;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  const UserFortressStatus({
    super.key,
    required this.userId,
    required this.builder,
    this.loadingWidget,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FortressStatus>(
      future: FortressService.getFortressStatus(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget ?? const SizedBox.shrink();
        }

        if (snapshot.hasError) {
          return errorWidget ?? const SizedBox.shrink();
        }

        final status = snapshot.data ?? const FortressStatus(isActive: false);
        return builder(status);
      },
    );
  }
}