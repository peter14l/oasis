import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:provider/provider.dart';
import 'package:oasis/services/curation_tracking_service.dart';
import 'package:oasis/services/app_initializer.dart'; // For ThemeProvider

class PrivacyTransparencyCard extends StatelessWidget {
  const PrivacyTransparencyCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isM3E = themeProvider.isM3EEnabled;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(isM3E ? 28 : 16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isM3E ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  FluentIcons.shield_task_24_regular,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Privacy Transparency',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Oasis collects data on your interactions (likes, time spent, and categories) to provide personalized curation. This data is stored strictly on your device and is NEVER sent to our servers or shared with third parties.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<Map<String, dynamic>>(
            future: context.read<CurationTrackingService>().getTrackingSummary(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final data = snapshot.data!;
              return Column(
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildSummaryItem(
                    context,
                    'Tracked Categories',
                    '${data['tracked_categories']}',
                  ),
                  _buildSummaryItem(
                    context,
                    'Likes Recorded',
                    '${data['total_likes_recorded']}',
                  ),
                  _buildSummaryItem(
                    context,
                    'Data Location',
                    '${data['data_location']}',
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => _confirmClearData(context),
                    icon: const Icon(FluentIcons.delete_24_regular, size: 18),
                    label: const Text('Clear Local Tracking Data'),
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmClearData(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Tracking Data?'),
        content: const Text(
          'This will remove all locally stored curation data. Your recommendations may become less personalized.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await context.read<CurationTrackingService>().clearAllData();
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(
              'Clear Data',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
