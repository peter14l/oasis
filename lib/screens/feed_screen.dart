import 'dart:ui';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oasis_v2/providers/feed_provider.dart';
import 'package:oasis_v2/providers/profile_provider.dart';
import 'package:oasis_v2/services/auth_service.dart';
import 'package:oasis_v2/services/stories_service.dart';
import 'package:oasis_v2/widgets/post_card.dart';
import 'package:share_plus/share_plus.dart';
import 'package:oasis_v2/models/story_model.dart';
import 'package:oasis_v2/widgets/stories_bar.dart';
import 'package:oasis_v2/widgets/capsules/capsule_carousel.dart';
import 'package:oasis_v2/models/feed_layout_strategy.dart';
import 'package:oasis_v2/widgets/feed_layout_switcher.dart';
import 'package:oasis_v2/screens/zen_feed_screen.dart';
import 'package:oasis_v2/screens/pulse_feed_screen.dart';
import 'package:oasis_v2/widgets/comments_modal.dart';
import 'package:oasis_v2/utils/responsive_layout.dart';
import 'package:oasis_v2/services/ripples_service.dart';
import 'package:oasis_v2/services/screen_time_service.dart';
import 'package:oasis_v2/providers/user_settings_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart' as motion;

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final AuthService _authService = AuthService();
  final StoriesService _storiesService = StoriesService();
  List<StoryGroup> _storyGroups = [];
  List<StoryModel> _myStories = [];
  FeedLayoutType _currentLayout = FeedLayoutType.standard;
  bool _isScrolled = false;
  Timer? _wellbeingTimer;
  bool _showWellbeingNudge = false;
  bool _isStoriesLoading = true;

  @override
  void initState() {
    super.initState();
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

  Future<void> _checkWellbeingLimit() async {
    final settings = context.read<UserSettingsProvider>();
    if (settings.dailyLimitMinutes <= 0) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final screenTimeService = ScreenTimeService(prefs);
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

      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
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
    final service = context.read<RipplesService>();
    if (service.isRipplesLocked) {
      final end = service.lockoutEndTime;
      final diff = end != null ? end.difference(DateTime.now()).inMinutes : 30;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ripples is locked for $diff more minutes to maintain well-being.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Enter Ripples', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text('How long would you like to stay today?'),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: TextField(
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: 'Minutes',
                    suffixText: 'min',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onSubmitted: (val) {
                    final mins = int.tryParse(val);
                    if (mins != null && mins > 0) {
                      service.startSession(Duration(minutes: mins));
                      Navigator.pop(context);
                      context.push('/ripples');
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),
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
          SliverAppBar(
            pinned: true,
            floating: true,
            snap: true,
            elevation: 0,
            backgroundColor: _isScrolled ? Colors.black.withValues(alpha: 0.8) : Colors.transparent,
            toolbarHeight: ResponsiveLayout.isDesktop(context) ? 80 : 70,
            automaticallyImplyLeading: false,
            centerTitle: !ResponsiveLayout.isDesktop(context),
            title: Row(
              mainAxisAlignment: ResponsiveLayout.isDesktop(context) ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                if (ResponsiveLayout.isDesktop(context)) const SizedBox(width: 8),
                PopupMenuButton<int>(
                  onSelected: (index) => _tabController.animateTo(index),
                  offset: const Offset(0, 45),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 0, child: Text('FOLLOWING', style: TextStyle(fontWeight: FontWeight.bold))),
                    const PopupMenuItem(value: 1, child: Text('EXPLORE', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _tabController.index == 0 ? 'FOLLOWING' : 'EXPLORE',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => _handleRipplesTap(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: colorScheme.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: colorScheme.secondary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.waves_rounded, size: 18, color: colorScheme.secondary),
                        const SizedBox(width: 8),
                        Text('Ripples', style: TextStyle(color: colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              FeedLayoutSwitcher(
                currentLayout: _currentLayout,
                onLayoutChanged: (layout) => setState(() => _currentLayout = layout),
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
                return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
              }
              if (posts.isEmpty) {
                return const SliverFillRemaining(child: Center(child: Text('No posts found.')));
              }
              return SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveLayout.isDesktop(context) ? 40 : 0,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => PostCard(
                      post: posts[index],
                      onComment: () => context.push('/post/${posts[index].id}/comments'),
                    ),
                    childCount: posts.length,
                  ),
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
          ResponsiveLayout.isDesktop(context)
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surface.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: MaxWidthContainer(
                                maxWidth: ResponsiveLayout.maxFeedWidth + 100, 
                                child: feedContent,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 400,
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: ListView(
                              padding: const EdgeInsets.all(32),
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.trending_up, size: 20, color: colorScheme.primary),
                                    const SizedBox(width: 12),
                                    Text('TRENDING', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 2, color: colorScheme.primary)),
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
                                    Icon(Icons.person_add_outlined, size: 20, color: colorScheme.primary),
                                    const SizedBox(width: 12),
                                    Text('SUGGESTED', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 2, color: colorScheme.primary)),
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
                      ),
                    ],
                  ),
                )
              : (ResponsiveLayout.isMobile(context) ? feedContent : MaxWidthContainer(maxWidth: ResponsiveLayout.maxFeedWidth, child: feedContent)),
          if (_showWellbeingNudge) _buildWellbeingNudge(),
        ],
      ),
    );
  }

  Widget _buildTrendingItem(String tag, String count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tag, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          Text(count, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
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
            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            child: Text(name[0], style: const TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(handle, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11)),
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
                  border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
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
                      child: const Icon(Icons.spa_rounded, color: Colors.amber, size: 40),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Time for a breather?',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'You\'ve been on Oasis for ${settings.dailyLimitMinutes} minutes today.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
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
                      onPressed: () => setState(() => _showWellbeingNudge = false),
                      child: const Text('Stay for 5 more minutes', style: TextStyle(color: Colors.white54)),
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
