// app_router.dart

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:navigation_bar_m3e/navigation_bar_m3e.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:oasis_v2/services/auth_service.dart';
import 'package:oasis_v2/services/screen_time_service.dart';
import 'package:oasis_v2/services/wellness_service.dart';
import 'package:oasis_v2/providers/user_settings_provider.dart';
import 'package:universal_io/io.dart';
import 'package:oasis_v2/screens/spaces/spaces_screen.dart';

import 'package:oasis_v2/features/circles/presentation/screens/circle_detail_screen.dart';
import 'package:oasis_v2/features/circles/presentation/screens/create_circle_screen.dart';
import 'package:oasis_v2/features/circles/presentation/screens/create_commitment_screen.dart';

import 'package:oasis_v2/screens/canvas/timeline_canvas_screen.dart';
import 'package:oasis_v2/screens/canvas/create_canvas_screen.dart';

import 'package:oasis_v2/screens/messages/direct_messages_screen.dart'
    as messages;
import 'package:oasis_v2/features/messages/presentation/screens/chat_screen.dart';
import 'package:oasis_v2/screens/messages/new_message_screen.dart';
import 'package:oasis_v2/providers/conversation_provider.dart';
import 'package:oasis_v2/services/app_initializer.dart';
import 'package:oasis_v2/screens/messages/active_call_screen.dart';
import 'package:oasis_v2/models/call.dart';
import 'package:oasis_v2/screens/notifications/notifications_screen.dart';
import 'package:oasis_v2/screens/settings_screen.dart';
import 'package:oasis_v2/screens/settings/subscription_screen.dart';
import 'package:oasis_v2/screens/settings/account_privacy_screen.dart';
import 'package:oasis_v2/screens/settings/two_factor_auth_screen.dart';
import 'package:oasis_v2/screens/settings/download_data_screen.dart';
import 'package:oasis_v2/screens/settings/storage_usage_screen.dart';
import 'package:oasis_v2/screens/settings/font_size_screen.dart';
import 'package:oasis_v2/screens/settings/help_support_screen.dart';
import 'package:oasis_v2/screens/moderation/moderation_screens.dart';
import 'package:oasis_v2/screens/story_view_screen.dart';
import 'package:oasis_v2/models/story_model.dart';
import '../features/auth/presentation/screens/login_screen.dart'
    as login_screen;
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/reset_password_screen.dart';
import '../features/feed/presentation/screens/feed_screen.dart';
import '../screens/search_screen.dart';
import '../features/feed/presentation/screens/create_post_screen.dart';
import '../features/feed/presentation/screens/comments_screen.dart';
import 'package:oasis_v2/features/feed/presentation/screens/post_details_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/profile/presentation/screens/edit_profile_screen.dart';
import '../features/profile/presentation/screens/followers_screen.dart';
import '../screens/legal/privacy_policy_screen.dart';
import '../screens/legal/terms_of_service_screen.dart';
import '../features/auth/presentation/screens/onboarding_screen.dart';
import '../features/capsules/presentation/screens/create_capsule_screen.dart';
import '../features/capsules/presentation/screens/capsule_view_screen.dart';
import '../features/circles/presentation/screens/circle_join_screen.dart';
import '../screens/stories/create_story_screen.dart';
import '../screens/ripples_screen.dart';
import '../screens/create_ripple_screen.dart';
import '../screens/oasis_pro_screen.dart';
import 'package:oasis_v2/core/utils/responsive_layout.dart';
import 'package:flutter_animate/flutter_animate.dart' as motion;

import 'package:oasis_v2/screens/settings/wellness_stats_screen.dart';

import 'package:oasis_v2/widgets/account_switcher_sheet.dart';

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

