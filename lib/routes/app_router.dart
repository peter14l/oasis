// app_router.dart

import 'dart:ui' as imageUrl;
import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:navigation_bar_m3e/navigation_bar_m3e.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:morrow_v2/services/auth_service.dart';
import 'package:morrow_v2/screens/community/communities_screen.dart';
import 'package:morrow_v2/screens/community/community_detail_screen.dart';
import 'package:morrow_v2/screens/community/community_name_theme_screen.dart';
import 'package:morrow_v2/screens/community/community_guidelines_screen.dart';
import 'package:morrow_v2/screens/community/community_description_rules_screen.dart';
import 'package:morrow_v2/screens/community/community_privacy_moderation_screen.dart';
import 'package:morrow_v2/screens/community/community_setup_confirmation_screen.dart';
import 'package:morrow_v2/screens/messages/direct_messages_screen.dart'
    as messages;
import 'package:morrow_v2/screens/messages/chat_screen.dart';
import 'package:morrow_v2/screens/messages/new_message_screen.dart';
import 'package:morrow_v2/screens/notifications/notifications_screen.dart';
import 'package:morrow_v2/screens/settings_screen.dart';
import 'package:morrow_v2/screens/settings/subscription_screen.dart';
import 'package:morrow_v2/screens/settings/account_privacy_screen.dart';
import 'package:morrow_v2/screens/settings/two_factor_auth_screen.dart';
import 'package:morrow_v2/screens/settings/download_data_screen.dart';
import 'package:morrow_v2/screens/settings/storage_usage_screen.dart';
import 'package:morrow_v2/screens/settings/font_size_screen.dart';
import 'package:morrow_v2/screens/settings/help_support_screen.dart';
import 'package:morrow_v2/screens/moderation/moderation_screens.dart';
import 'package:morrow_v2/screens/story_view_screen.dart';
import 'package:morrow_v2/models/story_model.dart';
import 'package:morrow_v2/screens/login_screen.dart' as login_screen;
import '../screens/register_screen.dart';
import '../screens/reset_password_screen.dart';
import '../screens/feed_screen.dart';
import '../screens/search_screen.dart';
import '../screens/create_post_screen.dart';
import '../screens/comments_screen.dart';
import 'package:morrow_v2/screens/post_details_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/followers_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/legal/privacy_policy_screen.dart';
import '../screens/legal/terms_of_service_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/capsules/create_capsule_screen.dart';
import 'package:morrow_v2/services/screen_time_service.dart';
import 'package:morrow_v2/widgets/wellbeing_break_overlay.dart';

