import 'package:flutter/material.dart';
import 'package:morrow_v2/models/post.dart';
import 'package:intl/intl.dart';

class ActivityGraph extends StatelessWidget {
  final List<Post> posts;
  final int monthsToShow;

  const ActivityGraph({
    super.key,
    required this.posts,
    this.monthsToShow = 6,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Calculate monthly post frequencies
    final now = DateTime.now();
    
    // Generate the last X months list for the X-axis
    List<DateTime> monthsList = [];
    for (int i = monthsToShow - 1; i >= 0; i--) {
      int targetMonth = now.month - i;
      int targetYear = now.year;
      if (targetMonth <= 0) {
        targetMonth += 12;
        targetYear -= 1;
      }
      monthsList.add(DateTime(targetYear, targetMonth, 1));
    }

    final Map<DateTime, int> monthlyCounts = {
      for (var m in monthsList) m: 0
    };

    for (var post in posts) {
      // Find the corresponding month bin
      final postMonth = DateTime(post.timestamp.year, post.timestamp.month, 1);
      if (monthlyCounts.containsKey(postMonth)) {
        monthlyCounts[postMonth] = monthlyCounts[postMonth]! + 1;
      }
    }

    // Determine max frequency for color scaling
    int maxCount = 1;
    if (monthlyCounts.isNotEmpty) {
       final maxVal = monthlyCounts.values.reduce((a, b) => a > b ? a : b);
       maxCount = maxVal == 0 ? 1 : maxVal;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: monthsList.map((monthDate) {
                final count = monthlyCounts[monthDate] ?? 0;
                
                Color cellColor;
                if (count == 0) {
                  cellColor = colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);
                } else {
                  // Scale opacity from 0.4 to 1.0 based on count vs maxCount
                  final intensity = 0.4 + (0.6 * (count / maxCount));
                  cellColor = colorScheme.primary.withValues(alpha: intensity);
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: '${DateFormat('MMMM yyyy').format(monthDate)}: $count post${count == 1 ? '' : 's'}',
                      child: Container(
                        width: 24,
                        height: 48,
                        decoration: BoxDecoration(
                          color: cellColor,
                          borderRadius: BorderRadius.circular(6),
                          border: count == 0 ? Border.all(
                            color: theme.dividerColor.withValues(alpha: 0.1),
                            width: 1,
                          ) : null,
                          boxShadow: count > 0 ? [
                            BoxShadow(
                              color: cellColor.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ] : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('MMM').format(monthDate),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                );
              }).toList(),
            );
          }
        ),
      ],
    );
  }
}
