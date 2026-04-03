import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:oasis_v2/services/wellness_service.dart';
import 'package:oasis_v2/services/auth_service.dart';

class WellnessBadge extends StatelessWidget {
  const WellnessBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WellnessService>(
      builder: (context, wellness, child) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final user = AuthService().currentUser;
        final xp = user?.userMetadata?['xp'] ?? 0;

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
                  '$xp XP',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 1,
                  height: 12,
                  color: Colors.white30,
                ),
                const SizedBox(width: 8),
                const Icon(Icons.insights, size: 16, color: Colors.white),
              ],
            ),
          ),
        );
      },
    );
  }
}