class MainLayout extends StatefulWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  /// Routes that are locked when the collaboration kill-switch is active.
  static const _restrictedRoutes = {'/feed', '/search'};

  int _getCurrentIndex() {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/feed')) return 0;
    if (location.startsWith('/search')) return 1;
    if (location.startsWith('/communities')) return 2;
    if (location.startsWith('/messages')) return 3;
    if (location.startsWith('/notifications')) return 4;
    if (location.startsWith('/profile')) return 5;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentIndex = _getCurrentIndex();
    final isDesktop = MediaQuery.of(context).size.width >= 1200;

    return Consumer<ScreenTimeService>(
      builder: (context, svc, _) {
        final killSwitchActive = svc.isKillSwitchActive;

        // Auto-redirect away from restricted routes when kill-switch fires.
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
            body: Stack(
              children: [
                Row(
                  children: [
                    _buildNavigationRail(
                      context,
                      currentIndex,
                      theme,
                      killSwitchActive: killSwitchActive,
                    ),
                    Expanded(child: widget.child),
                  ],
                ),
                if (killSwitchActive)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: WellbeingBreakOverlay(
                      onReset: () => svc.resetKillSwitch(),
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
              if (killSwitchActive)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: WellbeingBreakOverlay(
                    onReset: () => svc.resetKillSwitch(),
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
    if (currentIndex == 2) {
      // Communities tab
      return FloatingActionButton(
        onPressed: () => context.goNamed('create_community'),
        backgroundColor: theme.colorScheme.primary,
        elevation: 2,
        shape: const CircleBorder(),
        child: Icon(
          Icons.add_rounded,
          color: theme.colorScheme.onPrimary,
          size: 28,
        ),
      );
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
        backgroundColor: theme.colorScheme.primary,
        elevation: 2,
        shape: const CircleBorder(),
        child: Icon(
          Icons.add_rounded,
          color: theme.colorScheme.onPrimary,
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
    // Indices 0 (Feed) and 1 (Search) are restricted when kill-switch is on.
    Widget _restrictedIcon(Widget icon) =>
        killSwitchActive ? Opacity(opacity: 0.3, child: icon) : icon;

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
          filter: imageUrl.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: NavigationBarM3E(
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedIndex: currentIndex,
            onDestinationSelected:
                (i) => _onDestinationSelected(
                  i,
                  killSwitchActive: killSwitchActive,
                ),
            labelBehavior: NavBarM3ELabelBehavior.alwaysHide,
            destinations: [
              NavigationDestinationM3E(
                icon: _restrictedIcon(const Icon(FluentIcons.home_24_regular)),
                selectedIcon: _restrictedIcon(
                  const Icon(FluentIcons.home_24_filled),
                ),
                label: 'Feed',
              ),
              NavigationDestinationM3E(
                icon: _restrictedIcon(
                  const Icon(FluentIcons.search_24_regular),
                ),
                selectedIcon: _restrictedIcon(
                  const Icon(FluentIcons.search_24_filled),
                ),
                label: 'Search',
              ),
              NavigationDestinationM3E(
                icon: const Icon(FluentIcons.people_community_24_regular),
                selectedIcon: const Icon(
                  FluentIcons.people_community_24_filled,
                ),
                label: 'Communities',
              ),
              NavigationDestinationM3E(
                icon: Badge.count(
                  count: 3,
                  child: const Icon(FluentIcons.chat_24_regular),
                ),
                selectedIcon: Badge.count(
                  count: 3,
                  child: const Icon(FluentIcons.chat_24_filled),
                ),
                label: 'Messages',
              ),
              NavigationDestinationM3E(
                icon: Badge.count(
                  count: 3,
                  child: const Icon(FluentIcons.alert_24_regular),
                ),
                selectedIcon: Badge.count(
                  count: 3,
                  child: const Icon(FluentIcons.alert_24_filled),
                ),
                label: 'Alerts',
              ),
              NavigationDestinationM3E(
                icon: const Icon(FluentIcons.person_24_regular),
                selectedIcon: const Icon(FluentIcons.person_24_filled),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationRail(
    BuildContext context,
    int currentIndex,
    ThemeData theme, {
    required bool killSwitchActive,
  }) {
    final colorScheme = theme.colorScheme;

    Widget _restrictedIcon(Widget icon) =>
        killSwitchActive ? Opacity(opacity: 0.3, child: icon) : icon;

    return NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected:
          (i) => _onDestinationSelected(i, killSwitchActive: killSwitchActive),
      labelType: NavigationRailLabelType.all,
      backgroundColor: const Color(0xFF0C0F14),
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Icon(Icons.auto_awesome, size: 32, color: colorScheme.primary),
      ),
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(Icons.person, color: colorScheme.onPrimaryContainer),
            ),
          ),
        ),
      ),
      destinations: [
        NavigationRailDestination(
          icon: _restrictedIcon(const Icon(FluentIcons.home_24_regular)),
          selectedIcon: _restrictedIcon(const Icon(FluentIcons.home_24_filled)),
          label:
              killSwitchActive
                  ? const Text('Feed', style: TextStyle(color: Colors.grey))
                  : const Text('Feed'),
        ),
        NavigationRailDestination(
          icon: _restrictedIcon(const Icon(FluentIcons.search_24_regular)),
          selectedIcon: _restrictedIcon(
            const Icon(FluentIcons.search_24_filled),
          ),
          label:
              killSwitchActive
                  ? const Text('Search', style: TextStyle(color: Colors.grey))
                  : const Text('Search'),
        ),
        NavigationRailDestination(
          icon: const Icon(FluentIcons.people_community_24_regular),
          selectedIcon: const Icon(FluentIcons.people_community_24_filled),
          label: const Text('Communities'),
        ),
        NavigationRailDestination(
          icon: Badge.count(
            count: 3,
            child: const Icon(FluentIcons.chat_24_regular),
          ),
          selectedIcon: Badge.count(
            count: 3,
            child: const Icon(FluentIcons.chat_24_filled),
          ),
          label: const Text('Messages'),
        ),
        NavigationRailDestination(
          icon: Badge.count(
            count: 3,
            child: const Icon(FluentIcons.alert_24_regular),
          ),
          selectedIcon: Badge.count(
            count: 3,
            child: const Icon(FluentIcons.alert_24_filled),
          ),
          label: const Text('Notifications'),
        ),
        NavigationRailDestination(
          icon: const Icon(FluentIcons.person_24_regular),
          selectedIcon: const Icon(FluentIcons.person_24_filled),
          label: const Text('Profile'),
        ),
      ],
    );
  }

  void _onDestinationSelected(int index, {bool killSwitchActive = false}) {
    // Block navigation to Feed (0) and Search (1) when kill-switch is active.
    if (killSwitchActive && (index == 0 || index == 1)) return;

    switch (index) {
      case 0:
        context.go('/feed');
        break;
      case 1:
        context.go('/search');
        break;
      case 2:
        context.go('/communities');
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
        path == '/reset-password'; // accessible with a recovery session
  }

  /// Routes that a fully-authenticated user should be bounced away from
  /// (e.g. they are already logged in, so login/register are irrelevant).
  /// NOTE: /reset-password is intentionally excluded — a user with a
  /// password-recovery session must be allowed to reach this screen.
  static bool _isLoginOnlyRoute(String path) {
    return path == '/login' || path == '/register';
  }

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    redirect: (context, state) async {
      // Splash handles its own navigation
      if (state.uri.path == '/splash') return null;

      // Password-reset screen is always reachable once Supabase sets the
      // recovery session — never redirect away from it automatically.
      if (state.uri.path == '/reset-password') return null;

      final authService = Provider.of<AuthService>(context, listen: false);
      await Future.delayed(Duration.zero);

      final isLoggedIn = authService.currentUser != null;

      // Unauthenticated users trying to reach a protected route → login
      if (!isLoggedIn && !_isPublicRoute(state.uri.path)) {
        return '/login';
      }

      // Authenticated users trying to reach login/register → feed
      if (isLoggedIn && _isLoginOnlyRoute(state.uri.path)) {
        return '/feed';
      }

      return null;
    },
    routes: [
      // Splash Screen
      GoRoute(
        path: '/splash',
        name: 'splash',
        pageBuilder:
            (context, state) =>
                MaterialPage(key: state.pageKey, child: const SplashScreen()),
      ),

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
            (context, state) =>
                MaterialPage(key: state.pageKey, child: const RegisterScreen()),
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
                (context, state) => const NoTransitionPage(child: FeedScreen()),
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
            path: '/communities',
            name: 'communities',
            pageBuilder:
                (context, state) =>
                    const NoTransitionPage(child: CommunitiesScreen()),
            routes: [
              // Community Creation Flow
              GoRoute(
                path: 'create',
                name: 'create_community',
                builder: (context, state) => const CommunityNameThemeScreen(),
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
            (context, state) =>
                MaterialPage(key: state.pageKey, child: const SettingsScreen()),
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
      ),

      // Community Detail Screen
      GoRoute(
        path: '/community/:communityId',
        name: 'community_detail',
        pageBuilder: (context, state) {
          final communityId = state.pathParameters['communityId']!;
          return MaterialPage(
            key: state.pageKey,
            child: CommunityDetailScreen(communityId: communityId),
          );
        },
      ),

      // Chat Screen
      GoRoute(
        path: '/chat/:conversationId',
        name: 'chat',
        pageBuilder: (context, state) {
          final conversationId = state.pathParameters['conversationId']!;
          final extra = state.extra as Map<String, dynamic>?;
          return MaterialPage(
            key: state.pageKey,
            child: ChatScreen(
              conversationId: conversationId,
              otherUserName: extra?['otherUserName'] ?? 'User',
              otherUserAvatar: extra?['otherUserAvatar'] ?? '',
              otherUserId: extra?['otherUserId'] ?? '',
            ),
          );
        },
      ),

      // New Message Screen
      GoRoute(
        path: '/new-message',
        name: 'new_message',
        pageBuilder:
            (context, state) => MaterialPage(
              key: state.pageKey,
              child: const NewMessageScreen(),
            ),
      ),

      // Community Creation Flow
      GoRoute(
        path: '/community/create',
        name: 'create-community',
        pageBuilder:
            (context, state) => MaterialPage(
              key: state.pageKey,
              child: const CommunityNameThemeScreen(),
            ),
      ),

      // Community Creation Steps
      GoRoute(
        path: '/community/create/guidelines',
        name: 'community-guidelines',
        pageBuilder: (context, state) {
          final extra = (state.extra ?? {}) as Map<String, dynamic>;
          final name = extra['name']?.toString() ?? '';
          final theme = extra['theme']?.toString() ?? '';
          return MaterialPage(
            key: state.pageKey,
            child: CommunityGuidelinesScreen(name: name, theme: theme),
          );
        },
      ),

      GoRoute(
        path: '/community/create/description',
        name: 'community-description',
        pageBuilder: (context, state) {
          final extra = (state.extra ?? {}) as Map<String, dynamic>;
          final name = extra['name']?.toString() ?? '';
          final theme = extra['theme']?.toString() ?? '';
          return MaterialPage(
            key: state.pageKey,
            child: CommunityDescriptionRulesScreen(name: name, theme: theme),
          );
        },
      ),

      GoRoute(
        path: '/community/create/privacy',
        name: 'community-privacy',
        pageBuilder: (context, state) {
          final extra = (state.extra ?? {}) as Map<String, dynamic>;
          final name = extra['name']?.toString() ?? '';
          final theme = extra['theme']?.toString() ?? '';
          final description = extra['description']?.toString() ?? '';
          final rules = extra['rules']?.toString() ?? '';
          return MaterialPage(
            key: state.pageKey,
            child: CommunityPrivacyModerationScreen(
              name: name,
              theme: theme,
              description: description,
              rules: rules,
            ),
          );
        },
      ),

      GoRoute(
        path: '/community/create/confirmation',
        name: 'community-confirmation',
        pageBuilder:
            (context, state) => MaterialPage(
              key: state.pageKey,
              child: CommunitySetupConfirmationScreen(
                communityData: state.extra as Map<String, dynamic>,
              ),
            ),
      ),

      // Community View
      GoRoute(
        path: '/community/:communityId',
        name: 'community',
        pageBuilder: (context, state) {
          final communityId = state.pathParameters['communityId']!;
          return MaterialPage(
            key: state.pageKey,
            child: CommunityDetailScreen(communityId: communityId),
          );
        },
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
}
