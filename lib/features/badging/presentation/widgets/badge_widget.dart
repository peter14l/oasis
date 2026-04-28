import 'package:flutter/material.dart';
import 'package:oasis/features/badging/domain/models/trust_badge.dart';
import 'package:oasis/themes/app_colors.dart';

/// Widget to display a single badge
class BadgeWidget extends StatelessWidget {
  final TrustBadge badge;
  final double size;
  final bool showLabel;
  final VoidCallback? onTap;

  const BadgeWidget({
    super.key,
    required this.badge,
    this.size = 32,
    this.showLabel = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(size / 4),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              badge.icon ?? '🏅',
              style: TextStyle(fontSize: size * 0.5),
            ),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 4),
          Text(
            badge.name,
            style: TextStyle(
              fontSize: size * 0.3,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }
}

/// Widget to display a row/grid of badges
class BadgeListWidget extends StatelessWidget {
  final List<TrustBadge> badges;
  final double badgeSize;
  final bool showLabels;
  final int maxDisplay;
  final Axis axis;
  final WrapAlignment wrapAlignment;

  const BadgeListWidget({
    super.key,
    required this.badges,
    this.badgeSize = 32,
    this.showLabels = true,
    this.maxDisplay = 10,
    this.axis = Axis.horizontal,
    this.wrapAlignment = WrapAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final displayBadges = badges.take(maxDisplay).toList();

    if (displayBadges.isEmpty) {
      return const SizedBox.shrink();
    }

    if (axis == Axis.horizontal) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: displayBadges.map((badge) {
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: BadgeWidget(
                badge: badge,
                size: badgeSize,
                showLabel: showLabels,
              ),
            );
          }).toList(),
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: wrapAlignment,
      children: displayBadges.map((badge) {
        return BadgeWidget(
          badge: badge,
          size: badgeSize,
          showLabel: showLabels,
        );
      }).toList(),
    );
  }
}

/// Compact badge for showing in lists (e.g., member list)
class CompactBadgeWidget extends StatelessWidget {
  final TrustBadge badge;

  const CompactBadgeWidget({
    super.key,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: badge.description ?? badge.name,
      child: Text(
        badge.icon ?? '🏅',
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}