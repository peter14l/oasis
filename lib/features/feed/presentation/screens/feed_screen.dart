import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oasis/services/digital_wellbeing_service.dart';
import 'package:oasis/widgets/wellbeing/lockout_overlay.dart';
import 'package:oasis/core/config/app_config.dart';
import 'package:oasis/features/feed/presentation/providers/feed_provider.dart';
import 'package:oasis/features/profile/presentation/providers/profile_provider.dart';
import 'package:oasis/services/auth_service.dart';
import 'package:oasis/features/stories/presentation/providers/stories_provider.dart';
import 'package:oasis/features/feed/presentation/widgets/post_card.dart';
import 'package:share_plus/share_plus.dart';
import 'package:oasis/features/ripples/presentation/screens/ripples_screen.dart';
import 'package:oasis/widgets/comments_modal.dart';
import 'package:oasis/widgets/adaptive/adaptive_scaffold.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:oasis/core/utils/responsive_layout.dart';
import 'package:oasis/features/ripples/presentation/providers/ripples_provider.dart';
import 'package:oasis/services/screen_time_service.dart';
import 'package:oasis/features/settings/presentation/providers/user_settings_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart' as motion;
import 'package:oasis/themes/app_colors.dart';
import 'package:oasis/services/app_initializer.dart';
import 'package:oasis/models/feed_layout_strategy.dart';
import 'package:oasis/features/feed/presentation/widgets/layouts/classic_feed_layout.dart';
import 'package:oasis/features/feed/presentation/widgets/layouts/focused_flow_layout.dart';
import 'package:oasis/features/feed/presentation/widgets/layouts/spatial_glider_layout.dart';
import 'package:oasis/features/feed/presentation/widgets/layouts/living_canvas_layout.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  Timer? _wellbeingTimer;
  bool _showWellbeingNudge = false;
  bool _showRipplesOverlay = false;
  bool _showDeepBreath = true; // Show on first load

  // Desktop Comment Pane State
  String? _selectedPostId;
  bool _showCommentPane = false;

  // Cached service references for safe cleanup in dispose()
  DigitalWellbeingService? _wellbeingService;
  UserSettingsProvider? _settingsProvider;

  AuthService get _authService => context.read<AuthService>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _scrollController.addListener(_onScroll);

    // Load initial feed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadFeed();
      _loadStories();
      final userId = _authService.currentUser?.id;
      if (userId != null) {
        context.read<ProfileProvider>().loadFollowing(userId);
        context.read<RipplesProvider>().initForUser(userId);
      }
      _startWellbeingPolling();
      if (mounted) {
        _wellbeingService = context.read<DigitalWellbeingService>();
        _wellbeingService?.startTracking('feed');
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cache settings provider for async callbacks
    _settingsProvider = context.read<UserSettingsProvider>();
  }

  void _startWellbeingPolling() {
    _wellbeingTimer?.cancel();
    _wellbeingTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkWellbeingLimit();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _wellbeingTimer?.cancel();
      _wellbeingTimer = null;
      debugPrint('FeedScreen: Wellbeing polling paused (background)');
    } else if (state == AppLifecycleState.resumed) {
      _startWellbeingPolling();
      debugPrint('FeedScreen: Wellbeing polling resumed');
    }
  }

  Future<void> _checkWellbeingLimit() async {
    if (!mounted) return;
    final settings = _settingsProvider;
    if (settings == null || settings.dailyLimitMinutes <= 0) return;

    try {
      final screenTimeService = context.read<ScreenTimeService>();
      final todayUsage = await screenTimeService.getTodayTotalUsage();
      final usageMinutes = todayUsage.inMinutes;

      if (usageMinutes >= settings.dailyLimitMinutes && !_showWellbeingNudge) {
        if (mounted) {
          setState(() => _showWellbeingNudge = true);
        }
      }
    } catch (e) {
      debugPrint('Error checking wellbeing limit: $e');
    }
  }

  void _onScroll() {
    if (!mounted || !_scrollController.hasClients) return;
    if (_scrollController.offset > 50 && !_isScrolled) {
      setState(() => _isScrolled = true);
    } else if (_scrollController.offset <= 50 && _isScrolled) {
      setState(() => _isScrolled = false);
    }

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final userId = _authService.currentUser?.id;
      if (userId != null) {
        final feedProvider = context.read<FeedProvider>();
        if (!feedProvider.isLoadingMore && feedProvider.hasMore) {
          feedProvider.loadMore(userId: userId);
        }
      }
    }
  }

  void _handleTabSelection() {
    if (!mounted) return;
    if (_tabController.indexIsChanging) {
      _loadFeed();
    }
  }

  @override
  void dispose() {
    try {
      _wellbeingService?.stopTracking();
    } catch (e) {
      debugPrint('Error stopping wellbeing tracking in dispose: $e');
    }
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    _scrollController.dispose();
    _wellbeingTimer?.cancel();
    super.dispose();
  }

  void _loadFeed() {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;

    final provider = context.read<FeedProvider>();
    if (_tabController.index == 0) {
      provider.switchFeedType(FeedType.following, userId: userId);
    } else {
      provider.switchFeedType(FeedType.forYou, userId: userId);
    }
  }

  void _loadStories() async {
    final userId = _authService.currentUser?.id;
    if (userId != null) {
      final provider = context.read<StoriesProvider>();
      provider.loadFollowingStories();
      provider.loadMyStories();
    }
  }

  Future<void> _refreshFeed() async {
    final userId = _authService.currentUser?.id;
    if (userId != null) {
      await context.read<FeedProvider>().refresh(userId: userId);
      _loadStories();
    }
  }

  void _handleRipplesTap(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final service = context.read<RipplesProvider>();
    if (service.isRipplesLocked) {
      final end = service.lockoutEndTime;
      final diff = end != null ? end.difference(DateTime.now()).inMinutes : 30;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ripples is locked for $diff more minutes to maintain well-being.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Enter Ripples',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Set your intentional focus duration',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [15, 30, 45].map((mins) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ChoiceChip(
                      label: Text('$mins min'),
                      selected: false,
                      onSelected: (_) {
                        service.startSession(Duration(minutes: mins));
                        Navigator.pop(context);
                        if (ResponsiveLayout.isDesktop(context)) {
                          setState(() => _showRipplesOverlay = true);
                        } else {
                          context.push('/ripples');
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: TextField(
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  autofocus: true,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                  decoration: InputDecoration(
                    hintText: '00',
                    suffixText: 'min',
                    suffixStyle: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onSubmitted: (val) {
                    final mins = int.tryParse(val);
                    if (mins != null && mins > 0) {
                      service.startSession(Duration(minutes: mins));
                      Navigator.pop(context);
                      if (ResponsiveLayout.isDesktop(context)) {
                        setState(() => _showRipplesOverlay = true);
                      } else {
                        context.push('/ripples');
                      }
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Ripples limits distractions to help you stay present.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showLayoutSwitcher(BuildContext context) {
    final settings = context.read<UserSettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Feed Layout',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ...FeedLayoutType.values.map((type) {
              final isSelected = settings.feedLayout == type;
              return ListTile(
                leading: Icon(
                  type.icon,
                  color: isSelected ? colorScheme.primary : null,
                ),
                title: Text(
                  type.displayName,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : null,
                    color: isSelected ? colorScheme.primary : null,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle, color: colorScheme.primary)
                    : null,
                onTap: () {
                  settings.setFeedLayout(type);
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isM3E = themeProvider.isM3EEnabled;
    final disableTransparency = themeProvider.isM3ETransparencyDisabled;
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final settings = context.watch<UserSettingsProvider>();
    final useFluent = themeProvider.useFluentUI;

    Widget layout;
    switch (settings.feedLayout) {
      case FeedLayoutType.classic:
        layout = ClassicFeedLayout(
          scrollController: _scrollController,
          onRefresh: _refreshFeed,
          isDesktop: isDesktop,
          isScrolled: _isScrolled,
          mobileHeader: _buildMobileHeader(colorScheme, isM3E),
          buildPostItem: _buildPostItem,
        );
        break;
      case FeedLayoutType.focused:
        layout = FocusedFlowLayout(
          onRefresh: _refreshFeed,
          mobileHeader: _buildMobileHeader(colorScheme, isM3E),
          buildPostItem: _buildPostItem,
        );
        break;
      case FeedLayoutType.spatial:
        layout = SpatialGliderLayout(
          onRefresh: _refreshFeed,
          mobileHeader: _buildMobileHeader(colorScheme, isM3E),
          buildPostItem: _buildPostItem,
        );
        break;
      case FeedLayoutType.canvas:
        layout = LivingCanvasLayout(
          onRefresh: _refreshFeed,
          mobileHeader: _buildMobileHeader(colorScheme, isM3E),
          buildPostItem: _buildPostItem,
        );
        break;
    }

    final feedContent = layout;

    if (useFluent && isDesktop) {
      return AdaptiveScaffold(
        title: const Text('Feed'),
        actions: [
          _buildDesktopTabSwitcher(colorScheme, isM3E),
          const SizedBox(width: 12),
          fluent.Tooltip(
            message: 'Change Layout',
            child: fluent.IconButton(
              icon: Icon(settings.feedLayout.icon, size: 20),
              onPressed: () => _showLayoutSwitcher(context),
            ),
          ),
          const SizedBox(width: 12),
          _buildRipplesButton(colorScheme, isM3E),
        ],
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: disableTransparency
                            ? colorScheme.surfaceContainer
                            : colorScheme.surface.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(isM3E ? 28 : 12),
                        border: isM3E
                            ? Border.all(
                                color: colorScheme.outlineVariant
                                    .withValues(alpha: 0.3),
                                width: 1,
                              )
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(isM3E ? 28 : 12),
                        child: disableTransparency
                            ? feedContent
                            : BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: feedContent,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _showCommentPane && _selectedPostId != null
                      ? _buildDesktopCommentPane(theme, colorScheme, isM3E)
                      : _buildDesktopSidebar(theme, colorScheme, isM3E),
                ],
              ),
            ),
            if (_showRipplesOverlay)
              Positioned.fill(
                child: motion.Animate(
                  effects: const [motion.FadeEffect()],
                  child: RipplesScreen(
                    onExit: () => setState(() => _showRipplesOverlay = false),
                  ),
                ),
              ),
            const LockoutOverlay(pageName: 'Feed'),
            if (_showWellbeingNudge) _buildWellbeingNudge(),
            if (_showDeepBreath) _buildDeepBreath(),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: feedContent,
    );
  }

  Widget _buildDeepBreath() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          color: OasisColors.deep.withValues(alpha: 0.9),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                motion.Animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                  effects: [
                    motion.ScaleEffect(
                      begin: const Offset(1.0, 1.0),
                      end: const Offset(1.2, 1.2),
                      duration: const Duration(seconds: 4),
                      curve: Curves.easeInOut,
                    ),
                    motion.FadeEffect(
                      begin: 0.4,
                      end: 0.8,
                      duration: const Duration(seconds: 4),
                    ),
                  ],
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: OasisColors.glow.withValues(alpha: 0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: OasisColors.glow.withValues(alpha: 0.2),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 64),
                motion.Animate(
                  effects: const [
                    motion.FadeEffect(
                      delay: Duration(milliseconds: 500),
                      duration: Duration(seconds: 2),
                    ),
                  ],
                  child: Text(
                    'Take a deep breath',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontFamily: 'Cormorant Garamond',
                      fontStyle: FontStyle.italic,
                      color: OasisColors.sand,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                motion.Animate(
                  effects: const [
                    motion.FadeEffect(
                      delay: Duration(seconds: 2),
                      duration: Duration(seconds: 1),
                    ),
                  ],
                  child: Text(
                    'Enter Oasis with intention.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: OasisColors.mist,
                    ),
                  ),
                ),
                const SizedBox(height: 64),
                motion.Animate(
                  effects: const [
                    motion.FadeEffect(
                      delay: Duration(seconds: 3),
                      duration: Duration(seconds: 1),
                    ),
                  ],
                  child: TextButton(
                    onPressed: () => setState(() => _showDeepBreath = false),
                    style: TextButton.styleFrom(
                      foregroundColor: OasisColors.glow,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: const Text(
                      'I AM PRESENT',
                      style: TextStyle(
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostItem(
    dynamic post,
    FeedProvider provider,
    bool isDesktopPadding,
  ) {
    return PostCard(
      post: post,
      onLike: () async {
        final userId = _authService.currentUser?.id;
        if (userId == null) return;

        if (post.isLiked) {
          provider.unlikePost(userId: userId, postId: post.id);
        } else {
          try {
            await provider.likePost(userId: userId, postId: post.id);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to like post: ${e.toString()}'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        }
      },
      onComment: () {
        if (ResponsiveLayout.isDesktop(context)) {
          setState(() {
            if (_selectedPostId == post.id) {
              _showCommentPane = !_showCommentPane;
            } else {
              _selectedPostId = post.id;
              _showCommentPane = true;
            }
          });
        } else {
          context.push('/post/${post.id}/comments');
        }
      },
      onBookmark: () {
        final userId = _authService.currentUser?.id;
        if (userId == null) return;

        if (post.isBookmarked) {
          provider.unbookmarkPost(userId: userId, postId: post.id);
        } else {
          provider.bookmarkPost(userId: userId, postId: post.id);
        }
      },
      onShare: () {
        final deepLink = AppConfig.getWebUrl('/post/${post.id}');
        Share.share('Check out this post on Oasis! $deepLink');
      },
    );
  }

  Widget _buildDesktopCommentPane(
    ThemeData theme,
    ColorScheme colorScheme, [
    bool isM3E = false,
  ]) {
    return Container(
      width: 450,
      decoration: BoxDecoration(
        color: isM3E
            ? colorScheme.surfaceContainer
            : colorScheme.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(isM3E ? 28 : 12),
        border: isM3E
            ? Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                width: 1,
              )
            : Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isM3E ? 28 : 12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                height: 80,
                child: Row(
                  children: [
                    Text(
                      'Comments',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => setState(() => _showCommentPane = false),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: CommentsModal(
                  postId: _selectedPostId!,
                  isSidePane: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileHeader(ColorScheme colorScheme, [bool isM3E = false]) {
    final settings = context.watch<UserSettingsProvider>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(settings.feedLayout.icon, size: 24),
          onPressed: () => _showLayoutSwitcher(context),
          tooltip: 'Change Layout',
        ),
        const Spacer(),
        _buildTabSwitcher(colorScheme, isM3E),
        const Spacer(),
        _buildRipplesButton(colorScheme, isM3E),
      ],
    );
  }

  Widget _buildDesktopTabSwitcher(
    ColorScheme colorScheme, [
    bool isM3E = false,
  ]) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(isM3E ? 14 : 24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDesktopTabButton('Following', 0, colorScheme, isM3E),
          _buildDesktopTabButton('Explore', 1, colorScheme, isM3E),
        ],
      ),
    );
  }

  Widget _buildDesktopTabButton(
    String label,
    int index,
    ColorScheme colorScheme,
    bool isM3E,
  ) {
    final isSelected = _tabController.index == index;
    return GestureDetector(
      onTap: () => setState(() => _tabController.animateTo(index)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(isM3E ? 10 : 20),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildTabSwitcher(ColorScheme colorScheme, [bool isM3E = false]) {
    return PopupMenuButton<int>(
      onSelected: (index) => _tabController.animateTo(index),
      offset: const Offset(0, 45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isM3E ? 16 : 20),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 0,
          child: Text(
            'FOLLOWING',
            style: TextStyle(
              fontWeight: isM3E ? FontWeight.w600 : FontWeight.bold,
            ),
          ),
        ),
        PopupMenuItem(
          value: 1,
          child: Text(
            'EXPLORE',
            style: TextStyle(
              fontWeight: isM3E ? FontWeight.w600 : FontWeight.bold,
            ),
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isM3E
              ? colorScheme.surfaceContainer
              : colorScheme.surface.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(isM3E ? 20 : 32),
          border: isM3E
              ? Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  width: 1,
                )
              : Border.all(color: colorScheme.onSurface.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _tabController.index == 0 ? 'FOLLOWING' : 'EXPLORE',
              style: TextStyle(
                fontWeight: isM3E ? FontWeight.w600 : FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRipplesButton(ColorScheme colorScheme, [bool isM3E = false]) {
    return GestureDetector(
      onTap: () => _handleRipplesTap(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isM3E
              ? colorScheme.tertiaryContainer
              : colorScheme.secondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(isM3E ? 20 : 32),
          border: isM3E
              ? Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  width: 1,
                )
              : Border.all(color: colorScheme.secondary.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ripples',
              style: TextStyle(
                color: isM3E
                    ? colorScheme.onTertiaryContainer
                    : colorScheme.secondary,
                fontWeight: isM3E ? FontWeight.w600 : FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopSidebar(
    ThemeData theme,
    ColorScheme colorScheme, [
    bool isM3E = false,
  ]) {
    return Container(
      width: 400,
      decoration: BoxDecoration(
        color: isM3E
            ? colorScheme.surfaceContainer
            : colorScheme.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(isM3E ? 28 : 12),
        border: isM3E
            ? Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                width: 1,
              )
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isM3E ? 28 : 12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: ListView(
            padding: const EdgeInsets.all(32),
            children: [
              Row(
                children: [
                  Icon(Icons.trending_up, size: 20, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    'TRENDING',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildTrendingItem('#OasisApp', '2.4k posts'),
              _buildTrendingItem('#OasisV2', '1.8k posts'),
              _buildTrendingItem('#FlutterDesktop', '942 posts'),
              _buildTrendingItem('#CyberDesign', '621 posts'),
              const SizedBox(height: 48),
              Row(
                children: [
                  Icon(
                    Icons.person_add_outlined,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'SUGGESTED',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSuggestionItem('DesignDaily', '@designdaily'),
              _buildSuggestionItem('TechNexus', '@technexus'),
              _buildSuggestionItem('CreativeSoul', '@creative'),
              _buildSuggestionItem('FutureVibe', '@future'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingItem(String tag, String count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tag,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          Text(
            count,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(String name, String handle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.1),
            child: Text(name[0], style: const TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  handle,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            child: const Text('Follow'),
          ),
        ],
      ),
    );
  }

  Widget _buildWellbeingNudge() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = context.read<UserSettingsProvider>();

    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Colors.black.withValues(alpha: 0.7),
          child: Center(
            child: motion.Animate(
              effects: const [motion.FadeEffect(), motion.ScaleEffect()],
              child: Container(
                margin: const EdgeInsets.all(32),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.spa_rounded,
                        color: Colors.amber,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Time for a breather?',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'You\'ve been on Oasis for ${settings.dailyLimitMinutes} minutes today.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          setState(() => _showWellbeingNudge = false);
                          context.go('/spaces/circles');
                        },
                        child: const Text('CHECK ON YOUR CIRCLES'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () =>
                          setState(() => _showWellbeingNudge = false),
                      child: const Text(
                        'Stay for 5 more minutes',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
