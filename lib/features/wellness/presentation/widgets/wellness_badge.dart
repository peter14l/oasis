import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:oasis/services/auth_service.dart';

class WellnessBadge extends StatelessWidget {
  final int? xp;
  final bool showInsights;

  const WellnessBadge({super.key, this.xp, this.showInsights = true});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = AuthService().currentUser;
    final displayXp = xp ?? user?.userMetadata?['xp'] ?? 0;

    return GestureDetector(
      onTap: () => context.push('/wellness-stats'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorScheme.primary, colorScheme.tertiary],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              '$displayXp XP',
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (showInsights) ...[
              const SizedBox(width: 8),
              Container(
                width: 1,
                height: 12,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.insights, size: 16, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }
}
