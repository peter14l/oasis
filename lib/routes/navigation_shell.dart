import 'package:flutter/material.dart' as material;
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:oasis/core/utils/responsive_layout.dart';
import 'package:oasis/providers/conversation_provider.dart';
import 'package:oasis/services/app_initializer.dart';

/// Navigation shell with bottom navigation bar
class NavigationShell extends material.StatelessWidget {
  final material.Widget child;
  final int currentIndex;

  const NavigationShell({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  @override
  material.Widget build(material.BuildContext context) {
    final theme = material.Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isM3E = themeProvider.isM3EEnabled;
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final useFluent = themeProvider.useFluentUI;

    // Get unread count
    final unreadCount = context.watch<ConversationProvider>().totalUnreadCount;

    if (useFluent) {
      return _buildFluentLayout(context, themeProvider, unreadCount);
    }

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

  material.Widget _buildFluentLayout(
    material.BuildContext context,
    ThemeProvider themeProvider,
    int unreadCount,
  ) {
    return fluent.NavigationView(
      titleBar: fluent.TitleBar(
        title: const fluent.Text('Oasis'),
        actions: material.Row(
          mainAxisAlignment: material.MainAxisAlignment.end,
          children: [
            fluent.Tooltip(
              message: 'Search',
              child: fluent.IconButton(
                icon: const material.Icon(
                  FluentIcons.search_24_regular,
                  size: 20,
                ),
                onPressed: () => context.go('/search'),
              ),
            ),
            const material.SizedBox(width: 12),
          ],
        ),
      ),
      pane: fluent.NavigationPane(
        selected: currentIndex,
        onChanged: (index) => _onDestinationSelected(context, index),
        displayMode: fluent.PaneDisplayMode.auto,
        items: [
          fluent.PaneItem(
            icon: const material.Icon(FluentIcons.home_24_regular),
            selectedIcon: const material.Icon(FluentIcons.home_24_filled),
            title: const fluent.Text('Feed'),
            body: child,
          ),
          fluent.PaneItem(
            icon: const material.Icon(FluentIcons.people_24_regular),
            selectedIcon: const material.Icon(FluentIcons.people_24_filled),
            title: const fluent.Text('Circles'),
            body: child,
          ),
          fluent.PaneItem(
            icon: fluent.InfoBadge(
              source:
                  unreadCount > 0 ? fluent.Text(unreadCount.toString()) : null,
              child: const material.Icon(FluentIcons.chat_24_regular),
            ),
            selectedIcon: fluent.InfoBadge(
              source:
                  unreadCount > 0 ? fluent.Text(unreadCount.toString()) : null,
              child: const material.Icon(FluentIcons.chat_24_filled),
            ),
            title: const fluent.Text('Messages'),
            body: child,
          ),
          fluent.PaneItem(
            icon: const material.Icon(FluentIcons.alert_24_regular),
            selectedIcon: const material.Icon(FluentIcons.alert_24_filled),
            title: const fluent.Text('Alerts'),
            body: child,
          ),
        ],
        footerItems: [
          fluent.PaneItem(
            icon: const material.Icon(FluentIcons.person_24_regular),
            title: const fluent.Text('Profile'),
            body: child,
            onTap: () => context.go('/profile'),
          ),
          fluent.PaneItem(
            icon: const material.Icon(FluentIcons.settings_24_regular),
            title: const fluent.Text('Settings'),
            body: child,
            onTap: () => context.go('/settings'),
          ),
        ],
      ),
    );
  }

  material.Widget _buildMobileLayout(
    material.BuildContext context,
    material.ThemeData theme,
    ThemeProvider themeProvider,
    bool isM3E,
    int unreadCount,
  ) {
    return material.Scaffold(
      body: child,
      bottomNavigationBar: material.NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected:
            (index) => _onDestinationSelected(context, index),
        destinations: [
          const material.NavigationDestination(
            icon: material.Icon(FluentIcons.home_24_regular),
            selectedIcon: material.Icon(FluentIcons.home_24_filled),
            label: 'Feed',
          ),
          const material.NavigationDestination(
            icon: material.Icon(FluentIcons.search_24_regular),
            selectedIcon: material.Icon(FluentIcons.search_24_filled),
            label: 'Search',
          ),
          const material.NavigationDestination(
            icon: material.Icon(FluentIcons.people_24_regular),
            selectedIcon: material.Icon(FluentIcons.people_24_filled),
            label: 'Circles',
          ),
          material.NavigationDestination(
            icon: material.Badge(
              isLabelVisible: unreadCount > 0,
              label: material.Text(unreadCount > 99 ? '99+' : unreadCount.toString()),
              child: const material.Icon(FluentIcons.chat_24_regular),
            ),
            selectedIcon: material.Badge(
              isLabelVisible: unreadCount > 0,
              label: material.Text(unreadCount > 99 ? '99+' : unreadCount.toString()),
              child: const material.Icon(FluentIcons.chat_24_filled),
            ),
            label: 'Messages',
          ),
          const material.NavigationDestination(
            icon: material.Icon(FluentIcons.alert_24_regular),
            selectedIcon: material.Icon(FluentIcons.alert_24_filled),
            label: 'Alerts',
          ),
        ],
      ),
    );
  }

  material.Widget _buildDesktopLayout(
    material.BuildContext context,
    material.ThemeData theme,
    ThemeProvider themeProvider,
    bool isM3E,
  ) {
    return material.Scaffold(
      body: material.Row(
        children: [
          material.NavigationRail(
            selectedIndex: currentIndex,
            onDestinationSelected:
                (index) => _onDestinationSelected(context, index),
            labelType: material.NavigationRailLabelType.all,
            destinations: const [
              material.NavigationRailDestination(
                icon: material.Icon(FluentIcons.home_24_regular),
                selectedIcon: material.Icon(FluentIcons.home_24_filled),
                label: material.Text('Feed'),
              ),
              material.NavigationRailDestination(
                icon: material.Icon(FluentIcons.search_24_regular),
                selectedIcon: material.Icon(FluentIcons.search_24_filled),
                label: material.Text('Search'),
              ),
              material.NavigationRailDestination(
                icon: material.Icon(FluentIcons.people_24_regular),
                selectedIcon: material.Icon(FluentIcons.people_24_filled),
                label: material.Text('Circles'),
              ),
              material.NavigationRailDestination(
                icon: material.Icon(FluentIcons.chat_24_regular),
                selectedIcon: material.Icon(FluentIcons.chat_24_filled),
                label: material.Text('Messages'),
              ),
              material.NavigationRailDestination(
                icon: material.Icon(FluentIcons.alert_24_regular),
                selectedIcon: material.Icon(FluentIcons.alert_24_filled),
                label: material.Text('Alerts'),
              ),
            ],
          ),
          const material.VerticalDivider(thickness: 1, width: 1),
          material.Expanded(child: child),
        ],
      ),
    );
  }

  void _onDestinationSelected(material.BuildContext context, int index) {
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
class UnreadMessagesBadge extends material.StatelessWidget {
  final material.Widget child;
  final bool isSelected;

  const UnreadMessagesBadge({
    super.key,
    required this.child,
    this.isSelected = false,
  });

  @override
  material.Widget build(material.BuildContext context) {
    return Consumer<ConversationProvider>(
      builder: (context, provider, _) {
        return material.Badge(
          isLabelVisible: provider.totalUnreadCount > 0,
          label: material.Text(provider.totalUnreadCount.toString()),
          child: child,
        );
      },
    );
  }
}
