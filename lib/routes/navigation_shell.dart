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
    // 5-tab Fluent layout with working icons
    return fluent.NavigationView(
      pane: fluent.NavigationPane(
        selected: currentIndex,
        size: const fluent.NavigationPaneSize(
          compactWidth: 54,
        ),
        onChanged: (index) => _onDestinationSelected(context, index),
        displayMode: fluent.PaneDisplayMode.auto,
        items: [
          fluent.PaneItem(
            icon: const material.Icon(FluentIcons.home_24_regular),
            selectedIcon: const material.Icon(FluentIcons.home_24_filled),
            title: const Text('Canvas'),
            body: material.SizedBox.shrink(),
          ),
          fluent.PaneItem(
            icon: const material.Icon(FluentIcons.box_24_regular),
            selectedIcon: const material.Icon(FluentIcons.box_24_filled),
            title: const Text('Vault'),
            body: material.SizedBox.shrink(),
          ),
          // COMMENTED OUT: Wellness tab - removed per user request (2026-04-28)
          // fluent.PaneItem(
          //   icon: const material.Icon(FluentIcons.leaf_one_24_regular),
          //   selectedIcon: const material.Icon(FluentIcons.leaf_one_24_filled),
          //   title: const Text('Wellness'),
          //   body: material.SizedBox.shrink(),
          // ),
          fluent.PaneItem(
            icon: _buildUnreadIcon(FluentIcons.chat_24_regular, unreadCount),
            selectedIcon: _buildUnreadIcon(FluentIcons.chat_24_filled, unreadCount),
            title: const Text('Messages'),
            body: material.SizedBox.shrink(),
          ),
        ],
        footerItems: [
          fluent.PaneItem(
            icon: const material.Icon(FluentIcons.person_24_regular),
            title: const Text('Profile'),
            body: material.SizedBox.shrink(),
            onTap: () => context.go('/profile'),
          ),
          fluent.PaneItem(
            icon: const material.Icon(FluentIcons.settings_24_regular),
            title: const Text('Settings'),
            body: material.SizedBox.shrink(),
            onTap: () => context.go('/settings'),
          ),
        ],
      ),
      content: child,
    );
  }

  material.Widget _buildUnreadIcon(IconData icon, int unreadCount) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        material.Icon(icon),
        if (unreadCount > 0)
          Positioned(
            top: -2,
            right: -2,
            child: fluent.InfoBadge(
              source: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: const TextStyle(fontSize: 8, color: material.Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  material.Widget _buildMobileLayout(
    material.BuildContext context,
    material.ThemeData theme,
    ThemeProvider themeProvider,
    bool isM3E,
    int unreadCount,
  ) {
    // 4-tab Mobile layout: Canvas (Home), Vault, Messages, Profile - Wellness removed (2026-04-28)
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
            label: 'Canvas',
          ),
          const material.NavigationDestination(
            icon: material.Icon(FluentIcons.box_24_regular),
            selectedIcon: material.Icon(FluentIcons.box_24_filled),
            label: 'Vault',
          ),
          // COMMENTED OUT: Wellness tab - removed per user request (2026-04-28)
          // const material.NavigationDestination(
          //   icon: material.Icon(FluentIcons.leaf_one_24_regular),
          //   selectedIcon: material.Icon(FluentIcons.leaf_one_24_filled),
          //   label: 'Wellness',
          // ),
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
            icon: material.Icon(FluentIcons.person_24_regular),
            selectedIcon: material.Icon(FluentIcons.person_24_filled),
            label: 'Profile',
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
    // 4-tab Desktop layout - Wellness removed (2026-04-28)
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
                label: material.Text('Canvas'),
              ),
              material.NavigationRailDestination(
                icon: material.Icon(FluentIcons.box_24_regular),
                selectedIcon: material.Icon(FluentIcons.box_24_filled),
                label: material.Text('Vault'),
              ),
              // COMMENTED OUT: Wellness tab - removed per user request (2026-04-28)
              // material.NavigationRailDestination(
              //   icon: material.Icon(FluentIcons.leaf_one_24_regular),
              //   selectedIcon: material.Icon(FluentIcons.leaf_one_24_filled),
              //   label: material.Text('Wellness'),
              // ),
              material.NavigationRailDestination(
                icon: material.Icon(FluentIcons.chat_24_regular),
                selectedIcon: material.Icon(FluentIcons.chat_24_filled),
                label: material.Text('Messages'),
              ),
              material.NavigationRailDestination(
                icon: material.Icon(FluentIcons.person_24_regular),
                selectedIcon: material.Icon(FluentIcons.person_24_filled),
                label: material.Text('Profile'),
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
    // Unfocus to prevent keyboard state sync issues
    material.FocusManager.instance.primaryFocus?.unfocus();

    // 4-tab mapping: Canvas(0), Vault(1), Messages(2), Profile(3) - Wellness removed (2026-04-28)
    switch (index) {
      case 0:
        context.go('/spaces');
        break;
      case 1:
        context.go('/vault');
        break;
      case 2:
        context.go('/messages');
        break;
      case 3:
        context.go('/profile');
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
    final useFluent = Provider.of<ThemeProvider>(context).useFluentUI;

    return Consumer<ConversationProvider>(
      builder: (context, provider, _) {
        final count = provider.totalUnreadCount;
        if (useFluent) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              child,
              if (count > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: fluent.InfoBadge(
                    source: Text(
                      count > 99 ? '99+' : count.toString(),
                      style: const TextStyle(fontSize: 8, color: material.Colors.white),
                    ),
                  ),
                ),
            ],
          );
        }
        return material.Badge(
          isLabelVisible: count > 0,
          label: material.Text(count.toString()),
          child: child,
        );
      },
    );
  }
}
