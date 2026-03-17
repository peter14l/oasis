import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:oasis_v2/providers/profile_provider.dart';
import 'package:oasis_v2/services/auth_service.dart';
import 'package:oasis_v2/services/post_service.dart';
import 'package:oasis_v2/models/post.dart';
import 'package:oasis_v2/models/user_profile.dart';
import 'package:share_plus/share_plus.dart';
import 'package:oasis_v2/widgets/wellness_badge.dart';
import 'package:oasis_v2/widgets/profile/activity_graph.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final PostService _postService = PostService();
  late TabController _tabController;
  List<Post> _userPosts = [];
  final List<Post> _savedPosts = [];
  bool _isLoadingPosts = false;
  final ScrollController _scrollController = ScrollController();

  bool get isOwnProfile {
    final currentUserId = _authService.currentUser?.id;
    return widget.userId == null || widget.userId == currentUserId;
  }

  String get targetUserId => widget.userId ?? _authService.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: isOwnProfile ? 2 : 1, vsync: this);
    _loadProfile();
    _loadUserPosts();
  }

  void _loadProfile() {
    final currentUserId = _authService.currentUser?.id;
    final targetId = targetUserId;
    if (targetId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (isOwnProfile) {
          context.read<ProfileProvider>().loadCurrentProfile(targetId);
        } else if (currentUserId != null) {
          context.read<ProfileProvider>().loadProfile(targetId, currentUserId);
        }
      });
    }
  }

  Future<void> _loadUserPosts() async {
    final currentUserId = _authService.currentUser?.id;
    final targetId = targetUserId;
    if (targetId.isEmpty) return;

    setState(() => _isLoadingPosts = true);

    try {
      final posts = await _postService.getUserPosts(
        userId: targetId,
        currentUserId: currentUserId ?? '',
      );
      if (mounted) {
        setState(() {
          _userPosts = posts;
          _isLoadingPosts = false;
        });

        // Load saved posts only for own profile
        if (isOwnProfile) {
          final savedPosts = await context.read<ProfileProvider>().loadSavedPosts(
                targetId,
              );
          setState(() {
            _savedPosts.clear();
            _savedPosts.addAll(savedPosts);
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingPosts = false);
    }
  }

  Future<void> _handleMessage(String currentUserId, String targetId) async {
    try {
      final conversationId = await context.read<ProfileProvider>().getOrCreateConversation(
            user1Id: currentUserId,
            user2Id: targetId,
          );
      if (mounted) {
        context.push('/messages/$conversationId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting conversation: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userId = _authService.currentUser?.id;

    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        final profile = isOwnProfile
            ? profileProvider.currentProfile
            : profileProvider.viewedProfile;

        if (profileProvider.isLoading && profile == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (profile == null) {
          return const Scaffold(
            body: Center(child: Text('Profile not found')),
          );
        }

        return Scaffold(
          body: CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildModernAppBar(profile, theme, colorScheme),
              // Profile Card & Tabs
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildGlassProfileCard(
                        profile,
                        profileProvider,
                        theme,
                        colorScheme,
                        userId,
                      ),
                    ),
                    const SizedBox(height: 16), // Gap between card and tabs
                    TabBar(
                      controller: _tabController,
                      tabs: [
                        const Tab(icon: Icon(Icons.grid_on_rounded)),
                        if (isOwnProfile)
                          const Tab(icon: Icon(Icons.bookmark_border_rounded)),
                      ],
                    ),
                  ],
                ),
              ),
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    CustomScrollView(
                      physics: const ClampingScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          sliver: _buildPostsGrid(_userPosts, userId),
                        ),
                      ],
                    ),
                    if (isOwnProfile)
                      CustomScrollView(
                        physics: const ClampingScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            sliver: _buildPostsGrid(_savedPosts, userId),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SliverPadding(
                padding: EdgeInsets.only(bottom: 80),
              ), // Bottom spacing
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernAppBar(
    UserProfile profile,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    // bannerColor variable definition removed as it is no longer used

    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.transparent,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => context.push('/settings'),
        ),
      ],
      // flexibleSpace: FlexibleSpaceBar(
      //   background: Stack(
      //     fit: StackFit.expand,
      //     children: [
      //       // Gradient Overlay for readability
      //       // Container(
      //       //   decoration: BoxDecoration(
      //       //     gradient: LinearGradient(
      //       //       begin: Alignment.topCenter,
      //       //       end: Alignment.bottomCenter,
      //       //       colors: [
      //       //         Colors.black.withOpacity(0.3),
      //       //         Colors.transparent,
      //       //         Colors.black.withOpacity(0.1),
      //       //       ],
      //       //     ),
      //       //   ),
      //       // ),
      //       // Edit Banner Button
      //       Positioned(
      //         top: 48,
      //         right: 48, // inset from settings button
      //         child: Container(
      //           decoration: BoxDecoration(
      //             color: Colors.black.withOpacity(0.4),
      //             shape: BoxShape.circle,
      //           ),
      //           child: IconButton(
      //             icon: const Icon(Icons.edit, color: Colors.white, size: 20),
      //             onPressed: _handleEditBanner,
      //           ),
      //         ),
      //       ),
      //     ],
      //   ),
      // ),
    );
  }

  Widget _buildGlassProfileCard(
    UserProfile profile,
    ProfileProvider profileProvider,
    ThemeData theme,
    ColorScheme colorScheme,
    String? currentUserId,
  ) {
    return Column(
      children: [
        // Bento Row 1: Intro + Followers
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 2,
                child: _buildBentoCard(
                  colorScheme: colorScheme,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: profile.avatarUrl != null &&
                                    profile.avatarUrl!.isNotEmpty
                                ? CachedNetworkImageProvider(profile.avatarUrl!)
                                : null,
                            child: profile.avatarUrl == null
                                ? Text(profile.username[0].toUpperCase())
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile.fullName ?? profile.username,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '@${profile.username}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          profile.bio!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBentoCard(
                  colorScheme: colorScheme,
                  onTap: () => context.push('/profile/${profile.id}/followers'),
                  child: _buildStatColumn('Followers', '${profile.followersCount}', theme),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Bento Row 2: Following + Posts + Wellness
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildBentoCard(
                  colorScheme: colorScheme,
                  onTap: () => context.push('/profile/${profile.id}/following'),
                  child: _buildStatColumn('Following', '${profile.followingCount}', theme),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBentoCard(
                  colorScheme: colorScheme,
                  child: _buildStatColumn('Posts', '${profile.postsCount}', theme),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBentoCard(
                  colorScheme: colorScheme,
                  color: colorScheme.tertiary.withValues(alpha: 0.1),
                  child: const Center(child: WellnessBadge()),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Bento Row 3: Activity Graph
        _buildBentoCard(
          colorScheme: colorScheme,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Activity',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              ActivityGraph(posts: _userPosts),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Actions
        Row(
          children: [
            Expanded(
              child: isOwnProfile
                  ? FilledButton(
                      onPressed: () => context.push('/edit-profile'),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Edit Profile'),
                    )
                  : (profileProvider.isFollowing
                      ? OutlinedButton(
                          onPressed: () {
                            if (currentUserId != null) {
                              profileProvider.unfollowUser(
                                followerId: currentUserId,
                                followingId: profile.id,
                              );
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Unfollow'),
                        )
                      : FilledButton(
                          onPressed: () {
                            if (currentUserId != null) {
                              profileProvider.followUser(
                                followerId: currentUserId,
                                followingId: profile.id,
                              );
                            }
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Follow'),
                        )),
            ),
            if (!isOwnProfile && currentUserId != null) ...[
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: () => _handleMessage(currentUserId, profile.id),
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.message_outlined),
              ),
            ],
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: () => Share.share('Check out my profile!'),
              style: IconButton.styleFrom(
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.share_outlined),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBentoCard({
    required ColorScheme colorScheme,
    required Widget child,
    Color? color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color ?? colorScheme.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.onSurface.withValues(alpha: 0.05),
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _buildStatColumn(String label, String count, ThemeData theme) {
    return Column(
      children: [
        Text(
          count,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildPostsGrid(List<Post> posts, String? userId) {
    if (_isLoadingPosts) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (posts.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.photo_library_outlined,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text('No posts yet'),
            ],
          ),
        ),
      );
    }

    // Grid Logic
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1.0,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        final post = posts[index];
        return GestureDetector(
          onTap: () {
            // Navigation to Post Details
            context.push('/post/${post.id}');
          },
          child: Container(
            color: Colors.grey[300],
            child:
                post.imageUrl != null
                    ? CachedNetworkImage(
                      imageUrl: post.imageUrl!,
                      fit: BoxFit.cover,
                    )
                    : const Center(child: Icon(Icons.text_fields)),
          ),
        );
      }, childCount: posts.length),
    );
  }
}
