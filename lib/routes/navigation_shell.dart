import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:oasis/core/utils/responsive_layout.dart';
import 'package:oasis/providers/conversation_provider.dart';
import 'package:oasis/services/app_initializer.dart';

/// Navigation shell with bottom navigation bar
class NavigationShell extends StatelessWidget {
  final Widget child;
  final int currentIndex;

  const NavigationShell({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isM3E = themeProvider.isM3EEnabled;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    // Get unread count
    final unreadCount = context.watch<ConversationProvider>().totalUnreadCount;

    if (isDesktop) {
      return _buildDesktopLayout(context, theme, themeProvider, isM3E);
    }

    return _buildMobileLayout(
      context,
      theme,
      themeProvider,
      isM3E,
      unreadCount,
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    ThemeData theme,
    ThemeProvider themeProvider,
    bool isM3E,
    int unreadCount,
  ) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected:
            (index) => _onDestinationSelected(context, index),
        destinations: [
          const NavigationDestination(
            icon: Icon(FluentIcons.home_24_regular),
            selectedIcon: Icon(FluentIcons.home_24_filled),
            label: 'Feed',
          ),
          const NavigationDestination(
            icon: Icon(FluentIcons.search_24_regular),
            selectedIcon: Icon(FluentIcons.search_24_filled),
            label: 'Search',
          ),
          const NavigationDestination(
            icon: Icon(FluentIcons.people_24_regular),
            selectedIcon: Icon(FluentIcons.people_24_filled),
            label: 'Circles',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text(unreadCount > 99 ? '99+' : unreadCount.toString()),
              child: const Icon(FluentIcons.chat_24_regular),
            ),
            selectedIcon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text(unreadCount > 99 ? '99+' : unreadCount.toString()),
              child: const Icon(FluentIcons.chat_24_filled),
            ),
            label: 'Messages',
          ),
          const NavigationDestination(
            icon: Icon(FluentIcons.alert_24_regular),
            selectedIcon: Icon(FluentIcons.alert_24_filled),
            label: 'Alerts',
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    ThemeData theme,
    ThemeProvider themeProvider,
    bool isM3E,
  ) {
    // Desktop layout - could use NavigationRail
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: currentIndex,
            onDestinationSelected:
                (index) => _onDestinationSelected(context, index),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(FluentIcons.home_24_regular),
                selectedIcon: Icon(FluentIcons.home_24_filled),
                label: Text('Feed'),
              ),
              NavigationRailDestination(
                icon: Icon(FluentIcons.search_24_regular),
                selectedIcon: Icon(FluentIcons.search_24_filled),
                label: Text('Search'),
              ),
              NavigationRailDestination(
                icon: Icon(FluentIcons.people_24_regular),
                selectedIcon: Icon(FluentIcons.people_24_filled),
                label: Text('Circles'),
              ),
              NavigationRailDestination(
                icon: Icon(FluentIcons.chat_24_regular),
                selectedIcon: Icon(FluentIcons.chat_24_filled),
                label: Text('Messages'),
              ),
              NavigationRailDestination(
                icon: Icon(FluentIcons.alert_24_regular),
                selectedIcon: Icon(FluentIcons.alert_24_filled),
                label: Text('Alerts'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }

  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/feed');
        break;
      case 1:
        context.go('/search');
        break;
      case 2:
        context.go('/circles');
        break;
      case 3:
        context.go('/messages');
        break;
      case 4:
        context.go('/notifications');
        break;
    }
  }
}

/// Badge widget for unread messages (extracted from app_router.dart)
class UnreadMessagesBadge extends StatelessWidget {
  final Widget child;
  final bool isSelected;

  const UnreadMessagesBadge({
    super.key,
    required this.child,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ConversationProvider>(
      builder: (context, provider, _) {
        return Badge(
          isLabelVisible: provider.totalUnreadCount > 0,
          label: Text(provider.totalUnreadCount.toString()),
          child: child,
        );
      },
    );
  }
}
