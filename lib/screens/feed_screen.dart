import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:morrow_v2/providers/feed_provider.dart';
import 'package:morrow_v2/providers/profile_provider.dart';
import 'package:morrow_v2/services/auth_service.dart';
import 'package:morrow_v2/services/stories_service.dart';
import 'package:morrow_v2/widgets/post_card.dart';
import 'package:share_plus/share_plus.dart';
import 'package:morrow_v2/models/story_model.dart';
import 'package:morrow_v2/widgets/stories_bar.dart';
import 'package:morrow_v2/widgets/capsules/capsule_carousel.dart';
import 'package:morrow_v2/models/feed_layout_strategy.dart';
import 'package:morrow_v2/widgets/feed_layout_switcher.dart';
import 'package:morrow_v2/screens/zen_feed_screen.dart';
import 'package:morrow_v2/screens/pulse_feed_screen.dart';
import 'package:morrow_v2/widgets/greyscale_wrapper.dart';
import 'package:morrow_v2/widgets/comments_modal.dart';
import 'package:morrow_v2/utils/responsive_layout.dart';

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
    Scaffold.of(context).showBottomSheet(
      (context) => CommentsModal(postId: postId),
      backgroundColor: Colors.transparent,
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
        backgroundColor: colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.3,
        ),
        appBar: AppBar(
          title: Text(
            'Feed',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 2,
          actions: [
            FeedLayoutSwitcher(
              currentLayout: _currentLayout,
              onLayoutChanged: (layout) {
                setState(() {
                  _currentLayout = layout;
                });
              },
            ),
          ],
        ),
        body: Consumer<FeedProvider>(
          builder: (context, feedProvider, child) {
            final feedContent = RefreshIndicator(
              onRefresh: _refreshFeed,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Stories Bar
                  StoriesBar(
                    storyGroups: _storyGroups,
                    currentUserStories: _currentUserStories,
                    isLoading: _isLoadingStories,
                    onRefresh: _loadStories,
                  ),

                  // Time Capsules
                  const SliverToBoxAdapter(child: CapsuleCarousel()),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: colorScheme.surface.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: colorScheme.onSurface.withValues(alpha: 0.05),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildFeedTab(
                                label: 'For You',
                                isSelected: _selectedIndex == 0,
                                onTap: () => _updateFeedIndex(0, feedProvider),
                                colorScheme: colorScheme,
                                theme: theme,
                              ),
                              _buildFeedTab(
                                label: 'Following',
                                isSelected: _selectedIndex == 1,
                                onTap: () => _updateFeedIndex(1, feedProvider),
                                colorScheme: colorScheme,
                                theme: theme,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

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

            // Wrap in MaxWidthContainer for desktop and tablet
            return !ResponsiveLayout.isMobile(context)
                ? MaxWidthContainer(
                  maxWidth: ResponsiveLayout.maxFeedWidth,
                  child: feedContent,
                )
                : feedContent;
          },
        ),
        // floatingActionButton: FloatingActionButton(
        //   onPressed: () => context.push('/create-post'),
        //   child: const Icon(Icons.add_rounded, size: 28),
        // ),
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
