import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:morrow_v2/models/comment.dart';
import 'package:morrow_v2/services/comment_service.dart';
import 'package:morrow_v2/services/auth_service.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

class CommentsModal extends StatefulWidget {
  final String postId;

  const CommentsModal({super.key, required this.postId});

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

      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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

      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
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

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => SafeArea(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isOwnComment) ...[
                        ListTile(
                          leading: const Icon(FluentIcons.delete_24_regular),
                          title: const Text('Delete Comment'),
                          onTap: () {
                            Navigator.pop(context);
                            _deleteComment(comment);
                          },
                        ),
                      ] else ...[
                        ListTile(
                          leading: const Icon(FluentIcons.flag_24_regular),
                          title: const Text('Report Comment'),
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Report submitted')),
                            );
                          },
                        ),
                      ],
                      ListTile(
                        leading: const Icon(FluentIcons.dismiss_24_regular),
                        title: const Text('Cancel'),
                        onTap: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userId = _authService.currentUser?.id;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: colorScheme.surface.withValues(alpha: 0.7),
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Text('Comments', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? Center(child: Text('Error: $_error'))
                          : _comments.isEmpty
                              ? Center(
                                  child: Text(
                                    'No comments yet.',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _comments.length,
                                  itemBuilder: (context, index) {
                                    final comment = _comments[index];
                                    return _buildCommentItem(comment, userId);
                                  },
                                ),
                ),

                if (_replyingTo != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Replying to ${_replyingTo!.username}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(FluentIcons.dismiss_24_regular, size: 20),
                          onPressed: () => setState(() => _replyingTo = null),
                        ),
                      ],
                    ),
                  ),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.5),
                    border: Border(
                      top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1), width: 1),
                    ),
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              hintText: 'Add a comment...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            maxLines: null,
                            textCapitalization: TextCapitalization.sentences,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _isSubmitting ? null : _submitComment,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(FluentIcons.send_24_regular),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommentItem(Comment comment, String? currentUserId) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: comment.userAvatar.isNotEmpty
                ? CachedNetworkImageProvider(comment.userAvatar)
                : null,
            child: comment.userAvatar.isEmpty ? Text(comment.username[0].toUpperCase()) : null,
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
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeago.format(comment.timestamp),
                      style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(FluentIcons.more_vertical_24_regular, size: 18),
                      onPressed: () => _showCommentOptions(comment),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.content, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    InkWell(
                      onTap: () => _likeComment(comment),
                      child: Row(
                        children: [
                          Icon(
                            comment.isLiked ? FluentIcons.heart_16_filled : FluentIcons.heart_16_regular,
                            size: 16,
                            color: comment.isLiked ? Colors.red : null,
                          ),
                          if (comment.likes > 0) ...[
                            const SizedBox(width: 4),
                            Text('${comment.likes}', style: theme.textTheme.bodySmall),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: () {
                        setState(() => _replyingTo = comment);
                        FocusScope.of(context).requestFocus(FocusNode());
                      },
                      child: Text(
                        'Reply',
                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
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
