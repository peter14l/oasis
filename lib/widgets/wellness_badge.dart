import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oasis_v2/services/screen_time_service.dart';

class WellnessBadge extends StatelessWidget {
  const WellnessBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ScreenTimeService>(
      builder: (context, service, child) {
        final streak = service.getWellnessStreak();
        final isUnder = service.isUnderLimit();
        final theme = Theme.of(context);

        if (streak == 0 && !isUnder) {
          return const SizedBox.shrink(); // Hide if no streak and failed today
        }

        // "Digital Zen Master" if streak > 7
        final isMaster = streak >= 7;
        final label = isMaster ? 'Zen Master' : '$streak Day Streak';
        final color =
            isMaster
                ? const Color(0xFFFFD700)
                : const Color(0xFF4CAF50); // Gold vs Green

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_fire_department, size: 16, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
