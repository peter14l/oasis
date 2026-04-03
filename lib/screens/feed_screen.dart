import 'dart:ui';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oasis_v2/features/feed/presentation/providers/feed_provider.dart';
import 'package:oasis_v2/features/profile/presentation/providers/profile_provider.dart';
import 'package:oasis_v2/services/auth_service.dart';
import 'package:oasis_v2/services/stories_service.dart';
import 'package:oasis_v2/widgets/post_card.dart';
import 'package:share_plus/share_plus.dart';
import 'package:oasis_v2/models/story_model.dart';
import 'package:oasis_v2/widgets/stories_bar.dart';
import 'package:oasis_v2/widgets/capsules/capsule_carousel.dart';
import 'package:oasis_v2/models/feed_layout_strategy.dart';
import 'package:oasis_v2/widgets/feed_layout_switcher.dart';
import 'package:oasis_v2/screens/ripples_screen.dart';
import 'package:oasis_v2/screens/zen_feed_screen.dart';
import 'package:oasis_v2/screens/pulse_feed_screen.dart';
import 'package:oasis_v2/widgets/comments_modal.dart';
import 'package:oasis_v2/core/utils/responsive_layout.dart';
import 'package:oasis_v2/services/ripples_service.dart';
import 'package:oasis_v2/services/screen_time_service.dart';
import 'package:oasis_v2/providers/user_settings_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart' as motion;
import 'package:oasis_v2/services/app_initializer.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final StoriesService _storiesService = StoriesService();
  List<StoryGroup> _storyGroups = [];
  List<StoryModel> _myStories = [];
  FeedLayoutType _currentLayout = FeedLayoutType.standard;
  bool _isScrolled = false;
  Timer? _wellbeingTimer;
  bool _showWellbeingNudge = false;
  bool _isStoriesLoading = true;
  bool _showRipplesOverlay = false;

  // Desktop Comment Pane State
  String? _selectedPostId;
  bool _showCommentPane = false;

  AuthService get _authService => context.read<AuthService>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _scrollController.addListener(_onScroll);

    // Load initial feed and layout preference
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFeed();
      _loadStories();
      _loadLayoutPreference();
      final userId = _authService.currentUser?.id;
      if (userId != null) {
        context.read<ProfileProvider>().loadFollowing(userId);
        context.read<RipplesService>().initForUser(userId);
      }
      _startWellbeingPolling();
    });
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
    final settings = context.read<UserSettingsProvider>();
    if (settings.dailyLimitMinutes <= 0) return;

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
    if (_scrollController.hasClients) {
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
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      _loadFeed();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    _scrollController.dispose();
    _wellbeingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadLayoutPreference() async {
    final layout = await FeedLayoutSwitcher.loadLayoutPreference();
    setState(() {
      _currentLayout = layout;
    });
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
    setState(() => _isStoriesLoading = true);
    final userId = _authService.currentUser?.id;
    if (userId != null) {
      final groups = await _storiesService.getFollowingStories();
      final myStories = await _storiesService.getMyStories();
      if (mounted) {
        setState(() {
          _storyGroups = groups;
          _myStories = myStories;
          _isStoriesLoading = false;
        });
      }
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
    final service = context.read<RipplesService>();
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
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
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
                  Icon(
                        Icons.waves_rounded,
                        size: 48,
                        color: colorScheme.primary,
                      )
                      .animate(
                        onPlay:
                            (controller) => controller.repeat(reverse: true),
                      )
                      .scale(duration: 1.seconds, curve: Curves.easeInOut),
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
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
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
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
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isM3E = themeProvider.isM3EEnabled;
    final disableTransparency = themeProvider.isM3ETransparencyDisabled;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    if (_currentLayout == FeedLayoutType.zenCarousel) {
      return ZenFeedScreen(
        onLayoutChanged: (layout) => setState(() => _currentLayout = layout),
      );
    } else if (_currentLayout == FeedLayoutType.pulseMap) {
      return PulseFeedScreen(
        onLayoutChanged: (layout) => setState(() => _currentLayout = layout),
      );
    }

    final feedContent = RefreshIndicator(
      onRefresh: _refreshFeed,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (!isDesktop)
            SliverAppBar(
              pinned: true,
              floating: true,
              snap: true,
              elevation: 0,
              backgroundColor:
                  _isScrolled
                      ? Colors.black.withValues(alpha: 0.8)
                      : Colors.transparent,
              toolbarHeight: 70,
              automaticallyImplyLeading: false,
              centerTitle: true,
              title: _buildMobileHeader(colorScheme, isM3E),
              actions: [
                FeedLayoutSwitcher(
                  currentLayout: _currentLayout,
                  onLayoutChanged:
                      (layout) => setState(() => _currentLayout = layout),
                ),
                const SizedBox(width: 16),
              ],
            ),

          SliverToBoxAdapter(
            child: StoriesBar(
              storyGroups: _storyGroups,
              currentUserStories: _myStories,
              isLoading: _isStoriesLoading,
              onRefresh: _loadStories,
            ),
          ),

          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: CapsuleCarousel(),
            ),
          ),

          Consumer<FeedProvider>(
            builder: (context, provider, _) {
              final posts = provider.posts;
              if (provider.isLoading && posts.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (posts.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('No posts found.')),
                );
              }
              return SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: isDesktop ? 20 : 0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final post = posts[index];
                    return PostCard(
                      post: post,
                      onLike: () async {
                        final userId = _authService.currentUser?.id;
                        if (userId == null) return;

                        if (post.isLiked) {
                          provider.unlikePost(userId: userId, postId: post.id);
                        } else {
                          try {
                            await provider.likePost(
                              userId: userId,
                              postId: post.id,
                            );
                          } catch (e) {
                            // Show error snackbar if liking fails
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to like post: ${e.toString()}',
                                  ),
                                  backgroundColor:
                                      Theme.of(context).colorScheme.error,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        }
                      },
                      onComment: () {
                        if (isDesktop) {
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
                          provider.unbookmarkPost(
                            userId: userId,
                            postId: post.id,
                          );
                        } else {
                          provider.bookmarkPost(
                            userId: userId,
                            postId: post.id,
                          );
                        }
                      },
                      onShare: () {
                        final deepLink =
                            'https://oasis-web-red.vercel.app/post/${post.id}';
                        Share.share('Check out this post on Morrow! $deepLink');
                      },
                    );
                  }, childCount: posts.length),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          isDesktop
              ? Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color:
                              disableTransparency
                                  ? colorScheme.surfaceContainer
                                  : colorScheme.surface.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(isM3E ? 28 : 12),
                          border:
                              isM3E
                                  ? Border.all(
                                    color: colorScheme.outlineVariant
                                        .withValues(alpha: 0.3),
                                    width: 1,
                                  )
                                  : null,
                        ),
                        child: Column(
                          children: [
                            _buildDesktopHeader(colorScheme, isM3E),
                            const Divider(height: 1, thickness: 0.5),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.vertical(
                                  bottom: Radius.circular(isM3E ? 28 : 12),
                                ),
                                child:
                                    disableTransparency
                                        ? MaxWidthContainer(
                                          maxWidth: 600,
                                          child: feedContent,
                                        )
                                        : BackdropFilter(
                                          filter: ImageFilter.blur(
                                            sigmaX: 10,
                                            sigmaY: 10,
                                          ),
                                          child: MaxWidthContainer(
                                            maxWidth: 600,
                                            child: feedContent,
                                          ),
                                        ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _showCommentPane && _selectedPostId != null
                        ? _buildDesktopCommentPane(theme, colorScheme, isM3E)
                        : _buildDesktopSidebar(theme, colorScheme, isM3E),
                  ],
                ),
              )
              : (ResponsiveLayout.isMobile(context)
                  ? feedContent
                  : MaxWidthContainer(
                    maxWidth: ResponsiveLayout.maxFeedWidth,
                    child: feedContent,
                  )),

          if (_showRipplesOverlay && isDesktop)
            Positioned.fill(
              child: motion.Animate(
                effects: const [motion.FadeEffect()],
                child: RipplesScreen(
                  onExit: () => setState(() => _showRipplesOverlay = false),
                ),
              ),
            ),

          if (_showWellbeingNudge) _buildWellbeingNudge(),
        ],
      ),
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
        color:
            isM3E
                ? colorScheme.surfaceContainer
                : colorScheme.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(isM3E ? 28 : 12),
        border:
            isM3E
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTabSwitcher(colorScheme, isM3E),
        const SizedBox(width: 16),
        _buildRipplesButton(colorScheme, isM3E),
      ],
    );
  }

  Widget _buildDesktopHeader(ColorScheme colorScheme, [bool isM3E = false]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      height: 80,
      child: Row(
        children: [
          Text(
            'Feed',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: isM3E ? FontWeight.w600 : FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          _buildTabSwitcher(colorScheme),
          const SizedBox(width: 24),
          _buildRipplesButton(colorScheme),
          const SizedBox(width: 24),
          FeedLayoutSwitcher(
            currentLayout: _currentLayout,
            onLayoutChanged:
                (layout) => setState(() => _currentLayout = layout),
          ),
        ],
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
      itemBuilder:
          (context) => [
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
          color:
              isM3E
                  ? colorScheme.surfaceContainer
                  : colorScheme.surface.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(isM3E ? 20 : 32),
          border:
              isM3E
                  ? Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                    width: 1,
                  )
                  : Border.all(
                    color: colorScheme.onSurface.withValues(alpha: 0.1),
                  ),
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
          color:
              isM3E
                  ? colorScheme.tertiaryContainer
                  : colorScheme.secondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(isM3E ? 20 : 32),
          border:
              isM3E
                  ? Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    width: 1,
                  )
                  : Border.all(
                    color: colorScheme.secondary.withValues(alpha: 0.2),
                  ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.waves_rounded,
              size: 18,
              color:
                  isM3E
                      ? colorScheme.onTertiaryContainer
                      : colorScheme.secondary,
            ),
            const SizedBox(width: 8),
            Text(
              'Ripples',
              style: TextStyle(
                color:
                    isM3E
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
        color:
            isM3E
                ? colorScheme.surfaceContainer
                : colorScheme.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(isM3E ? 28 : 12),
        border:
            isM3E
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
              _buildTrendingItem('#MorrowApp', '2.4k posts'),
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
                      onPressed:
                          () => setState(() => _showWellbeingNudge = false),
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
