import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:oasis_v2/models/post.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:provider/provider.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:oasis_v2/providers/profile_provider.dart';
import 'package:oasis_v2/services/auth_service.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback? onLike;
  final VoidCallback? onBookmark;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;
  final bool isOwnPost;

  const PostCard({
    super.key,
    required this.post,
    this.onLike,
    this.onBookmark,
    this.onComment,
    this.onShare,
    this.onDelete,
    this.isOwnPost = false,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _likeAnimationController;
  late Animation<double> _likeAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _likeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.4).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.4, end: 1.0).chain(
          CurveTween(curve: Curves.bounceOut),
        ),
        weight: 50,
      ),
    ]).animate(_likeAnimationController);
    _currentImageIndex = 0;
  }

  int _currentImageIndex = 0;

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

  void _handleLike() {
    if (widget.post.isLiked) {
      _likeAnimationController.reverse();
    } else {
      _likeAnimationController.forward().then((_) {
        _likeAnimationController.reverse();
      });
    }
    widget.onLike?.call();
  }

  void _showMoreOptions() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: colorScheme.onSurface.withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 32,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  if (widget.isOwnPost) ...[
                    _buildMoreTile(
                      context,
                      icon: FluentIcons.delete_24_regular,
                      title: 'Delete Post',
                      titleColor: colorScheme.error,
                      onTap: () {
                        Navigator.pop(context);
                        _confirmDelete();
                      },
                    ),
                  ] else ...[
                    _buildMoreTile(
                      context,
                      icon: FluentIcons.flag_24_regular,
                      title: 'Report Post',
                      titleColor: colorScheme.error,
                      onTap: () {
                        Navigator.pop(context);
                        _showReportDialog();
                      },
                    ),
                  ],
                  _buildMoreTile(
                    context,
                    icon: FluentIcons.link_24_regular,
                    title: 'Copy Link',
                    onTap: () {
                      Navigator.pop(context);
                      _copyPostLink();
                    },
                  ),
                  _buildMoreTile(
                    context,
                    icon: FluentIcons.share_24_regular,
                    title: 'Share via...',
                    onTap: () {
                      Navigator.pop(context);
                      widget.onShare?.call();
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoreTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: titleColor ?? colorScheme.onSurface, size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? colorScheme.onSurface,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Post'),
            content: const Text(
              'Are you sure you want to delete this post? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onDelete?.call();
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Report Post'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Why are you reporting this post?'),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Spam'),
                  onTap: () {
                    Navigator.pop(context);
                    _submitReport('spam');
                  },
                ),
                ListTile(
                  title: const Text('Inappropriate content'),
                  onTap: () {
                    Navigator.pop(context);
                    _submitReport('inappropriate');
                  },
                ),
                ListTile(
                  title: const Text('Harassment'),
                  onTap: () {
                    Navigator.pop(context);
                    _submitReport('harassment');
                  },
                ),
                ListTile(
                  title: const Text('Other'),
                  onTap: () {
                    Navigator.pop(context);
                    _submitReport('other');
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  void _submitReport(String reason) {
    // In a real app, this would send the report to your backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thank you for your report. We will review it shortly.'),
      ),
    );
  }

  void _copyPostLink() {
    final postLink = 'https://oasis-web-red.vercel.app/post/${widget.post.id}';
    Clipboard.setData(ClipboardData(text: postLink));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = MediaQuery.of(context).size.width >= 1000;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: isDesktop && _isHovered ? 1.01 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.surface.withValues(alpha: 0.7),
                    colorScheme.surface.withValues(alpha: 0.4),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _isHovered 
                    ? colorScheme.primary.withValues(alpha: 0.3)
                    : colorScheme.primary.withValues(alpha: 0.1),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: _isHovered ? 0.1 : 0.05),
                    blurRadius: _isHovered ? 20 : 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap:
                              () => context.push('/profile/${widget.post.userId}'),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundImage:
                                widget.post.userAvatar.isNotEmpty
                                    ? CachedNetworkImageProvider(
                                      widget.post.userAvatar,
                                    )
                                    : null,
                            child:
                                widget.post.userAvatar.isEmpty
                                    ? Text(widget.post.username[0].toUpperCase())
                                    : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap:
                                () =>
                                    context.push('/profile/${widget.post.userId}'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      widget.post.username,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (widget.post.isVerified) ...[
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.verified,
                                        size: 16,
                                        color: colorScheme.primary,
                                      ),
                                    ],
                                    if (!widget.isOwnPost)
                                      Consumer<ProfileProvider>(
                                        builder: (context, profileProvider, child) {
                                          final isFollowing = profileProvider.following.any((p) => p.id == widget.post.userId);
                                          if (isFollowing) return const SizedBox.shrink();
                                          return Padding(
                                            padding: const EdgeInsets.only(left: 8.0),
                                            child: InkWell(
                                              onTap: () {
                                                final currentUserId = AuthService().currentUser?.id;
                                                if (currentUserId != null) {
                                                  profileProvider.followUser(
                                                    followerId: currentUserId,
                                                    followingId: widget.post.userId,
                                                  );
                                                }
                                              },
                                              child: Text(
                                                'Follow',
                                                style: theme.textTheme.labelMedium?.copyWith(
                                                  color: colorScheme.primary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                  ],
                                ),
                                Text(
                                  timeago.format(widget.post.timestamp),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(FluentIcons.more_vertical_24_regular),
                          onPressed: _showMoreOptions,
                        ),
                      ],
                    ),
                  ),

                  // Post Image(s)
                  if (widget.post.mediaUrls.isNotEmpty ||
                      (widget.post.imageUrl != null &&
                          widget.post.imageUrl!.isNotEmpty)) ...[
                    Builder(
                      builder: (context) {
                        final images =
                            widget.post.mediaUrls.isNotEmpty
                                ? widget.post.mediaUrls
                                : [widget.post.imageUrl!];

                        return Column(
                          children: [
                            GestureDetector(
                              onDoubleTap: _handleLike,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 500),
                                child:
                                    images.length > 1
                                        ? SizedBox(
                                          height: 400, // Fixed height for carousel
                                          child: PageView.builder(
                                            itemCount: images.length,
                                            onPageChanged: (index) {
                                              // You could add state here for dots if you lift this Builder out
                                            },
                                            itemBuilder: (context, index) {
                                              return CachedNetworkImage(
                                                imageUrl: images[index],
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                placeholder:
                                                    (context, url) => Container(
                                                      color:
                                                          colorScheme
                                                              .surfaceContainerHighest,
                                                      child: const Center(
                                                        child:
                                                            CircularProgressIndicator(),
                                                      ),
                                                    ),
                                                errorWidget:
                                                    (
                                                      context,
                                                      url,
                                                      error,
                                                    ) => Container(
                                                      color:
                                                          colorScheme
                                                              .surfaceContainerHighest,
                                                      child: const Center(
                                                        child: Icon(
                                                          Icons.error_outline,
                                                        ),
                                                      ),
                                                    ),
                                              );
                                            },
                                          ),
                                        )
                                        : Hero(
                                          tag: 'post_${widget.post.id}',
                                          child: CachedNetworkImage(
                                            imageUrl: images.first,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            placeholder:
                                                (context, url) => Container(
                                                  height: 300,
                                                  color:
                                                      colorScheme
                                                          .surfaceContainerHighest,
                                                  child: const Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  ),
                                                ),
                                            errorWidget:
                                                (context, url, error) => Container(
                                                  height: 300,
                                                  color:
                                                      colorScheme
                                                          .surfaceContainerHighest,
                                                  child: const Center(
                                                    child: Icon(Icons.error_outline),
                                                  ),
                                                ),
                                          ),
                                        ),
                              ),
                            ),
                            if (images.length > 1)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(images.length, (index) {
                                    return Container(
                                      width: 6,
                                      height: 6,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: colorScheme.onSurface.withValues(
                                          alpha: 0.2,
                                        ), // Simple dot for now
                                      ),
                                    );
                                  }),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],

                  // Caption (if no image or before actions)
                  if (widget.post.content != null &&
                      widget.post.content!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: RichText(
                        text: TextSpan(
                          style: theme.textTheme.bodyMedium,
                          children: [
                            TextSpan(
                              text: '${widget.post.username} ',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            TextSpan(text: widget.post.content),
                          ],
                        ),
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        ScaleTransition(
                          scale: _likeAnimation,
                          child: IconButton(
                            icon: Icon(
                              widget.post.isLiked
                                  ? FluentIcons.heart_24_filled
                                  : FluentIcons.heart_24_regular,
                              color: widget.post.isLiked ? Colors.red : null,
                            ),
                            onPressed: _handleLike,
                            iconSize: 28,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.post.likes}',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(FluentIcons.chat_24_regular),
                          onPressed: widget.onComment,
                          iconSize: 24,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.post.comments}',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(FluentIcons.share_24_regular),
                          onPressed: widget.onShare,
                          iconSize: 24,
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            widget.post.isBookmarked
                                ? FluentIcons.bookmark_24_filled
                                : FluentIcons.bookmark_24_regular,
                            color:
                                widget.post.isBookmarked
                                    ? colorScheme.primary
                                    : null,
                          ),
                          onPressed: widget.onBookmark,
                          iconSize: 24,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