class MainLayout extends StatefulWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  /// Routes that are locked when the collaboration kill-switch or focus mode is active.
  static const _restrictedRoutes = {'/feed', '/search'};
  bool _isRailExtended = false;

  // Panel state for Desktop
  String? _activePanel; // 'search', 'notifications', or null

  int _getCurrentIndex() {
    final location = GoRouterState.of(context).uri.path;
    final screenTimeService = context.read<ScreenTimeService>();

    if (location.startsWith('/feed')) {
      screenTimeService.setCurrentCategory('Feed');
      return 0;
    }
    if (location.startsWith('/search')) {
      screenTimeService.setCurrentCategory('Feed'); // Search is discovery
      return 1;
    }
    if (location.startsWith('/spaces') ||
        location.startsWith('/circles') ||
        location.startsWith('/communities')) {
      screenTimeService.setCurrentCategory('Communities');
      return 2;
    }
    if (location.startsWith('/messages')) {
      screenTimeService.setCurrentCategory('Messages');
      return 3;
    }
    if (location.startsWith('/notifications')) {
      screenTimeService.setCurrentCategory(null);
      return 4;
    }
    if (location.startsWith('/profile')) {
      screenTimeService.setCurrentCategory('Profile');
      return 5;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isM3E = themeProvider.isM3EEnabled;
    final disableTransparency =
        isM3E && themeProvider.isM3ETransparencyDisabled;
    final currentIndex = _getCurrentIndex();
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Consumer3<ScreenTimeService, WellnessService, UserSettingsProvider>(
      builder: (context, svc, wellness, userSettings, _) {
        final killSwitchActive = wellness.focusModeEnabled;
        final isMica = userSettings.micaEnabled && Platform.isWindows;

        final panelColor =
            isMica
                ? Colors.black.withValues(alpha: 0.1)
                : (isM3E
                    ? theme.colorScheme.surfaceContainer
                    : const Color(0xFF0C0F14).withValues(alpha: 0.8));

        final slidingPanelColor =
            isMica
                ? Colors.black.withValues(alpha: 0.8)
                : (isM3E
                    ? theme.colorScheme.surfaceContainerHigh
                    : const Color(0xFF0C0F14));

        if (killSwitchActive) {
          final location = GoRouterState.of(context).uri.path;
          final isRestricted = _restrictedRoutes.any(
            (r) => location.startsWith(r),
          );
          if (isRestricted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) context.go('/messages');
            });
          }
        }

        if (isDesktop) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                // Background Main Content (Remains stable)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      SizedBox(width: (_isRailExtended ? 240 : 120) + 12),
                      Expanded(child: widget.child),
                    ],
                  ),
                ),

                // Dimmer/Dismiss Layer
                if (_activePanel != null)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () => setState(() => _activePanel = null),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.4),
                      ),
                    ),
                  ),

                // Navigation Rail
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    width: _isRailExtended ? 240 : 120,
                    decoration: BoxDecoration(
                      color:
                          disableTransparency
                              ? theme.colorScheme.surfaceContainer
                              : panelColor,
                      borderRadius: BorderRadius.circular(isM3E ? 32 : 12),
                      border: Border.all(
                        color:
                            isM3E
                                ? theme.colorScheme.outlineVariant.withValues(
                                  alpha: 0.3,
                                )
                                : Colors.white.withValues(alpha: 0.05),
                        width: isM3E ? 1 : 1,
                      ),
                      boxShadow:
                          isM3E && disableTransparency
                              ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 16,
                                  offset: const Offset(4, 0),
                                ),
                              ]
                              : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(isM3E ? 24 : 12),
                      child:
                          disableTransparency
                              ? _buildNavigationRail(
                                context,
                                currentIndex,
                                theme,
                                killSwitchActive: killSwitchActive,
                                isMica: isMica,
                                disableTransparency: disableTransparency,
                              )
                              : BackdropFilter(
                                filter: ui.ImageFilter.blur(
                                  sigmaX: isMica ? 0 : 10,
                                  sigmaY: isMica ? 0 : 10,
                                ),
                                child: _buildNavigationRail(
                                  context,
                                  currentIndex,
                                  theme,
                                  killSwitchActive: killSwitchActive,
                                  isMica: isMica,
                                  disableTransparency: disableTransparency,
                                ),
                              ),
                    ),
                  ),
                ),

                // Sliding Panels - Truly opaque now
                if (_activePanel != null)
                  Positioned(
                    top: 12,
                    bottom: 12,
                    left: (_isRailExtended ? 240 : 120) + 24,
                    child: motion.Animate(
                      effects: [
                        motion.MoveEffect(
                          begin: const Offset(-50, 0),
                          end: const Offset(0, 0),
                          curve: Curves.easeOutCubic,
                        ),
                        motion.FadeEffect(),
                      ],
                      child: Container(
                        width: 450,
                        decoration: BoxDecoration(
                          color: slidingPanelColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.6),
                              blurRadius: 60,
                              offset: const Offset(20, 0),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child:
                              _activePanel == 'search'
                                  ? const SearchScreen(isPanel: true)
                                  : const NotificationsScreen(isPanel: true),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            floatingActionButton: _buildFloatingActionButton(
              context,
              currentIndex,
              theme,
              killSwitchActive: killSwitchActive,
            ),
          );
        }

        // Mobile/Tablet layout with bottom navigation
        return Scaffold(
          extendBody: true,
          body: Stack(
            children: [
              AnimatedPadding(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.zero,
                child: widget.child,
              ),
            ],
          ),
          floatingActionButton: _buildFloatingActionButton(
            context,
            currentIndex,
            theme,
            killSwitchActive: killSwitchActive,
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: _buildBottomNavigationBar(
            context,
            currentIndex,
            theme,
            killSwitchActive: killSwitchActive,
          ),
        );
      },
    );
  }

  Widget? _buildFloatingActionButton(
    BuildContext context,
    int currentIndex,
    ThemeData theme, {
    required bool killSwitchActive,
  }) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    if (isDesktop) return null;
    final isM3E = Provider.of<ThemeProvider>(context).isM3EEnabled;

    if (currentIndex == 2) {
      // Spaces tab — no FAB needed, circles/canvas have their own buttons
      return null;
    } else if (currentIndex == 0 && !killSwitchActive) {
      // Feed tab FAB — hidden when kill-switch is active
      return FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder:
                (context) => Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.post_add, size: 28),
                        title: const Text('New Post'),
                        subtitle: const Text(
                          'Share a moment with your community',
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          context.pushNamed('create_post');
                        },
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        leading: const Icon(
                          FluentIcons.video_24_regular,
                          size: 28,
                        ),
                        title: const Text('New Ripple'),
                        subtitle: const Text('Share a short video ripple'),
                        onTap: () {
                          Navigator.pop(context);
                          context.pushNamed('create_ripple');
                        },
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        leading: const Icon(Icons.lock_clock, size: 28),
                        title: const Text('Time Capsule'),
                        subtitle: const Text('Seal a message for the future'),
                        onTap: () {
                          Navigator.pop(context);
                          context.pushNamed('create_capsule');
                        },
                      ),
                    ],
                  ),
                ),
          );
        },
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
        elevation: isM3E ? 3 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isM3E ? 16 : 28),
        ),
        child: Icon(
          Icons.add_rounded,
          color: theme.colorScheme.onPrimaryContainer,
          size: 28,
        ),
      );
    }
    return null;
  }

  Widget _buildBottomNavigationBar(
    BuildContext context,
    int currentIndex,
    ThemeData theme, {
    required bool killSwitchActive,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final disableTransparency =
        themeProvider.isM3EEnabled && themeProvider.isM3ETransparencyDisabled;

    // Indices 0 (Feed) and 1 (Search) are restricted when kill-switch is on.
    Widget restrictedIcon(Widget icon) =>
        killSwitchActive ? Opacity(opacity: 0.3, child: icon) : icon;

    final navBar = NavigationBarM3E(
      backgroundColor:
          disableTransparency
              ? theme.colorScheme.surfaceContainer
              : Colors.transparent,
      elevation: disableTransparency ? 3 : 0,
      selectedIndex: currentIndex,
      onDestinationSelected:
          (i) => _onDestinationSelected(i, killSwitchActive: killSwitchActive),
      labelBehavior: NavBarM3ELabelBehavior.alwaysShow,
      destinations: [
        NavigationDestinationM3E(
          icon: restrictedIcon(const Icon(FluentIcons.home_24_regular)),
          selectedIcon: restrictedIcon(const Icon(FluentIcons.home_24_filled)),
          label: 'Feed',
        ),
        NavigationDestinationM3E(
          icon: restrictedIcon(const Icon(FluentIcons.search_24_regular)),
          selectedIcon: restrictedIcon(
            const Icon(FluentIcons.search_24_filled),
          ),
          label: 'Search',
        ),
        NavigationDestinationM3E(
          icon: const Icon(FluentIcons.channel_24_regular),
          selectedIcon: const Icon(FluentIcons.channel_24_filled),
          label: 'Spaces',
        ),
        NavigationDestinationM3E(
          icon: const UnreadMessagesBadge(
            child: Icon(FluentIcons.chat_24_regular),
          ),
          selectedIcon: const UnreadMessagesBadge(
            child: Icon(FluentIcons.chat_24_filled),
          ),
          label: 'Messages',
        ),
        NavigationDestinationM3E(
          icon: const Icon(FluentIcons.alert_24_regular),
          selectedIcon: const Icon(FluentIcons.alert_24_filled),
          label: 'Alerts',
        ),
        NavigationDestinationM3E(
          icon: GestureDetector(
            onLongPress: () => AccountSwitcherSheet.show(context),
            child: const Icon(FluentIcons.person_24_regular),
          ),
          selectedIcon: GestureDetector(
            onLongPress: () => AccountSwitcherSheet.show(context),
            child: const Icon(FluentIcons.person_24_filled),
          ),
          label: 'Profile',
        ),
      ],
    );

    if (disableTransparency) {
      return navBar;
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(
          alpha: 0.7,
        ), // Semi-transparent tint
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: navBar,
        ),
      ),
    );
  }

  Widget _buildNavigationRail(
    BuildContext context,
    int currentIndex,
    ThemeData theme, {
    required bool killSwitchActive,
    bool isMica = false,
    bool disableTransparency = false,
  }) {
    final colorScheme = theme.colorScheme;

    Widget restrictedIcon(Widget icon) =>
        killSwitchActive ? Opacity(opacity: 0.3, child: icon) : icon;

    return NavigationRail(
      extended: _isRailExtended,
      selectedIndex: currentIndex,
      onDestinationSelected:
          (i) => _onDestinationSelected(i, killSwitchActive: killSwitchActive),
      labelType:
          _isRailExtended
              ? NavigationRailLabelType.none
              : NavigationRailLabelType.all,
      backgroundColor:
          disableTransparency
              ? theme.colorScheme.surface
              : (isMica ? Colors.transparent : const Color(0xFF0C0F14)),
      leading: Column(
        children: [
          const SizedBox(height: 8),
          IconButton(
            icon: Icon(_isRailExtended ? Icons.menu_open : Icons.menu),
            onPressed: () => setState(() => _isRailExtended = !_isRailExtended),
            color: colorScheme.onSurfaceVariant,
          ),
          if (_isRailExtended)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: _buildDesktopCreateButton(context, theme),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: GestureDetector(
                onTapDown:
                    (details) =>
                        _showCreateMenu(context, details.globalPosition, theme),
                child: IconButton.filled(
                  onPressed: () {}, // Handled by onTapDown for position
                  icon: const Icon(Icons.add_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    minimumSize: const Size(56, 56),
                  ),
                ),
              ),
            ),
        ],
      ),
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              onTap: () => context.go('/profile'),
              onLongPress: () => AccountSwitcherSheet.show(context),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(
                  Icons.person,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
        ),
      ),
      destinations: [
        NavigationRailDestination(
          icon: restrictedIcon(const Icon(FluentIcons.home_24_regular)),
          selectedIcon: restrictedIcon(const Icon(FluentIcons.home_24_filled)),
          label:
              killSwitchActive
                  ? const Text('Feed', style: TextStyle(color: Colors.grey))
                  : const Text('Feed'),
        ),
        NavigationRailDestination(
          icon: restrictedIcon(const Icon(FluentIcons.search_24_regular)),
          selectedIcon: restrictedIcon(
            const Icon(FluentIcons.search_24_filled),
          ),
          label:
              killSwitchActive
                  ? const Text('Search', style: TextStyle(color: Colors.grey))
                  : const Text('Search'),
        ),
        NavigationRailDestination(
          icon: const Icon(FluentIcons.channel_24_regular),
          selectedIcon: const Icon(FluentIcons.channel_24_filled),
          label: const Text('Spaces'),
        ),
        NavigationRailDestination(
          icon: const UnreadMessagesBadge(
            child: Icon(FluentIcons.chat_24_regular),
          ),
          selectedIcon: const UnreadMessagesBadge(
            child: Icon(FluentIcons.chat_24_filled),
          ),
          label: const Text('Messages'),
        ),
        NavigationRailDestination(
          icon: const Icon(FluentIcons.alert_24_regular),
          selectedIcon: const Icon(FluentIcons.alert_24_filled),
          label: const Text('Notifications'),
        ),
        NavigationRailDestination(
          icon: GestureDetector(
            onLongPress: () => AccountSwitcherSheet.show(context),
            child: const Icon(FluentIcons.person_24_regular),
          ),
          selectedIcon: GestureDetector(
            onLongPress: () => AccountSwitcherSheet.show(context),
            child: const Icon(FluentIcons.person_24_filled),
          ),
          label: const Text('Profile'),
        ),
      ],
    );
  }

  Widget _buildDesktopCreateButton(BuildContext context, ThemeData theme) {
    return GestureDetector(
      onTapDown:
          (details) => _showCreateMenu(context, details.globalPosition, theme),
      child: InkWell(
        onTap: () {}, // Handled by onTapDown
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text(
                'CREATE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateMenu(BuildContext context, Offset position, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        overlay.size.width - position.dx,
        overlay.size.height - position.dy,
      ),
      color:
          theme.brightness == Brightness.dark
              ? const Color(0xFF1A1D24)
              : Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      items: [
        PopupMenuItem(
          onTap: () {
            // Delay slightly to allow menu to close
            Future.delayed(const Duration(milliseconds: 10), () {
              if (context.mounted) context.pushNamed('create_post');
            });
          },
          child: Row(
            children: [
              Icon(
                Icons.post_add,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              const Text('New Post'),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: () {
            Future.delayed(const Duration(milliseconds: 10), () {
              if (context.mounted) context.pushNamed('create_ripple');
            });
          },
          child: Row(
            children: [
              Icon(
                FluentIcons.video_24_regular,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              const Text('New Ripple'),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: () {
            Future.delayed(const Duration(milliseconds: 10), () {
              if (context.mounted) context.pushNamed('create_capsule');
            });
          },
          child: Row(
            children: [
              Icon(
                Icons.lock_clock,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              const Text('Time Capsule'),
            ],
          ),
        ),
      ],
    );
  }

  void _onDestinationSelected(int index, {bool killSwitchActive = false}) {
    // Block interaction with Feed (0) and Search (1) when kill-switch is active.
    if (killSwitchActive && (index == 0 || index == 1)) return;

    final isDesktop = ResponsiveLayout.isDesktop(context);

    if (isDesktop) {
      if (index == 1) {
        // Search
        setState(() {
          _activePanel = _activePanel == 'search' ? null : 'search';
        });
        return;
      }
      if (index == 4) {
        // Notifications
        setState(() {
          _activePanel =
              _activePanel == 'notifications' ? null : 'notifications';
        });
        return;
      }
    }

    // Normal navigation for non-panel items or non-desktop
    switch (index) {
      case 0:
        context.go('/feed');
        break;
      case 1:
        context.go('/search');
        break;
      case 2:
        context.go('/spaces');
        break;
      case 3:
        context.go('/messages');
        break;
      case 4:
        context.go('/notifications');
        break;
      case 5:
        context.go('/profile');
        break;
    }
  }
}

class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> _shellNavigatorKey =
      GlobalKey<NavigatorState>();

  /// Routes that do NOT require authentication — unauthenticated users can visit
  /// them freely (the login wall doesn't apply).
  static bool _isPublicRoute(String path) {
    return path == '/login' ||
        path == '/register' ||
        path == '/splash' ||
        path == '/reset-password' || // accessible with a recovery session
        path ==
            '/set-password'; // accessible with a recovery session (for Google users)
  }

  /// Routes that a fully-authenticated user should be bounced away from
  /// (e.g. they are already logged in, so login/register are irrelevant).
  /// NOTE: /reset-password is intentionally excluded — a user with a
  /// password-recovery session must be allowed to reach this screen.
  static bool _isLoginOnlyRoute(String path) {
    return path == '/login' || path == '/register';
  }

  static GoRouter? _router;

  static GoRouter get router {
    _router ??= GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/feed',
      refreshListenable: AuthService(),
      debugLogDiagnostics: true,
      redirect: (context, state) async {
        // Password-reset screen is always reachable once Supabase sets the
        // recovery session — never redirect away from it automatically.
        if (state.uri.path == '/reset-password') return null;
        // Same for set-password screen
        if (state.uri.path == '/set-password') return null;

        // Check onboarding status
        final hasSeenOnboarding = await OnboardingScreen.hasSeenOnboarding();
        if (!hasSeenOnboarding && state.uri.path != '/onboarding') {
          return '/onboarding';
        }

        final authService = Provider.of<AuthService>(context, listen: false);
        final isLoggedIn = authService.currentUser != null;

        // Unauthenticated users trying to reach a protected route → login
        if (!isLoggedIn &&
            !_isPublicRoute(state.uri.path) &&
            state.uri.path != '/onboarding') {
          return '/login';
        }

        // Authenticated users trying to reach login/register → feed
        if (isLoggedIn && _isLoginOnlyRoute(state.uri.path)) {
          // Allow if specifically adding a new account
          if (state.uri.queryParameters['add_account'] == 'true') {
            return null;
          }
          return '/feed';
        }

        return null;
      },
      routes: [
        // Auth Routes
        GoRoute(
          path: '/login',
          name: 'login',
          pageBuilder:
              (context, state) => MaterialPage(
                key: state.pageKey,
                child: const login_screen.LoginScreen(),
              ),
        ),
        GoRoute(
          path: '/register',
          name: 'register',
          pageBuilder:
              (context, state) => MaterialPage(
                key: state.pageKey,
                child: const RegisterScreen(),
              ),
        ),
        GoRoute(
          path: '/reset-password',
          name: 'reset_password',
          pageBuilder:
              (context, state) => MaterialPage(
                key: state.pageKey,
                child: const ResetPasswordScreen(),
              ),
        ),

        // Set Password (for Google users who want to set a password)
        GoRoute(
          path: '/set-password',
          name: 'set_password',
          pageBuilder:
              (context, state) => MaterialPage(
                key: state.pageKey,
                child: const ResetPasswordScreen(),
              ),
        ),

        // Main App Shell (Tab Navigation)
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) => MainLayout(child: child),
          routes: [
            // Feed Screen
            GoRoute(
              path: '/feed',
              name: 'feed',
              pageBuilder:
                  (context, state) =>
                      const NoTransitionPage(child: FeedScreen()),
            ),

            // Search Screen
            GoRoute(
              path: '/search',
              name: 'search',
              pageBuilder:
                  (context, state) =>
                      const NoTransitionPage(child: SearchScreen()),
            ),

            // Communities Screen
            GoRoute(
              path: '/spaces',
              name: 'spaces',
              pageBuilder:
                  (context, state) =>
                      const NoTransitionPage(child: SpacesScreen()),
              routes: [
                GoRoute(
                  path: 'circles/create',
                  name: 'create_circle',
                  parentNavigatorKey: _rootNavigatorKey,
                  pageBuilder:
                      (context, state) => const MaterialPage(
                        fullscreenDialog: true,
                        child: CreateCircleScreen(),
                      ),
                ),
                GoRoute(
                  path: 'canvas/create',
                  name: 'create_canvas',
                  parentNavigatorKey: _rootNavigatorKey,
                  pageBuilder:
                      (context, state) => const MaterialPage(
                        fullscreenDialog: true,
                        child: CreateCanvasScreen(),
                      ),
                ),
                GoRoute(
                  path: 'circles/:circleId',
                  name: 'circle_detail',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final id = state.pathParameters['circleId']!;
                    return CircleDetailScreen(circleId: id);
                  },
                  routes: [
                    GoRoute(
                      path: 'add-commitment',
                      name: 'create_commitment',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) {
                        final id = state.pathParameters['circleId']!;
                        return CreateCommitmentScreen(circleId: id);
                      },
                    ),
                  ],
                ),
                GoRoute(
                  path: 'canvas/:canvasId',
                  name: 'canvas_detail',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final id = state.pathParameters['canvasId']!;
                    return TimelineCanvasScreen(canvasId: id);
                  },
                ),
              ],
            ),

            // Direct Messages Screen
            GoRoute(
              path: '/messages',
              name: 'messages',
              pageBuilder:
                  (context, state) => const NoTransitionPage(
                    child: messages.DirectMessagesScreen(),
                  ),
              routes: [
                GoRoute(
                  path: ':conversationId',
                  name: 'chat_nested',
                  parentNavigatorKey: _rootNavigatorKey,
                  pageBuilder: (context, state) {
                    final conversationId =
                        state.pathParameters['conversationId']!;
                    final extra = state.extra as Map<String, dynamic>?;

                    final isDesktop = MediaQuery.of(context).size.width >= 1000;

                    if (isDesktop) {
                      // On Desktop, navigate to messages with the conversation selected
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (context.mounted) {
                          context.go(
                            '/messages',
                            extra: {
                              'initialConversationId': conversationId,
                              ...?extra,
                            },
                          );
                        }
                      });
                      return const NoTransitionPage(
                        child: messages.DirectMessagesScreen(),
                      );
                    } else {
                      // On Mobile, push the dedicated ChatScreen with full height (no navbar)
                      return MaterialPage(
                        child: ChatScreen(
                          conversationId: conversationId,
                          otherUserName: extra?['otherUserName'],
                          otherUserAvatar: extra?['otherUserAvatar'],
                          otherUserId: extra?['otherUserId'],
                        ),
                      );
                    }
                  },
                ),
              ],
            ),

            // Notifications Screen
            GoRoute(
              path: '/notifications',
              name: 'notifications',
              pageBuilder:
                  (context, state) =>
                      const NoTransitionPage(child: NotificationsScreen()),
            ),

            // Profile Screen
            GoRoute(
              path: '/profile',
              name: 'profile',
              pageBuilder:
                  (context, state) =>
                      const NoTransitionPage(child: ProfileScreen()),
            ),
          ],
        ),

        // Ripples Screen (Full screen, no bottom nav)
        GoRoute(
          path: '/ripples',
          name: 'ripples',
          pageBuilder:
              (context, state) => const MaterialPage(
                key: ValueKey('ripples_screen'),
                fullscreenDialog: true,
                child: RipplesScreen(),
              ),
        ),

        // Create Ripple Screen
        GoRoute(
          path: '/create-ripple',
          name: 'create_ripple',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) {
            return MaterialPage(
              key: state.pageKey,
              fullscreenDialog: true,
              child: const CreateRippleScreen(),
            );
          },
        ),

        // Oasis Pro Screen
        GoRoute(
          path: '/oasis-pro',
          name: 'oasis_pro',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) {
            return MaterialPage(
              key: state.pageKey,
              fullscreenDialog: true,
              child: const OasisProScreen(),
            );
          },
        ),

        // Integrated Call Screen
        GoRoute(
          path: '/call/:callId',
          name: 'active_call',
          pageBuilder: (context, state) {
            final call = state.extra as Call;
            return MaterialPage(
              key: state.pageKey,
              fullscreenDialog: true,
              child: ActiveCallScreen(call: call),
            );
          },
        ),

        // Create Post Modal
        GoRoute(
          path: '/create-post',
          name: 'create_post',
          pageBuilder: (context, state) {
            final communityId = state.extra as String?;
            return MaterialPage(
              key: state.pageKey,
              fullscreenDialog: true,
              child: CreatePostScreen(communityId: communityId),
            );
          },
        ),

        // Create Time Capsule Modal
        GoRoute(
          path: '/create-capsule',
          name: 'create_capsule',
          pageBuilder: (context, state) {
            return MaterialPage(
              key: state.pageKey,
              fullscreenDialog: true,
              child: const CreateCapsuleScreen(),
            );
          },
        ),

        // View Time Capsule (Deep Link)
        GoRoute(
          path: '/capsule/:capsuleId',
          name: 'view_capsule',
          builder: (context, state) {
            final id = state.pathParameters['capsuleId']!;
            return CapsuleViewScreen(capsuleId: id);
          },
        ),

        // Join Circle (Deep Link)
        GoRoute(
          path: '/circle/join/:circleId',
          name: 'join_circle',
          builder: (context, state) {
            final id = state.pathParameters['circleId']!;
            return CircleJoinScreen(circleId: id);
          },
        ),

        // Create Story Screen
        GoRoute(
          path: '/stories/create',
          name: 'create_story',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) {
            return MaterialPage(
              key: state.pageKey,
              fullscreenDialog: true,
              child: const CreateStoryScreen(),
            );
          },
        ),

        // Post Details Screen (Feed View)
        GoRoute(
          path: '/post/:postId',
          name: 'post_details',
          pageBuilder: (context, state) {
            final postId = state.pathParameters['postId']!;
            return MaterialPage(
              key: state.pageKey,
              child: PostDetailsScreen(postId: postId),
            );
          },
        ),

        // Comments Screen
        GoRoute(
          path: '/post/:postId/comments',
          name: 'comments',
          pageBuilder: (context, state) {
            final postId = state.pathParameters['postId']!;
            return MaterialPage(
              key: state.pageKey,
              child: CommentsScreen(postId: postId),
            );
          },
        ),

        // Edit Profile Screen
        GoRoute(
          path: '/edit-profile',
          name: 'edit_profile',
          pageBuilder:
              (context, state) => MaterialPage(
                key: state.pageKey,
                child: const EditProfileScreen(),
              ),
        ),

        // Settings Screen
        GoRoute(
          path: '/settings',
          name: 'settings',
          pageBuilder:
              (context, state) => MaterialPage(
                key: state.pageKey,
                child: const SettingsScreen(),
              ),
        ),

        // Subscription Screen
        GoRoute(
          path: '/subscription',
          name: 'subscription',
          pageBuilder:
              (context, state) => MaterialPage(
                key: state.pageKey,
                child: const SubscriptionScreen(),
              ),
        ),
        GoRoute(
          path: '/settings/account-privacy',
          name: 'account_privacy',
          pageBuilder:
              (context, state) => MaterialPage(
                key: state.pageKey,
                child: const AccountPrivacyScreen(),
              ),
        ),
        GoRoute(
          path: '/settings/blocked-users',
          name: 'blocked_users',
          pageBuilder:
              (context, state) => MaterialPage(
                key: state.pageKey,
                child: const BlockedUsersScreen(),
              ),
        ),
        GoRoute(
          path: '/settings/two-factor-auth',
          name: 'two_factor_auth',
          pageBuilder:
              (context, state) => MaterialPage(
                key: state.pageKey,
                child: const TwoFactorAuthScreen(),
              ),
        ),
        GoRoute(
          path: '/settings/download-data',
          name: 'download_data',
          pageBuilder:
              (context, state) => MaterialPage(
                key: state.pageKey,
                child: const DownloadDataScreen(),
              ),
        ),
        GoRoute(
          path: '/settings/storage-usage',
          name: 'storage_usage',
          pageBuilder:
              (context, state) => MaterialPage(
                key: state.pageKey,
                child: const StorageUsageScreen(),
              ),
        ),
        GoRoute(
          path: '/settings/font-size',
          name: 'font_size',
          pageBuilder:
              (context, state) => MaterialPage(
                key: state.pageKey,
                child: const FontSizeScreen(),
              ),
        ),
        GoRoute(
          path: '/settings/help-support',
          name: 'help_support',
          pageBuilder:
              (context, state) => MaterialPage(
                key: state.pageKey,
                child: const HelpSupportScreen(),
              ),
        ),

        // Story View Screen
        GoRoute(
          path: '/story/:storyId',
          name: 'story_view',
          pageBuilder: (context, state) {
            final storyId = state.pathParameters['storyId']!;
            final stories = state.extra as List<StoryModel>;
            return CustomTransitionPage(
              key: state.pageKey,
              child: StoryViewScreen(initialStoryId: storyId, stories: stories),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return FadeTransition(opacity: animation, child: child);
              },
            );
          },
        ),

        GoRoute(
          path: '/wellness-stats',
          name: 'wellness_stats',
          pageBuilder:
              (context, state) =>
                  const MaterialPage(child: WellnessStatsScreen()),
        ),
        // User Profile Screen (for viewing others)
        GoRoute(
          path: '/profile/:userId',
          name: 'user_profile',
          pageBuilder: (context, state) {
            final userId = state.pathParameters['userId']!;
            return MaterialPage(
              key: state.pageKey,
              child: ProfileScreen(userId: userId),
            );
          },
        ),

        // Followers/Following Screen
        GoRoute(
          path: '/profile/:userId/followers',
          name: 'followers',
          pageBuilder: (context, state) {
            final userId = state.pathParameters['userId']!;
            return MaterialPage(
              key: state.pageKey,
              child: FollowersScreen(userId: userId, initialTab: 0),
            );
          },
        ),
        GoRoute(
          path: '/profile/:userId/following',
          name: 'following',
          pageBuilder: (context, state) {
            final userId = state.pathParameters['userId']!;
            return MaterialPage(
              key: state.pageKey,
              child: FollowersScreen(userId: userId, initialTab: 1),
            );
          },
        ), // New Message Screen
        GoRoute(
          path: '/new-message',
          name: 'new_message',
          pageBuilder:
              (context, state) => MaterialPage(
                key: state.pageKey,
                child: const NewMessageScreen(),
              ),
        ),

        // Legal Screens
        GoRoute(
          path: '/privacy-policy',
          name: 'privacy_policy',
          pageBuilder:
              (context, state) => MaterialPage(
                key: state.pageKey,
                child: const PrivacyPolicyScreen(),
              ),
        ),
        GoRoute(
          path: '/terms-of-service',
          name: 'terms_of_service',
          pageBuilder:
              (context, state) => MaterialPage(
                key: state.pageKey,
                child: const TermsOfServiceScreen(),
              ),
        ),

        // Onboarding Screen
        GoRoute(
          path: '/onboarding',
          name: 'onboarding',
          pageBuilder:
              (context, state) => MaterialPage(
                key: state.pageKey,
                child: const OnboardingScreen(),
              ),
        ),
      ],
    );
    return _router!;
  }
}
