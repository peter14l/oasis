import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
import 'package:oasis_v2/widgets/greyscale_wrapper.dart';
import 'package:oasis_v2/widgets/comments_modal.dart';
import 'package:oasis_v2/utils/responsive_layout.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final AuthService _authService = AuthService();
  final StoriesService _storiesService = StoriesService();

  List<StoryGroup> _storyGroups = [];
  List<StoryModel>? _currentUserStories;
  bool _isLoadingStories = false;
  int _selectedIndex = 0;
  FeedLayoutType _currentLayout = FeedLayoutType.standard;

  bool _isScrolled = false;

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
      }
    });
  }

  Future<void> _loadLayoutPreference() async {
    final layout = await FeedLayoutSwitcher.loadLayoutPreference();
    if (mounted) {
      setState(() {
        _currentLayout = layout;
      });
    }
  }

  Future<void> _loadStories() async {
    if (mounted) setState(() => _isLoadingStories = true);

    try {
      final groups = await _storiesService.getFollowingStories();
      final currentUserId = _authService.currentUser?.id;

      // Separate current user's stories from others
      List<StoryModel>? currentUserStories;
      if (currentUserId != null) {
        final currentUserGroup =
            groups.where((g) => g.userId == currentUserId).toList();
        if (currentUserGroup.isNotEmpty) {
          currentUserStories = currentUserGroup.first.stories;
        }
      }

      if (mounted) {
        setState(() {
          _storyGroups = groups;
          _currentUserStories = currentUserStories;
          _isLoadingStories = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading stories: $e');
      if (mounted) setState(() => _isLoadingStories = false);
    }
  }

  void _handleTabSelection() {
    if (!mounted) return;
    if (_tabController.indexIsChanging) {
      setState(() => _selectedIndex = _tabController.index);
    }
  }

  void _loadFeed() {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;

    final feedProvider = context.read<FeedProvider>();
    feedProvider.loadFeed(userId: userId);
  }

  Future<void> _refreshFeed() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;

    final feedProvider = context.read<FeedProvider>();
    await feedProvider.refresh(userId: userId);
    await _loadStories();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final isScrolled = _scrollController.offset > 10;
      if (isScrolled != _isScrolled) {
        setState(() => _isScrolled = isScrolled);
      }
    }

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final userId = _authService.currentUser?.id;
      if (userId == null) return;

      final feedProvider = context.read<FeedProvider>();
      if (!feedProvider.isLoadingMore && feedProvider.hasMore) {
        feedProvider.loadMore(userId: userId);
      }
    }
  }

  void _handleLike(String postId) async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;

    final feedProvider = context.read<FeedProvider>();
    final post = feedProvider.posts.firstWhere((p) => p.id == postId);

    try {
      if (post.isLiked) {
        await feedProvider.unlikePost(userId: userId, postId: postId);
      } else {
        await feedProvider.likePost(userId: userId, postId: postId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  void _handleBookmark(String postId) async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;

    final feedProvider = context.read<FeedProvider>();
    final post = feedProvider.posts.firstWhere((p) => p.id == postId);

    try {
      if (post.isBookmarked) {
        await feedProvider.unbookmarkPost(userId: userId, postId: postId);
      } else {
        await feedProvider.bookmarkPost(userId: userId, postId: postId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  void _handleComment(String postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsModal(postId: postId),
    );
  }

  void _handleShare(String postId) {
    // Share with deep link to post
    final deepLink = 'https://morrow.app/post/$postId';
    Share.share('Check out this post on Morrow! $deepLink');
  }

  void _handleDelete(String postId) async {
    final feedProvider = context.read<FeedProvider>();
    try {
      await feedProvider.deletePost(postId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Post deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting post: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final userId = _authService.currentUser?.id;

    // Return alternative layouts if selected
    if (_currentLayout == FeedLayoutType.zenCarousel) {
      return GreyscaleWrapper(
        child: ZenFeedScreen(
          onLayoutChanged: (layout) {
            setState(() {
              _currentLayout = layout;
            });
          },
        ),
      );
    } else if (_currentLayout == FeedLayoutType.pulseMap) {
      return GreyscaleWrapper(
        child: PulseFeedScreen(
          onLayoutChanged: (layout) {
            setState(() {
              _currentLayout = layout;
            });
          },
        ),
      );
    }

    return GreyscaleWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Consumer<FeedProvider>(
          builder: (context, feedProvider, child) {
            final feedContent = RefreshIndicator(
              onRefresh: _refreshFeed,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Pinned AppBar with Selector
                  SliverAppBar(
                    pinned: true,
                    floating: true,
                    snap: true,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    backgroundColor: _isScrolled 
                        ? Colors.black.withValues(alpha: 0.50) 
                        : Colors.transparent,
                    toolbarHeight: 70,
                    automaticallyImplyLeading: false,
                    centerTitle: true,
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Dropdown Feed Selector
                        PopupMenuButton<int>(
                          onSelected: (index) {
                            if (index == 2) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Ripples - Coming Soon! 🌊'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }
                            _updateFeedIndex(index, feedProvider);
                          },
                          offset: const Offset(0, 45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.1,
                              ),
                            ),
                          ),
                          elevation: 8,
                          color: colorScheme.surface,
                          itemBuilder:
                              (context) => [
                                PopupMenuItem(
                                  value: 0,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.auto_awesome_outlined,
                                        size: 18,
                                        color:
                                            _selectedIndex == 0
                                                ? colorScheme.primary
                                                : colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'For You',
                                        style: TextStyle(
                                          fontWeight:
                                              _selectedIndex == 0
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                          color:
                                              _selectedIndex == 0
                                                  ? colorScheme.primary
                                                  : colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 1,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.people_outline_rounded,
                                        size: 18,
                                        color:
                                            _selectedIndex == 1
                                                ? colorScheme.primary
                                                : colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Following',
                                        style: TextStyle(
                                          fontWeight:
                                              _selectedIndex == 1
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                          color:
                                              _selectedIndex == 1
                                                  ? colorScheme.primary
                                                  : colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surface.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.1,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _selectedIndex == 0
                                      ? 'For You'
                                      : 'Following',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 18,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Ripples Option
                        GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Ripples - Coming Soon! 🌊'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.secondary.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: colorScheme.secondary.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.waves_rounded,
                                  size: 16,
                                  color: colorScheme.secondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Ripples',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: colorScheme.secondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      FeedLayoutSwitcher(
                        currentLayout: _currentLayout,
                        onLayoutChanged: (layout) {
                          setState(() {
                            _currentLayout = layout;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),

                  // Stories Bar
                  StoriesBar(
                    storyGroups: _storyGroups,
                    currentUserStories: _currentUserStories,
                    isLoading: _isLoadingStories,
                    onRefresh: _loadStories,
                  ),

                  // Time Capsules
                  const SliverToBoxAdapter(child: CapsuleCarousel()),

                  // Loading State
                  if (feedProvider.isLoading && feedProvider.posts.isEmpty)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    ),

                  // Error State
                  if (feedProvider.error != null && feedProvider.posts.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48),
                            const SizedBox(height: 16),
                            Text('Error: ${feedProvider.error}'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadFeed,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Empty State
                  if (!feedProvider.isLoading &&
                      feedProvider.posts.isEmpty &&
                      feedProvider.error == null)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.post_add,
                              size: 48,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No posts yet',
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Be the first to create a post!',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Posts List
                  if (feedProvider.posts.isNotEmpty)
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final post = feedProvider.posts[index];
                        return PostCard(
                          post: post,
                          isOwnPost: post.userId == userId,
                          onLike: () => _handleLike(post.id),
                          onBookmark: () => _handleBookmark(post.id),
                          onComment: () => _handleComment(post.id),
                          onShare: () => _handleShare(post.id),
                          onDelete: () => _handleDelete(post.id),
                        );
                      }, childCount: feedProvider.posts.length),
                    ),

                  // Loading More Indicator
                  if (feedProvider.isLoadingMore)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),

                  // Bottom Padding
                  SliverPadding(
                    padding: EdgeInsets.only(
                      bottom: bottomInset > 0 ? bottomInset + 16 : 92,
                    ),
                    sliver: const SliverToBoxAdapter(),
                  ),
                ],
              ),
            );

            // Desktop Split Layout
            if (ResponsiveLayout.isDesktop(context)) {
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Main Feed (Floating)
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: MaxWidthContainer(
                              maxWidth: ResponsiveLayout.maxFeedWidth,
                              child: feedContent,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Desktop Sidebar (Floating)
                    Container(
                      width: 350,
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: ListView(
                            padding: const EdgeInsets.all(20),
                            children: [
                              Text(
                                'TRENDING',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildTrendingItem('#MorrowApp', '2.4k posts'),
                              _buildTrendingItem('#OasisV2', '1.8k posts'),
                              _buildTrendingItem('#FlutterDesktop', '942 posts'),
                              const SizedBox(height: 32),
                              Text(
                                'SUGGESTED FOR YOU',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildSuggestionItem('DesignDaily', '@designdaily'),
                              _buildSuggestionItem('TechNexus', '@technexus'),
                              _buildSuggestionItem('CreativeSoul', '@creative'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            // Wrap in MaxWidthContainer for tablet
            return !ResponsiveLayout.isMobile(context)
                ? MaxWidthContainer(
                  maxWidth: ResponsiveLayout.maxFeedWidth,
                  child: feedContent,
                )
                : feedContent;
          },
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

  void _updateFeedIndex(int index, FeedProvider feedProvider) {
    setState(() => _selectedIndex = index);
    _tabController.animateTo(index);

    final userId = _authService.currentUser?.id;
    if (userId != null) {
      feedProvider.switchFeedType(
        index == 0 ? FeedType.forYou : FeedType.following,
        userId: userId,
      );
    }
  }

  Widget _buildFeedTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required ThemeData theme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _FeedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final int selectedIndex;
  final Function(int) onChanged;
  final ColorScheme colorScheme;
  final ThemeData theme;

  _FeedHeaderDelegate({
    required this.selectedIndex,
    required this.onChanged,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final isPinned = shrinkOffset > 0;
    final currentLabel = selectedIndex == 0 ? 'For You' : 'Following';

    return Container(
      color:
          isPinned
              ? theme.scaffoldBackgroundColor.withValues(alpha: 0.95)
              : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Dropdown Feed Selector
            PopupMenuButton<int>(
              onSelected: onChanged,
              offset: const Offset(0, 45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: colorScheme.onSurface.withValues(alpha: 0.1),
                ),
              ),
              elevation: 8,
              color: colorScheme.surface,
              itemBuilder:
                  (context) => [
                    PopupMenuItem(
                      value: 0,
                      child: Row(
                        children: [
                          Icon(
                            Icons.auto_awesome_outlined,
                            size: 18,
                            color:
                                selectedIndex == 0
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'For You',
                            style: TextStyle(
                              fontWeight:
                                  selectedIndex == 0
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                              color:
                                  selectedIndex == 0
                                      ? colorScheme.primary
                                      : colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 1,
                      child: Row(
                        children: [
                          Icon(
                            Icons.people_outline_rounded,
                            size: 18,
                            color:
                                selectedIndex == 1
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Following',
                            style: TextStyle(
                              fontWeight:
                                  selectedIndex == 1
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                              color:
                                  selectedIndex == 1
                                      ? colorScheme.primary
                                      : colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: colorScheme.onSurface.withValues(alpha: 0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentLabel,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Ripples Option
            GestureDetector(
              onTap: () => onChanged(2),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.secondary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.waves_rounded,
                      size: 16,
                      color: colorScheme.secondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Ripples',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  double get maxExtent => 60.0;

  @override
  double get minExtent => 60.0;

  @override
  bool shouldRebuild(covariant _FeedHeaderDelegate oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex;
  }
}

class _HeaderTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _HeaderTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

