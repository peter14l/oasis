import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:oasis_v2/features/notifications/domain/models/notification_entity.dart';
import 'package:oasis_v2/features/notifications/presentation/providers/notification_provider.dart';
import 'package:oasis_v2/features/notifications/presentation/providers/notification_state.dart'
    as state;
import 'package:oasis_v2/services/auth_service.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:oasis_v2/core/utils/responsive_layout.dart';
import 'package:oasis_v2/services/app_initializer.dart';

class NotificationsScreen extends StatefulWidget {
  final bool isPanel;
  const NotificationsScreen({super.key, this.isPanel = false});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Desktop layout states
  AppNotification? _selectedNotification;
  String _filterType = 'all'; // all, likes, comments, follows, mentions
  bool _showUnreadOnly = false;
  bool _showSidebar = true;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _markAsRead(AppNotification notification) async {
    if (notification.isRead) return;
    try {
      await context.read<NotificationProvider>().markAsRead(notification.id);
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await context.read<NotificationProvider>().markAllAsRead();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear all notifications?'),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Clear All'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      // Clear all functionality - would need to add to provider
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Notifications cleared')));
      }
    }
  }

  void _handleNotificationTap(AppNotification notification) {
    _markAsRead(notification);

    final isDesktop = ResponsiveLayout.isDesktop(context);
    final usePanelLayout = widget.isPanel;

    if (isDesktop && !usePanelLayout) {
      // On full desktop, show in detail panel
      setState(() => _selectedNotification = notification);
    } else {
      // On mobile or panel, navigate
      if (notification.postId != null) {
        context.push('/post/${notification.postId}/comments');
      } else if (notification.actorId != null &&
          notification.type == 'follow') {
        context.push('/profile/${notification.actorId}');
      }
    }
  }

  List<AppNotification> get _filteredNotifications {
    final provider = context.read<NotificationProvider>();
    var filtered = provider.notifications;

    if (_showUnreadOnly) {
      filtered = filtered.where((n) => !n.isRead).toList();
    }

    if (_filterType != 'all') {
      filtered = filtered.where((n) => n.type == _filterType).toList();
    }

    return filtered;
  }

  Map<String, List<AppNotification>> get _groupedNotifications {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final thisWeek = today.subtract(const Duration(days: 7));

    final Map<String, List<AppNotification>> grouped = {
      'Today': [],
      'Yesterday': [],
      'This Week': [],
      'Earlier': [],
    };

    for (final notification in _filteredNotifications) {
      final localTimestamp = notification.timestamp.toLocal();
      final notifDate = DateTime(
        localTimestamp.year,
        localTimestamp.month,
        localTimestamp.day,
      );

      if (notifDate.isAtSameMomentAs(today)) {
        grouped['Today']!.add(notification);
      } else if (notifDate.isAtSameMomentAs(yesterday)) {
        grouped['Yesterday']!.add(notification);
      } else if (notifDate.isAfter(thisWeek)) {
        grouped['This Week']!.add(notification);
      } else {
        grouped['Earlier']!.add(notification);
      }
    }

    grouped.removeWhere((key, value) => value.isEmpty);
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final unreadCount = provider.unreadCount;

    final isDesktop = ResponsiveLayout.isDesktop(context);
    final usePanelLayout = widget.isPanel;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (isDesktop && !usePanelLayout) {
      // Desktop full screen layout
      return Scaffold(
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  bottom: BorderSide(color: theme.dividerColor, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Notifications',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (unreadCount > 0) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$unreadCount',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (_filteredNotifications.isNotEmpty) ...[
                    TextButton.icon(
                      onPressed: _markAllAsRead,
                      icon: const Icon(Icons.done_all, size: 18),
                      label: const Text('Mark all read'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _clearAll,
                      icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                      label: const Text('Clear all'),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(width: 12),
                  IconButton(
                    icon: Icon(
                      _showSidebar ? Icons.filter_list_off : Icons.filter_list,
                      size: 24,
                    ),
                    onPressed:
                        () => setState(() => _showSidebar = !_showSidebar),
                    tooltip: _showSidebar ? 'Hide Filters' : 'Show Filters',
                    style: IconButton.styleFrom(
                      backgroundColor:
                          _showSidebar
                              ? colorScheme.primaryContainer
                              : colorScheme.surfaceContainerHighest,
                      foregroundColor:
                          _showSidebar
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildDesktopLayout()),
          ],
        ),
      );
    }

    // Mobile layout OR Panel layout (Simplified)
    return Scaffold(
      backgroundColor:
          usePanelLayout ? colorScheme.surface : theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: usePanelLayout ? colorScheme.surface : null,
        automaticallyImplyLeading: !usePanelLayout,
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: !usePanelLayout,
        actions: [
          if (_filteredNotifications.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'mark_read') {
                  _markAllAsRead();
                } else if (value == 'clear_all') {
                  _clearAll();
                } else if (value == 'toggle_unread') {
                  setState(() => _showUnreadOnly = !_showUnreadOnly);
                }
              },
              itemBuilder:
                  (context) => [
                    PopupMenuItem(
                      value: 'toggle_unread',
                      child: Row(
                        children: [
                          Icon(
                            _showUnreadOnly
                                ? Icons.visibility
                                : Icons.visibility_off,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(_showUnreadOnly ? 'Show All' : 'Unread Only'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'mark_read',
                      child: Row(
                        children: [
                          Icon(Icons.done_all, size: 20),
                          SizedBox(width: 12),
                          Text('Mark all read'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'clear_all',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_sweep_outlined,
                            size: 20,
                            color: colorScheme.error,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Clear all',
                            style: TextStyle(color: colorScheme.error),
                          ),
                        ],
                      ),
                    ),
                  ],
            ),
        ],
      ),
      body: _buildMobileLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        if (_showSidebar)
          Container(
            width: 250,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: _buildFiltersSidebar(),
          ),
        Expanded(flex: 2, child: _buildNotificationsList()),
        Expanded(flex: 3, child: _buildDetailPanel()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    final provider = context.watch<NotificationProvider>();
    return provider.state.loadingState == state.NotificationLoadingState.loading
        ? const Center(child: CircularProgressIndicator())
        : _filteredNotifications.isEmpty
        ? _buildEmptyState()
        : RefreshIndicator(
          onRefresh: () async {
            await context.read<NotificationProvider>().loadNotifications(
              refresh: true,
            );
          },
          child: _buildNotificationsList(),
        );
  }

  Widget _buildFiltersSidebar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = context.watch<NotificationProvider>();
    final unreadCount = provider.unreadCount;
    final totalCount = provider.notifications.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Filters',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        SwitchListTile(
          title: const Text('Unread Only'),
          subtitle: Text('$unreadCount unread'),
          value: _showUnreadOnly,
          onChanged: (value) => setState(() => _showUnreadOnly = value),
          contentPadding: EdgeInsets.zero,
        ),

        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),

        Text(
          'Type',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        _buildFilterOption('All', 'all', Icons.notifications_outlined),
        _buildFilterOption('Likes', 'like', Icons.favorite_outline),
        _buildFilterOption('Comments', 'comment', Icons.comment_outlined),
        _buildFilterOption('Follows', 'follow', Icons.person_add_outlined),
        _buildFilterOption('Mentions', 'mention', Icons.alternate_email),

        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Statistics',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildStatRow('Total', totalCount),
              const SizedBox(height: 8),
              _buildStatRow('Unread', unreadCount),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterOption(String label, String value, IconData icon) {
    final isSelected = _filterType == value;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() => _filterType = value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
                    : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color:
                    isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? theme.colorScheme.primary : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, int value) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(
          '$value',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsList() {
    final provider = context.watch<NotificationProvider>();
    if (provider.state.loadingState == state.NotificationLoadingState.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredNotifications.isEmpty) {
      return _buildEmptyState();
    }

    final isDesktop = ResponsiveLayout.isDesktop(context);
    final usePanelLayout = widget.isPanel;
    final grouped = _groupedNotifications;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: grouped.length * 2,
      itemBuilder: (context, index) {
        if (index.isEven) {
          final groupIndex = index ~/ 2;
          final groupKey = grouped.keys.elementAt(groupIndex);
          return Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              groupKey,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          );
        } else {
          final groupIndex = index ~/ 2;
          final groupKey = grouped.keys.elementAt(groupIndex);
          final notifications = grouped[groupKey]!;

          return Column(
            children:
                notifications.map((notification) {
                  return _buildNotificationItem(
                    notification,
                    isDesktop && !usePanelLayout,
                  );
                }).toList(),
          );
        }
      },
    );
  }

  Widget _buildDetailPanel() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_selectedNotification == null) {
      return Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: theme.dividerColor, width: 1)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_outlined,
                size: 80,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              const Text('Select a notification'),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundImage:
                      _selectedNotification!.actorAvatar != null &&
                              _selectedNotification!.actorAvatar!.isNotEmpty
                          ? CachedNetworkImageProvider(
                            _selectedNotification!.actorAvatar!,
                          )
                          : null,
                  child:
                      _selectedNotification!.actorAvatar == null ||
                              _selectedNotification!.actorAvatar!.isEmpty
                          ? Icon(
                            _getNotificationIcon(_selectedNotification!.type),
                          )
                          : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getNotificationText(_selectedNotification!),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeago.format(_selectedNotification!.timestamp),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            if (_selectedNotification!.postId != null)
              OutlinedButton.icon(
                onPressed: () {
                  context.push(
                    '/post/${_selectedNotification!.postId}/comments',
                  );
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('View Post'),
              ),
            if (_selectedNotification!.actorId != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.push('/profile/${_selectedNotification!.actorId}');
                  },
                  icon: const Icon(Icons.person_outline),
                  label: const Text('View Profile'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.comment;
      case 'follow':
        return Icons.person_add;
      case 'mention':
        return Icons.alternate_email;
      case 'ripple':
        return Icons.waves;
      case 'dm':
        return Icons.message;
      default:
        return Icons.notifications;
    }
  }

  String _getNotificationText(AppNotification notification) {
    final actorName = notification.actorName ?? 'Someone';
    switch (notification.type) {
      case 'like':
        return '$actorName liked your post';
      case 'comment':
        return '$actorName commented on your post';
      case 'follow':
        return '$actorName started following you';
      case 'mention':
        return '$actorName mentioned you';
      case 'ripple':
        return '$actorName shared a ripple with you';
      case 'dm':
        return '$actorName sent you a message';
      default:
        return notification.message ?? 'New notification';
    }
  }

  Widget _buildNotificationItem(AppNotification notification, bool isDesktop) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isM3E = themeProvider.isM3EEnabled;
    final isSelected =
        isDesktop && _selectedNotification?.id == notification.id;

    return Card(
      margin: EdgeInsets.only(bottom: isM3E ? 8 : 12),
      color:
          notification.isRead
              ? (isM3E ? colorScheme.surfaceContainerLow : null)
              : (isM3E
                  ? colorScheme.secondaryContainer
                  : colorScheme.primaryContainer.withValues(alpha: 0.3)),
      elevation: isM3E ? 0 : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isM3E ? 20 : 12),
        side:
            isSelected
                ? BorderSide(color: colorScheme.primary, width: 2)
                : isM3E
                ? BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  width: 1,
                )
                : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: isM3E ? 16 : 16,
          vertical: isM3E ? 8 : 8,
        ),
        leading: Container(
          padding: isM3E ? EdgeInsets.all(2) : EdgeInsets.zero,
          decoration:
              isM3E && !notification.isRead
                  ? BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.primary, width: 2),
                  )
                  : null,
          child: CircleAvatar(
            radius: isM3E ? 22 : 24,
            backgroundImage:
                notification.actorAvatar != null &&
                        notification.actorAvatar!.isNotEmpty
                    ? CachedNetworkImageProvider(notification.actorAvatar!)
                    : null,
            backgroundColor: isM3E ? colorScheme.tertiaryContainer : null,
            child:
                notification.actorAvatar == null ||
                        notification.actorAvatar!.isEmpty
                    ? Icon(
                      _getNotificationIcon(notification.type),
                      size: isM3E ? 20 : 24,
                    )
                    : null,
          ),
        ),
        title: Text(
          _getNotificationText(notification),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight:
                notification.isRead
                    ? (isM3E ? FontWeight.w400 : FontWeight.normal)
                    : (isM3E ? FontWeight.w600 : FontWeight.w600),
          ),
        ),
        subtitle: Text(
          timeago.format(notification.timestamp),
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing:
            !notification.isRead
                ? Container(
                  width: isM3E ? 10 : 8,
                  height: isM3E ? 10 : 8,
                  decoration: BoxDecoration(
                    color: isM3E ? colorScheme.tertiary : colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow:
                        isM3E
                            ? [
                              BoxShadow(
                                color: colorScheme.tertiary.withValues(
                                  alpha: 0.4,
                                ),
                                blurRadius: 6,
                              ),
                            ]
                            : null,
                  ),
                )
                : null,
        onTap: () => _handleNotificationTap(notification),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _showUnreadOnly
                ? 'No unread notifications'
                : 'No notifications yet',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _showUnreadOnly
                ? 'You\'re all caught up!'
                : 'When you get notifications, they\'ll show up here',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
