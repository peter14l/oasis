import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:oasis/features/circles/domain/models/circles_models.dart';
import 'package:oasis/features/circles/presentation/widgets/circles/circle_warmth_indicator.dart';

import 'package:oasis/services/app_initializer.dart'; // For ThemeProvider
import 'package:provider/provider.dart';

class CircleListCard extends StatelessWidget {
  final CircleEntity circle;
  final VoidCallback onTap;
  final bool isDesktop;

  const CircleListCard({
    super.key,
    required this.circle,
    required this.onTap,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isM3E = themeProvider.isM3EEnabled;

    // Desktop layout: card with vertical stack
    if (isDesktop) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isM3E ? 28 : 20),
            color: theme.colorScheme.surface,
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 12,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Emoji avatar centered
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: isM3E ? BoxShape.rectangle : BoxShape.circle,
                      borderRadius: isM3E ? BorderRadius.circular(20) : null,
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      circle.emoji,
                      style: const TextStyle(fontSize: 36),
                    ),
                  ),
                ),
                const Spacer(),
                // Circle name
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        circle.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: isM3E ? FontWeight.w900 : FontWeight.bold,
                          letterSpacing: isM3E ? -0.5 : 0,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (circle.isTrustCircle)
                      Icon(
                        Icons.favorite,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Member count & Warmth
                Row(
                  children: [
                    Icon(
                      FluentIcons.people_24_regular,
                      size: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${circle.memberIds.length} member${circle.memberIds.length == 1 ? '' : 's'}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    CircleWarmthIndicator(score: circle.warmthScore, size: 18),
                  ],
                ),
                const SizedBox(height: 12),
                // Streak badge
                if (circle.streakCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(isM3E ? 8 : 12),
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFF6B35).withValues(alpha: 0.8),
                          const Color(0xFFFF9F1C).withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 3),
                        Text(
                          '${circle.streakCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    // Mobile layout: horizontal row (original)
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isM3E ? 28 : 20),
          color: theme.colorScheme.surface,
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // ── Emoji avatar ───────────────────────────────────────
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: isM3E ? BoxShape.rectangle : BoxShape.circle,
                  borderRadius: isM3E ? BorderRadius.circular(16) : null,
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                ),
                alignment: Alignment.center,
                child: Text(circle.emoji, style: const TextStyle(fontSize: 28)),
              ),

              const SizedBox(width: 14),

              // ── Info ────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            circle.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: isM3E ? FontWeight.w900 : FontWeight.bold,
                              letterSpacing: isM3E ? -0.5 : 0,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (circle.isTrustCircle) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.favorite,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          FluentIcons.people_24_regular,
                          size: 13,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${circle.memberIds.length} member${circle.memberIds.length == 1 ? '' : 's'}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleWarmthIndicator(score: circle.warmthScore, size: 14),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Streak badge ────────────────────────────────────────
              if (circle.streakCount > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(isM3E ? 8 : 12),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFF6B35).withValues(alpha: 0.8),
                        const Color(0xFFFF9F1C).withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 3),
                      Text(
                        '${circle.streakCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],

              Icon(
                FluentIcons.chevron_right_24_regular,
                size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
