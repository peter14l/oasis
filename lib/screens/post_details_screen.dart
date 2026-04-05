import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:oasis/features/feed/domain/models/post.dart';
import 'package:oasis/widgets/post_card.dart';
import 'package:oasis/services/auth_service.dart';
import 'package:oasis/services/post_service.dart';
import 'package:share_plus/share_plus.dart';

class PostDetailsScreen extends StatefulWidget {
  final String postId;
  final Post? initialPost; // Optional: Pass full post object if available

  const PostDetailsScreen({super.key, required this.postId, this.initialPost});

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  final PostService _postService = PostService();
  final AuthService _authService = AuthService();
  Post? _post;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialPost != null) {
      _post = widget.initialPost;
      _isLoading = false;
    } else {
      _loadPost();
    }
  }

  Future<void> _loadPost() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) {
      if (mounted) context.pop();
      return;
    }

    try {
      final post = await _postService.getPost(widget.postId, userId);
      setState(() {
        _post = post;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleDelete() async {
    if (_post == null) return;

    // Show confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Post'),
            content: const Text('Are you sure you want to delete this post?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    final userId = _authService.currentUser?.id;
    if (userId == null) return;

    try {
      await _postService.deletePost(_post!.id, userId);
      if (mounted) {
        Navigator.pop(context); // Return to previous screen
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Post deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting post: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadPost, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_post == null) {
      return const Center(child: Text('Post not found'));
    }

    final currentUserId = _authService.currentUser?.id;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          PostCard(
            post: _post!,
            isOwnPost: _post!.userId == currentUserId,
            onLike: () async {
              final userId = _authService.currentUser?.id;
              if (userId == null || _post == null) return;

              final wasLiked = _post!.isLiked;
              final newLikes = wasLiked
                  ? (_post!.likes > 0 ? _post!.likes - 1 : 0)
                  : _post!.likes + 1;

              setState(() {
                _post = _post!.copyWith(
                  isLiked: !wasLiked,
                  likes: newLikes,
                );
              });

              try {
                if (wasLiked) {
                  await _postService.unlikePost(_post!.id, userId);
                } else {
                  await _postService.likePost(userId: userId, postId: _post!.id);
                }
              } catch (e) {
                // Revert on error
                if (mounted) {
                  setState(() {
                    _post = _post!.copyWith(
                      isLiked: wasLiked,
                      likes: wasLiked ? _post!.likes + 1 : (_post!.likes > 0 ? _post!.likes - 1 : 0),
                    );
                  });
                }
              }
            },
            onBookmark: () async {
              final userId = _authService.currentUser?.id;
              if (userId == null || _post == null) return;

              final wasBookmarked = _post!.isBookmarked;
              setState(() {
                _post = _post!.copyWith(isBookmarked: !wasBookmarked);
              });

              try {
                if (wasBookmarked) {
                  await _postService.unbookmarkPost(userId: userId, postId: _post!.id);
                } else {
                  await _postService.bookmarkPost(userId: userId, postId: _post!.id);
                }
              } catch (e) {
                // Revert on error
                if (mounted) {
                  setState(() {
                    _post = _post!.copyWith(isBookmarked: wasBookmarked);
                  });
                }
              }
            },
            onComment: () {
              // Already in details, maybe focus comment box?
              // But PostDetails IS the view.
              // If we want comment section below, we should show it here.
              // For now, duplicate behavior: go to comments screen if there is one, or Show modal.
              context.push('/post/${_post!.id}/comments');
            },
            onShare: () => Share.share('Check out this post!'),
            onDelete: _handleDelete,
          ),
        ],
      ),
    );
  }
}
