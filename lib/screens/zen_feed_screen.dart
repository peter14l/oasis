import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oasis_v2/models/post.dart';
import 'package:oasis_v2/models/feed_layout_strategy.dart';
import 'package:oasis_v2/providers/feed_provider.dart';
import 'package:oasis_v2/services/auth_service.dart';
import 'package:oasis_v2/utils/friction_scroll_physics.dart';
import 'package:oasis_v2/widgets/zen_breath_widget.dart';
import 'package:oasis_v2/widgets/energy_meter_widget.dart';
import 'package:oasis_v2/widgets/feed_layout_switcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:oasis_v2/widgets/comments_modal.dart';
import 'package:share_plus/share_plus.dart';

/// Zen Carousel feed screen - one post at a time with breath interstitials
class ZenFeedScreen extends StatefulWidget {
  final ValueChanged<FeedLayoutType>? onLayoutChanged;

  const ZenFeedScreen({super.key, this.onLayoutChanged});

  @override
  State<ZenFeedScreen> createState() => _ZenFeedScreenState();
}

class _ZenFeedScreenState extends State<ZenFeedScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  final Random _random = Random();
  late int _nextBreathIndex;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _nextBreathIndex = _calculateNextBreathIndex(0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Calculate the next index where a breath interstitial should appear
  int _calculateNextBreathIndex(int currentIndex) {
    // Random interval between 5-8 posts
    final interval = 5 + _random.nextInt(4);
    return currentIndex + interval;
  }

  /// Check if current index should show a breath interstitial
  bool _isBreathIndex(int index) {
    return index == _nextBreathIndex && index > 0;
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });

    // Load more posts when approaching the end
    final feedProvider = context.read<FeedProvider>();
    if (page >= feedProvider.posts.length - 3) {
      final authService = context.read<AuthService>();
      final userId = authService.currentUser?.id;
      if (userId != null) {
        feedProvider.loadMore(userId: userId);
      }
    }
  }

  void _onBreathComplete() {
    // Calculate next breath index
    _nextBreathIndex = _calculateNextBreathIndex(_currentPage);

    // Move to next post
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zen Carousel'),
        actions: [
          FeedLayoutSwitcher(
            currentLayout: FeedLayoutType.zenCarousel,
            onLayoutChanged: widget.onLayoutChanged ?? (layout) {},
          ),
        ],
      ),
      body: Consumer<FeedProvider>(
        builder: (context, feedProvider, _) {
          final posts = feedProvider.posts;

          if (posts.isEmpty && feedProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (posts.isEmpty) {
            return const Center(child: Text('No posts available'));
          }

          return EnergyMeterWidget(
            showLabel: true,
            child: PageView.builder(
              controller: _pageController,
              physics: const FrictionScrollPhysics(frictionFactor: 0.6),
              onPageChanged: _onPageChanged,
              itemCount: posts.length + 10, // Add buffer for breath widgets
              itemBuilder: (context, index) {
                // Show breath interstitial at designated indices
                if (_isBreathIndex(index)) {
                  return ZenBreathWidget(onComplete: _onBreathComplete);
                }

                // Calculate actual post index (accounting for breath widgets)
                final postIndex =
                    index - (index ~/ 6); // Approximate adjustment

                if (postIndex >= posts.length) {
                  return const SizedBox.shrink();
                }

                final post = posts[postIndex];
                return _ZenPostPage(post: post);
              },
            ),
          );
        },
      ),
    );
  }
}

/// Full-screen post view with adaptive backdrop
class _ZenPostPage extends StatelessWidget {
  final Post post;

  const _ZenPostPage({required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage =
        post.imageUrl != null && post.imageUrl!.isNotEmpty ||
        post.mediaUrls.isNotEmpty;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Adaptive blurred background
        if (hasImage) _buildAdaptiveBackdrop(context),

        // Main content
        SafeArea(
          child: Column(
            children: [
              // Header with user info
              _buildHeader(context),

              // Scrollable content area
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Post image
                      if (hasImage) _buildPostImage(context),

                      // Post content
                      if (post.content != null && post.content!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            post.content!,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.6,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Action buttons
              _buildActions(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdaptiveBackdrop(BuildContext context) {
    final imageUrl =
        post.mediaUrls.isNotEmpty ? post.mediaUrls.first : post.imageUrl!;

    return Positioned.fill(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: CachedNetworkImageProvider(imageUrl),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage:
                post.userAvatar.isNotEmpty
                    ? CachedNetworkImageProvider(post.userAvatar)
                    : null,
            child:
                post.userAvatar.isEmpty
                    ? Text(post.username[0].toUpperCase())
                    : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.username,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _formatTimestamp(post.timestamp),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostImage(BuildContext context) {
    final imageUrl =
        post.mediaUrls.isNotEmpty ? post.mediaUrls.first : post.imageUrl!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      constraints: const BoxConstraints(maxHeight: 500),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder:
              (context, url) => Container(
                height: 300,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Center(child: CircularProgressIndicator()),
              ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final theme = Theme.of(context);
    final feedProvider = context.read<FeedProvider>();
    final authService = context.read<AuthService>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionButton(
            context,
            icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
            label: '${post.likes}',
            color: post.isLiked ? Colors.red : null,
            onTap: () {
              final userId = authService.currentUser?.id;
              if (userId == null) return;

              if (post.isLiked) {
                feedProvider.unlikePost(userId: userId, postId: post.id);
              } else {
                feedProvider.likePost(userId: userId, postId: post.id);
              }
            },
          ),
          _buildActionButton(
            context,
            icon: Icons.chat_bubble_outline,
            label: '${post.comments}',
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useRootNavigator: true,
                backgroundColor: Colors.transparent,
                builder: (context) => CommentsModal(postId: post.id),
              );
            },
          ),
          _buildActionButton(
            context,
            icon: Icons.share_outlined,
            label: '${post.shares}',
            onTap: () {
              final deepLink = 'https://morrow.app/post/${post.id}';
              Share.share('Check out this post on Morrow! $deepLink');
            },
          ),
          _buildActionButton(
            context,
            icon: post.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            label: '',
            color: post.isBookmarked ? theme.colorScheme.primary : null,
            onTap: () {
              final userId = authService.currentUser?.id;
              if (userId == null) return;

              if (post.isBookmarked) {
                feedProvider.unbookmarkPost(userId: userId, postId: post.id);
              } else {
                feedProvider.bookmarkPost(userId: userId, postId: post.id);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            if (label.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(color: color),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
