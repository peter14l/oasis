import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oasis/services/curation_tracking_service.dart';
import 'package:oasis/services/app_initializer.dart'; // For ThemeProvider
import 'package:oasis/core/network/supabase_client.dart';

/// Key for sync preference in SharedPreferences
const String _kCurationSyncEnabled = 'curation_sync_enabled';

class PrivacyTransparencyCard extends StatefulWidget {
  const PrivacyTransparencyCard({super.key});

  @override
  State<PrivacyTransparencyCard> createState() =>
      _PrivacyTransparencyCardState();
}

class _PrivacyTransparencyCardState extends State<PrivacyTransparencyCard> {
  bool _isSyncEnabled = false;
  bool _isLoading = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadSyncPreference();
  }

  Future<void> _loadSyncPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _isSyncEnabled = prefs.getBool(_kCurationSyncEnabled) ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleSync(bool newValue) async {
    if (newValue == true) {
      // Turning ON - sync existing local data to server
      await _syncLocalToServer();
    } else if (_isSyncEnabled == true) {
      // Turning OFF from ON - show warning
      final confirmed = await _showTurnOffWarning();
      if (!confirmed) return; // User cancelled
      // Delete from server
      await _deleteServerAnalytics();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kCurationSyncEnabled, newValue);
    if (mounted) setState(() => _isSyncEnabled = newValue);
  }

  Future<void> _syncLocalToServer() async {
    if (_isSyncing) return;

    final supabase = SupabaseService();
    if (!supabase.isAuthenticated) {
      debugPrint('[PrivacyTransparency] User not authenticated, skipping sync');
      return;
    }

    setState(() => _isSyncing = true);

    try {
      final service = context.read<CurationTrackingService>();
      final syncData = await service.getSyncData();

      for (final data in syncData) {
        await supabase.client.rpc('sync_user_analytics', params: data);
      }

      debugPrint('[PrivacyTransparency] Sync to server completed: ${syncData.length} categories');
    } catch (e) {
      debugPrint('[PrivacyTransparency] Sync error: $e');
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<bool> _showTurnOffWarning() async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Disable Cloud Sync?'),
                content: const Text(
                  'Disabling sync will return your data to local-only storage. '
                  'You won\'t receive curated recommendations on new devices, and your '
                  'analytics will be deleted from our servers.\n\n'
                  'Are you sure you want to disable?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    child: const Text('Disable Sync'),
                  ),
                ],
              ),
        ) ??
        false;
  }

  Future<void> _deleteServerAnalytics() async {
    final supabase = SupabaseService();
    if (!supabase.isAuthenticated) return;

    try {
      await supabase.client.rpc('delete_user_analytics');
      debugPrint('[PrivacyTransparency] Deleted server analytics');
    } catch (e) {
      debugPrint('[PrivacyTransparency] Delete error: $e');
    }
  }

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
            'Oasis collects data on your interactions (likes, time spent, and categories) to provide personalized curation. This data is stored on your device by default and only synced to our secure servers if you enable Cloud Sync.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          // "Your data is NEVER sold" assurance text
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  FluentIcons.checkmark_circle_24_regular,
                  color: colorScheme.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your data is NEVER sold to third parties and is SOLELY used to provide you with curated content.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Sync toggle
          if (!_isLoading) ...[
            const Divider(),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Sync to Cloud'),
              subtitle: Text(
                _isSyncEnabled
                    ? _isSyncing
                        ? 'Syncing your analytics...'
                        : 'Your analytics are backed up for new devices'
                    : 'Keep analytics local only',
                style: theme.textTheme.bodySmall,
              ),
              value: _isSyncEnabled,
              onChanged: _isSyncing ? null : _toggleSync,
              contentPadding: EdgeInsets.zero,
              secondary:
                  _isSyncing
                      ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : Icon(
                        _isSyncEnabled
                            ? FluentIcons.cloud_checkmark_24_regular
                            : FluentIcons.cloud_dismiss_24_regular,
                        color:
                            _isSyncEnabled
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                      ),
            ),
          ],

          const SizedBox(height: 8),
          FutureBuilder<Map<String, dynamic>>(
            future:
                context.read<CurationTrackingService>().getTrackingSummary(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final data = snapshot.data!;
              return Column(
                children: [
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
                    _isSyncEnabled
                        ? 'Local + Cloud'
                        : '${data['data_location']}',
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
      builder:
          (context) => AlertDialog(
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
