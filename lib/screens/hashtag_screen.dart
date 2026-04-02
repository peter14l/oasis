import 'package:flutter/material.dart';
import 'package:oasis_v2/models/hashtag.dart';
import 'package:oasis_v2/models/post.dart';
import 'package:oasis_v2/services/hashtag_service.dart';
import 'package:oasis_v2/widgets/post_card.dart';
import 'package:oasis_v2/widgets/comments_modal.dart';
import 'package:oasis_v2/widgets/share_sheet.dart';

class HashtagScreen extends StatefulWidget {
  final String tag;

  const HashtagScreen({super.key, required this.tag});

  @override
  State<HashtagScreen> createState() => _HashtagScreenState();
}

class _HashtagScreenState extends State<HashtagScreen> {
  final _hashtagService = HashtagService();
  Hashtag? _hashtag;
  List<Post> _posts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _offset = 0;
  final int _limit = 20;

  @override
  void initState() {
    super.initState();
    _loadHashtagData();
  }

  Future<void> _loadHashtagData() async {
    setState(() => _isLoading = true);

    try {
      // Load hashtag details
      final hashtag = await _hashtagService.getHashtagDetails(widget.tag);

      // Load posts
      final postsData = await _hashtagService.getPostsByHashtag(
        widget.tag,
        limit: _limit,
        offset: 0,
      );

      if (mounted) {
        setState(() {
          _hashtag = hashtag;
          _posts = postsData.map((data) => _parsePost(data)).toList();
          _offset = postsData.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading hashtag: $e')));
      }
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final postsData = await _hashtagService.getPostsByHashtag(
        widget.tag,
        limit: _limit,
        offset: _offset,
      );

      if (mounted) {
        setState(() {
          _posts.addAll(postsData.map((data) => _parsePost(data)));
          _offset += postsData.length;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  Post _parsePost(Map<String, dynamic> data) {
    final profile = data['profiles'] as Map<String, dynamic>?;
    return Post(
      id: data['id'] as String,
      userId: data['user_id'] as String,
      username: profile?['username'] as String? ?? 'Unknown',
      userAvatar: profile?['avatar_url'] as String? ?? '',
      content: data['content'] as String?,
      imageUrl: data['image_url'] as String?,
      timestamp: DateTime.parse(data['created_at'] as String),
      likes: data['likes_count'] as int? ?? 0,
      comments: data['comments_count'] as int? ?? 0,
      shares: data['shares_count'] as int? ?? 0,
      isLiked: data['is_liked'] as bool? ?? false,
      isBookmarked: data['is_bookmarked'] as bool? ?? false,
    );
  }

  void _handleLike(Post post) {
    final index = _posts.indexWhere((p) => p.id == post.id);
    if (index == -1) return;

    setState(() {
      _posts[index] = post.copyWith(
        isLiked: !post.isLiked,
        likes: post.isLiked ? post.likes - 1 : post.likes + 1,
      );
    });

    // TODO: Call post service like endpoint
    // For now, just update local state (optimistic update)
  }

  void _handleComment(Post post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsModal(postId: post.id),
    );
  }

  void _handleShare(Post post) {
    final shareText = post.content ?? '#${widget.tag}';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => ShareSheet(
            title: 'Share Post',
            payload: shareText,
            externalMessage: post.imageUrl,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('#${widget.tag}')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                slivers: [
                  // Hashtag info header
                  if (_hashtag != null)
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.1),
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '#${_hashtag!.tag}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_hashtag!.usageCount} ${_hashtag!.usageCount == 1 ? 'post' : 'posts'}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Posts list
                  if (_posts.isEmpty)
                    const SliverFillRemaining(
                      child: Center(child: Text('No posts found')),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        if (index == _posts.length) {
                          // Load more indicator
                          if (_isLoadingMore) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          } else {
                            // Load more trigger
                            _loadMorePosts();
                            return const SizedBox.shrink();
                          }
                        }

                        return PostCard(
                          post: _posts[index],
                          onLike: () => _handleLike(_posts[index]),
                          onComment: () => _handleComment(_posts[index]),
                          onShare: () => _handleShare(_posts[index]),
                        );
                      }, childCount: _posts.length + 1),
                    ),
                ],
              ),
    );
  }
}
