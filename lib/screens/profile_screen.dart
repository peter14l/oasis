import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:morrow_v2/providers/profile_provider.dart';
import 'package:morrow_v2/services/auth_service.dart';
import 'package:morrow_v2/services/post_service.dart';
import 'package:morrow_v2/models/post.dart';
import 'package:morrow_v2/models/user_profile.dart';
import 'package:share_plus/share_plus.dart';
import 'package:morrow_v2/widgets/wellness_badge.dart';
import 'package:morrow_v2/widgets/profile/activity_graph.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfile();
    _loadUserPosts();
  }

  void _loadProfile() {
    final userId = _authService.currentUser?.id;
    if (userId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ProfileProvider>().loadCurrentProfile(userId);
      });
    }
  }

  Future<void> _loadUserPosts() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;

    setState(() => _isLoadingPosts = true);

    try {
      final posts = await _postService.getUserPosts(
        userId: userId,
        currentUserId: userId,
      );
      setState(() {
        _userPosts = posts;
        _isLoadingPosts = false;
      });

      // Load saved posts as well
      final savedPosts = await context.read<ProfileProvider>().loadSavedPosts(
        userId,
      );
      setState(() {
        _savedPosts.clear();
        _savedPosts.addAll(savedPosts);
      });
    } catch (e) {
      setState(() => _isLoadingPosts = false);
    }
  }

  void _showColorPicker() {
    final colors = [
      '#FF5733',
      '#33FF57',
      '#3357FF',
      '#F333FF',
      '#33FFF3',
      '#FFE133',
      '#000000',
      '#FFFFFF',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: colors.length,
              itemBuilder: (context, index) {
                final colorHex = colors[index];
                final color = Color(
                  int.parse(colorHex.replaceAll('#', '0xFF')),
                );
                return InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    _updateBanner(color: colorHex);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey),
                    ),
                  ),
                );
              },
            ),
          ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }

  Future<void> _updateBanner({File? file, String? color}) async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;

    try {
      await context.read<ProfileProvider>().updateProfile(
        userId: userId,
        bannerFile: file,
        bannerColor: color,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update banner: $e')));
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
        final profile = profileProvider.currentProfile;

        if (profileProvider.isLoading && profile == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (profile == null) {
          return const Scaffold(body: Center(child: Text('Profile not found')));
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
                        theme,
                        colorScheme,
                      ),
                    ),
                    const SizedBox(height: 16), // Gap between card and tabs
                    TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(icon: Icon(Icons.grid_on_rounded)),
                        Tab(icon: Icon(Icons.bookmark_border_rounded)),
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
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.6),
            border: Border.all(
              color: colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            children: [
              // Avatar (Centered)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.surface,
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage:
                      profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                          ? CachedNetworkImageProvider(profile.avatarUrl!)
                          : null,
                  child:
                      profile.avatarUrl == null
                          ? Text(
                            profile.username[0].toUpperCase(),
                            style: theme.textTheme.displaySmall,
                          )
                          : null,
                ),
              ),
              const SizedBox(height: 12),

              // Name & Handle
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    profile.fullName ?? profile.username,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (profile.isVerified) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.verified, size: 24, color: colorScheme.primary),
                  ],
                ],
              ),
              if (profile.fullName != null) ...[
                const SizedBox(height: 4),
                Text(
                  '@${profile.username}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],

              // Bio
              if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  profile.bio!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
              ],

              const SizedBox(height: 12),
              const WellnessBadge(),

              const SizedBox(height: 16),

              // Stats Row (Evenly distributed)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatColumn('Posts', '${profile.postsCount}', theme),
                  InkWell(
                    onTap:
                        () => context.push('/profile/${profile.id}/followers'),
                    child: _buildStatColumn(
                      'Followers',
                      '${profile.followersCount}',
                      theme,
                    ),
                  ),
                  InkWell(
                    onTap:
                        () => context.push('/profile/${profile.id}/following'),
                    child: _buildStatColumn(
                      'Following',
                      '${profile.followingCount}',
                      theme,
                    ),
                  ),
                ],
              ),

              if (profile.location != null || profile.website != null) ...[
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (profile.location != null &&
                        profile.location!.isNotEmpty) ...[
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: colorScheme.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        profile.location!,
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (profile.website != null) const SizedBox(width: 16),
                    ],
                    if (profile.website != null &&
                        profile.website!.isNotEmpty) ...[
                      Icon(Icons.link, size: 16, color: colorScheme.primary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          profile.website!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],

              const SizedBox(height: 24),

              // Activity Graph
              ActivityGraph(posts: _userPosts),

              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () => context.push('/edit-profile'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Edit Profile'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Share.share('Check out my profile!'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Share Profile'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
