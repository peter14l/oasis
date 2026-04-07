import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:oasis/features/feed/domain/models/comment.dart';
import 'package:oasis/services/comment_service.dart';
import 'package:oasis/services/auth_service.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:oasis/features/feed/presentation/providers/feed_provider.dart';
import 'package:oasis/services/app_initializer.dart';
import 'package:provider/provider.dart';

class CommentsModal extends StatefulWidget {
  final String postId;
  final bool isSidePane;

  const CommentsModal({
    super.key,
    required this.postId,
    this.isSidePane = false,
  });

  @override
  State<CommentsModal> createState() => _CommentsModalState();
}

class _CommentsModalState extends State<CommentsModal> {
  final CommentService _commentService = CommentService();
  final AuthService _authService = AuthService();
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Comment> _comments = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;
  Comment? _replyingTo;
  RealtimeChannel? _commentsChannel;

  @override
  void initState() {
    super.initState();
    _loadComments();
    _subscribeToComments();
  }

  @override
  void didUpdateWidget(CommentsModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.postId != oldWidget.postId) {
      if (_commentsChannel != null) {
        _commentService.unsubscribeFromComments(_commentsChannel!);
      }
      _comments = [];
      _loadComments();
      _subscribeToComments();
    }
  }

  void _subscribeToComments() {
    _commentsChannel = _commentService.subscribeToPostComments(
      postId: widget.postId,
      onCommentAdded: (commentData) {
        if (mounted) {
          try {
            final newComment = Comment.fromJson(commentData);
            if (commentData['parent_comment_id'] == null) {
              setState(() {
                _comments.insert(0, newComment);
              });
              context.read<FeedProvider>().updatePostCommentCount(widget.postId, _comments.length);
            }
          } catch (e) {
            debugPrint('Error adding comment: $e');
          }
        }
      },
      onCommentDeleted: (commentId) {
        if (mounted) {
          setState(() {
            _comments.removeWhere((c) => c.id == commentId);
          });
          context.read<FeedProvider>().updatePostCommentCount(widget.postId, _comments.length);
        }
      },
    );
  }

  Future<void> _loadComments() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final comments = await _commentService.getPostComments(
        postId: widget.postId,
        currentUserId: userId,
      );

      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoading = false;
        });
        context.read<FeedProvider>().updatePostCommentCount(widget.postId, _comments.length);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final userId = _authService.currentUser?.id;
    if (userId == null) return;

    setState(() => _isSubmitting = true);

    try {
      final comment = await _commentService.createComment(
        userId: userId,
        postId: widget.postId,
        content: _commentController.text.trim(),
        parentCommentId: _replyingTo?.id,
      );

      setState(() {
        if (_replyingTo == null) {
          _comments.insert(0, comment);
        }
        _commentController.clear();
        _replyingTo = null;
        _isSubmitting = false;
      });

      if (mounted && _replyingTo == null) {
        context.read<FeedProvider>().incrementCommentCount(widget.postId);
      }

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _likeComment(Comment comment) async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;

    try {
      if (comment.isLiked) {
        await _commentService.unlikeComment(
          userId: userId,
          commentId: comment.id,
        );
      } else {
        await _commentService.likeComment(
          userId: userId,
          commentId: comment.id,
        );
      }

      setState(() {
        final index = _comments.indexWhere((c) => c.id == comment.id);
        if (index != -1) {
          _comments[index] = comment.copyWith(
            isLiked: !comment.isLiked,
            likes: comment.isLiked ? comment.likes - 1 : comment.likes + 1,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _deleteComment(Comment comment) async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;

    try {
      await _commentService.deleteComment(
        commentId: comment.id,
        userId: userId,
      );

      setState(() {
        _comments.removeWhere((c) => c.id == comment.id);
      });

      if (mounted) {
        context.read<FeedProvider>().updatePostCommentCount(widget.postId, _comments.length);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Comment deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  void _showCommentOptions(Comment comment) {
    final userId = _authService.currentUser?.id;
    final isOwnComment = comment.userId == userId;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => SafeArea(
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.98),
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
                      if (isOwnComment) ...[
                        _buildOptionTile(
                          icon: FluentIcons.delete_24_regular,
                          title: 'Delete Comment',
                          titleColor: colorScheme.error,
                          onTap: () {
                            Navigator.pop(context);
                            _deleteComment(comment);
                          },
                        ),
                      ] else ...[
                        _buildOptionTile(
                          icon: FluentIcons.flag_24_regular,
                          title: 'Report Comment',
                          titleColor: colorScheme.error,
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Report submitted')),
                            );
                          },
                        ),
                      ],
                      _buildOptionTile(
                        icon: FluentIcons.dismiss_24_regular,
                        title: 'Cancel',
                        onTap: () => Navigator.pop(context),
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

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: titleColor ?? theme.colorScheme.onSurface, size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? theme.colorScheme.onSurface,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isSidePane) {
      return _buildMainContent(context, _scrollController);
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return _buildMainContent(context, scrollController);
      },
    );
  }

  Widget _buildMainContent(BuildContext context, ScrollController scrollController) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isM3E = themeProvider.isM3EEnabled;
    final disableTransparency = themeProvider.isM3ETransparencyDisabled;
    final userId = _authService.currentUser?.id;

    final modalContent = Container(
      decoration: BoxDecoration(
        color: widget.isSidePane
            ? Colors.transparent
            : (disableTransparency ? colorScheme.surface : colorScheme.surface.withValues(alpha: 0.85)),
        borderRadius: widget.isSidePane ? null : BorderRadius.vertical(top: Radius.circular(isM3E ? 48 : 32)),
        border: widget.isSidePane ? null : Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          // Handle and Title
          if (!widget.isSidePane)
            Container(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Comments',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: isM3E ? FontWeight.w900 : FontWeight.bold,
                      letterSpacing: isM3E ? -0.5 : 0,
                    ),
                  ),
                ],
              ),
            ),

          // Comments List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Error: $_error'))
                    : _comments.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  FluentIcons.chat_24_regular,
                                  size: 48,
                                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No comments yet',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                            itemCount: _comments.length,
                            itemBuilder: (context, index) {
                              final comment = _comments[index];
                              return _buildCommentItem(comment, userId, isM3E);
                            },
                          ),
          ),

          // Reply indicator and Input Field
          SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_replyingTo != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      color: colorScheme.primary.withValues(alpha: 0.05),
                      child: Row(
                        children: [
                          Icon(FluentIcons.arrow_reply_16_regular, size: 14, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Replying to ${_replyingTo!.username}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _replyingTo = null),
                            child: Icon(FluentIcons.dismiss_16_regular, size: 16, color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    decoration: BoxDecoration(
                      color: widget.isSidePane ? Colors.transparent : colorScheme.surface,
                      border: Border(
                        top: BorderSide(
                          color: colorScheme.onSurface.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              hintText: 'Add a comment...',
                              hintStyle: TextStyle(
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                fontSize: 15,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(isM3E ? 16 : 24),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: colorScheme.onSurface.withValues(alpha: 0.05),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            ),
                            maxLines: 4,
                            minLines: 1,
                            textCapitalization: TextCapitalization.sentences,
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton.filled(
                          onPressed: _isSubmitting ? null : _submitComment,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(FluentIcons.send_24_filled, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            minimumSize: const Size(44, 44),
                            shape: isM3E ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)) : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (widget.isSidePane || disableTransparency) {
      return modalContent;
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: modalContent,
      ),
    );
  }

  Widget _buildCommentItem(Comment comment, String? currentUserId, bool isM3E) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isM3E ? 2 : 0),
            decoration: BoxDecoration(
              shape: isM3E ? BoxShape.rectangle : BoxShape.circle,
              borderRadius: isM3E ? BorderRadius.circular(8) : null,
              border: isM3E ? Border.all(color: colorScheme.primary.withValues(alpha: 0.5), width: 1) : null,
            ),
            child: ClipRRect(
              borderRadius: isM3E ? BorderRadius.circular(6) : BorderRadius.circular(18),
              child: SizedBox(
                width: 36,
                height: 36,
                child: comment.userAvatar.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: comment.userAvatar,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        child: Center(
                          child: Text(
                            comment.username[0].toUpperCase(),
                            style: TextStyle(color: colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.username,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isM3E ? FontWeight.w900 : FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeago.format(comment.timestamp, locale: 'en_short'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _showCommentOptions(comment),
                      child: Icon(
                        FluentIcons.more_horizontal_20_regular,
                        size: 18,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                    fontSize: 14,
                    fontWeight: isM3E ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _likeComment(comment),
                      child: Row(
                        children: [
                          Icon(
                            comment.isLiked ? FluentIcons.heart_16_filled : FluentIcons.heart_16_regular,
                            size: 16,
                            color: comment.isLiked ? (isM3E ? colorScheme.tertiary : Colors.red) : colorScheme.onSurfaceVariant,
                          ),
                          if (comment.likes > 0) ...[
                            const SizedBox(width: 6),
                            Text(
                              '${comment.likes}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: comment.isLiked ? (isM3E ? colorScheme.tertiary : Colors.red) : colorScheme.onSurfaceVariant,
                                fontWeight: (isM3E || comment.isLiked) ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    GestureDetector(
                      onTap: () {
                        setState(() => _replyingTo = comment);
                      },
                      child: Text(
                        'Reply',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (_commentsChannel != null) {
      _commentService.unsubscribeFromComments(_commentsChannel!);
    }
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
