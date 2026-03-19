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
          extendBodyBehindAppBar: true,
          body: CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildModernAppBar(profile, theme, colorScheme),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 120, 20, 24),
                  child: Column(
                    children: [
                      _buildProfileHeader(profile, theme, colorScheme),
                      const SizedBox(height: 24),
                      _buildStatsBar(profile, theme, colorScheme),
                      const SizedBox(height: 24),
                      _buildActivitySection(profile, theme, colorScheme),
                      const SizedBox(height: 24),
                      _buildActionButtons(profile, profileProvider, theme, colorScheme, userId),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        color: colorScheme.surface.withValues(alpha: 0.7),
                        child: TabBar(
                          controller: _tabController,
                          indicatorSize: TabBarIndicatorSize.label,
                          dividerColor: Colors.transparent,
                          labelColor: colorScheme.primary,
                          unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.4),
                          indicator: UnderlineTabIndicator(
                            borderSide: BorderSide(width: 3, color: colorScheme.primary),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          tabs: [
                            const Tab(icon: Icon(Icons.grid_view_rounded, size: 22)),
                            if (isOwnProfile)
                              const Tab(icon: Icon(Icons.bookmark_rounded, size: 22)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  48.0,
                ),
              ),
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPostsTab(userId),
                    if (isOwnProfile) _buildSavedTab(userId),
                  ],
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(UserProfile profile, ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.tertiary],
                ),
              ),
              child: CircleAvatar(
                radius: 45,
                backgroundColor: colorScheme.surface,
                backgroundImage: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(profile.avatarUrl!)
                    : null,
                child: profile.avatarUrl == null || profile.avatarUrl!.isEmpty
                    ? Text(profile.username[0].toUpperCase(), style: const TextStyle(fontSize: 24))
                    : null,
              ),
            ),
            if (profile.isPro)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.surface, width: 2),
                  ),
                  child: const Text(
                    'PRO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.fullName ?? profile.username,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '@${profile.username}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              const WellnessBadge(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsBar(UserProfile profile, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('Posts', '${profile.postsCount}', theme),
          _buildStatDivider(colorScheme),
          GestureDetector(
            onTap: () => context.push('/profile/${profile.id}/followers'),
            child: _buildStatItem('Followers', '${profile.followersCount}', theme),
          ),
          _buildStatDivider(colorScheme),
          GestureDetector(
            onTap: () => context.push('/profile/${profile.id}/following'),
            child: _buildStatItem('Following', '${profile.followingCount}', theme),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, ThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider(ColorScheme colorScheme) {
    return Container(
      height: 24,
      width: 1,
      color: colorScheme.onSurface.withValues(alpha: 0.1),
    );
  }

  Widget _buildActivitySection(UserProfile profile, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'ACTIVITY',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ActivityGraph(posts: _userPosts),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    UserProfile profile,
    ProfileProvider profileProvider,
    ThemeData theme,
    ColorScheme colorScheme,
    String? currentUserId,
  ) {
    return Row(
      children: [
        Expanded(
          child: isOwnProfile
              ? FilledButton.icon(
                  onPressed: () => context.push('/edit-profile'),
                  icon: const Icon(Icons.edit_note_rounded, size: 20),
                  label: const Text('Edit Profile'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      child: const Text('Following'),
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
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      child: const Text('Follow'),
                    )),
        ),
        const SizedBox(width: 12),
        if (!isOwnProfile && currentUserId != null) ...[
          IconButton.filledTonal(
            onPressed: () => _handleMessage(currentUserId, profile.id),
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
          ),
          const SizedBox(width: 12),
        ],
        IconButton.filledTonal(
          onPressed: () => Share.share('Check out my profile on Morrow!'),
          icon: const Icon(Icons.ios_share_rounded),
          style: IconButton.styleFrom(
            padding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
      ],
    );
  }

  Widget _buildPostsTab(String? userId) {
    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(2),
          sliver: _buildPostsGrid(_userPosts, userId),
        ),
      ],
    );
  }

  Widget _buildSavedTab(String? userId) {
    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(2),
          sliver: _buildPostsGrid(_savedPosts, userId),
        ),
      ],
    );
  }

  Widget _buildModernAppBar(
    UserProfile profile,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return SliverAppBar(
      pinned: true,
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: theme.colorScheme.surface.withValues(alpha: 0.4),
            child: Text(
              profile.username,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () => context.push('/settings'),
          ),
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
              Icon(
                Icons.grid_off_rounded,
                size: 48,
                color: Colors.grey.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No posts yet',
                style: TextStyle(color: Colors.grey.withValues(alpha: 0.5)),
              ),
            ],
          ),
        ),
      );
    }

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
          onTap: () => context.push('/post/${post.id}'),
          child: Container(
            color: Colors.black.withValues(alpha: 0.05),
            child: post.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: post.imageUrl!,
                    fit: BoxFit.cover,
                  )
                : const Center(child: Icon(Icons.text_fields, size: 20)),
          ),
        );
      }, childCount: posts.length),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar, this.backgroundColor);

  final TabBar _tabBar;
  final Color backgroundColor;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: backgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
