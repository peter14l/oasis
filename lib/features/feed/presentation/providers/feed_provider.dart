import 'package:flutter/foundation.dart';
import 'package:oasis/features/feed/domain/models/post.dart';
import 'package:oasis/features/feed/domain/models/comment.dart';
import 'package:oasis/features/feed/domain/repositories/feed_repository.dart';
import 'package:oasis/features/feed/domain/repositories/post_repository.dart';
import 'package:oasis/features/feed/domain/repositories/comment_repository.dart';
import 'package:oasis/features/feed/data/datasources/feed_local_datasource.dart';
import 'package:oasis/features/feed/presentation/providers/feed_state.dart';

export 'package:oasis/features/feed/presentation/providers/feed_state.dart'
    show FeedType;

/// Feed feature provider managing feed state, posts, and comments.
///
/// Orchestrates use cases from the domain layer and exposes
/// state to the presentation layer.
class FeedProvider with ChangeNotifier {
  final FeedRepository _feedRepository;
  final PostRepository _postRepository;
  final CommentRepository _commentRepository;
  final FeedLocalDatasource _localDatasource;

  FeedState _state = const FeedState();
  FeedState get state => _state;

  // Proxy getters for convenience (screens access these directly on FeedProvider)
  List<Post> get posts => _state.posts;
  bool get isLoading => _state.isLoading;
  bool get isLoadingMore => _state.isLoadingMore;
  bool get hasMore => _state.hasMore;
  String? get error => _state.error;
  FeedType get currentFeedType => _state.currentFeedType;

  FeedProvider({
    required FeedRepository feedRepository,
    required PostRepository postRepository,
    required CommentRepository commentRepository,
    FeedLocalDatasource? localDatasource,
  }) : _feedRepository = feedRepository,
       _postRepository = postRepository,
       _commentRepository = commentRepository,
       _localDatasource = localDatasource ?? FeedLocalDatasource() {
    _loadFromCache();
  }

  Future<void> _loadFromCache() async {
    try {
      final cached = await _localDatasource.getFeed();
      if (cached.isNotEmpty) {
        final posts = cached.map((e) => Post.fromJson(e)).toList();
        _state = _state.copyWith(
          forYouPosts: posts,
          forYouOffset: posts.length,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[FeedProvider] Cache load error: $e');
    }
  }

  // ─── Feed Operations ──────────────────────────────────────────────

  /// Switch between For You and Following feeds.
  void switchFeedType(FeedType type, {required String userId}) {
    if (_state.currentFeedType != type) {
      _state = _state.copyWith(currentFeedType: type);
      notifyListeners();

      if (_state.posts.isEmpty && !_state.isLoading) {
        loadFeed(userId: userId);
      }
    }
  }

  /// Load initial feed.
  Future<void> loadFeed({required String userId, bool refresh = false}) async {
    if (_state.isLoading) return;

    _state = _state.copyWith(isLoading: true, error: null);
    if (refresh) {
      if (_state.currentFeedType == FeedType.forYou) {
        _state = _state.copyWith(forYouOffset: 0, hasMoreForYou: true);
      } else {
        _state = _state.copyWith(followingOffset: 0, hasMoreFollowing: true);
      }
    }
    notifyListeners();

    try {
      final List<Post> newPosts;
      if (_state.currentFeedType == FeedType.forYou) {
        final effectiveRefresh = refresh || _state.forYouPosts.isEmpty;
        newPosts = await _feedRepository.getFeedPosts(
          userId: userId,
          limit: 20,
          offset: effectiveRefresh ? 0 : _state.forYouOffset,
        );

        if (effectiveRefresh) {
          _state = _state.copyWith(forYouPosts: newPosts);
          _localDatasource.saveFeed(newPosts.map((e) => e.toJson()).toList());
        } else {
          _state = _state.copyWith(
            forYouPosts: [..._state.forYouPosts, ...newPosts],
          );
        }
        _state = _state.copyWith(
          forYouOffset: _state.forYouPosts.length,
          hasMoreForYou: newPosts.length == 20,
        );
      } else {
        newPosts = await _feedRepository.getFollowingFeedPosts(
          userId: userId,
          limit: 20,
          offset: refresh ? 0 : _state.followingOffset,
        );

        if (refresh) {
          _state = _state.copyWith(followingPosts: newPosts);
        } else {
          _state = _state.copyWith(
            followingPosts: [..._state.followingPosts, ...newPosts],
          );
        }
        _state = _state.copyWith(
          followingOffset: _state.followingPosts.length,
          hasMoreFollowing: newPosts.length == 20,
        );
      }
    } catch (e) {
      _state = _state.copyWith(error: e.toString());
      debugPrint('[FeedProvider] Load feed error: $e');
    } finally {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
    }
  }

  /// Load more posts (pagination).
  Future<void> loadMore({required String userId}) async {
    if (_state.isLoadingMore || !_state.hasMore || _state.isLoading) return;

    _state = _state.copyWith(isLoadingMore: true);
    notifyListeners();

    try {
      final List<Post> newPosts;
      if (_state.currentFeedType == FeedType.forYou) {
        newPosts = await _feedRepository.getFeedPosts(
          userId: userId,
          limit: 20,
          offset: _state.forYouOffset,
        );
        _state = _state.copyWith(
          forYouPosts: [..._state.forYouPosts, ...newPosts],
          forYouOffset: _state.forYouPosts.length + newPosts.length,
          hasMoreForYou: newPosts.length == 20,
        );
      } else {
        newPosts = await _feedRepository.getFollowingFeedPosts(
          userId: userId,
          limit: 20,
          offset: _state.followingOffset,
        );
        _state = _state.copyWith(
          followingPosts: [..._state.followingPosts, ...newPosts],
          followingOffset: _state.followingPosts.length + newPosts.length,
          hasMoreFollowing: newPosts.length == 20,
        );
      }
    } catch (e) {
      _state = _state.copyWith(error: e.toString());
      debugPrint('[FeedProvider] Load more error: $e');
    } finally {
      _state = _state.copyWith(isLoadingMore: false);
      notifyListeners();
    }
  }

  /// Refresh feed.
  Future<void> refresh({required String userId}) async {
    return loadFeed(userId: userId, refresh: true);
  }

  // ─── Post Operations ──────────────────────────────────────────────

  /// Like a post with optimistic update.
  Future<void> likePost({
    required String userId,
    required String postId,
  }) async {
    _updatePostLikeStatus(postId, true);
    notifyListeners();
    _localDatasource.saveFeed(
      _state.forYouPosts.map((e) => e.toJson()).toList(),
    );

    try {
      await _postRepository.likePost(userId: userId, postId: postId);
    } catch (e) {
      _updatePostLikeStatus(postId, false);
      notifyListeners();
      _localDatasource.saveFeed(
        _state.forYouPosts.map((e) => e.toJson()).toList(),
      );
      debugPrint('[FeedProvider] Like post error: $e');
      rethrow;
    }
  }

  /// Unlike a post with optimistic update.
  Future<void> unlikePost({
    required String userId,
    required String postId,
  }) async {
    _updatePostLikeStatus(postId, false);
    notifyListeners();
    _localDatasource.saveFeed(
      _state.forYouPosts.map((e) => e.toJson()).toList(),
    );

    try {
      await _postRepository.unlikePost(userId: userId, postId: postId);
    } catch (e) {
      _updatePostLikeStatus(postId, true);
      notifyListeners();
      _localDatasource.saveFeed(
        _state.forYouPosts.map((e) => e.toJson()).toList(),
      );
      debugPrint('[FeedProvider] Unlike post error: $e');
      rethrow;
    }
  }

  /// Bookmark a post.
  Future<void> bookmarkPost({
    required String userId,
    required String postId,
  }) async {
    _updatePostBookmarkStatus(postId, true);
    notifyListeners();
    try {
      await _postRepository.bookmarkPost(userId: userId, postId: postId);
    } catch (e) {
      _updatePostBookmarkStatus(postId, false);
      notifyListeners();
      debugPrint('[FeedProvider] Bookmark error: $e');
      rethrow;
    }
  }

  /// Remove bookmark.
  Future<void> unbookmarkPost({
    required String userId,
    required String postId,
  }) async {
    _updatePostBookmarkStatus(postId, false);
    notifyListeners();
    try {
      await _postRepository.unbookmarkPost(userId: userId, postId: postId);
    } catch (e) {
      _updatePostBookmarkStatus(postId, true);
      notifyListeners();
      debugPrint('[FeedProvider] Unbookmark error: $e');
      rethrow;
    }
  }

  /// Delete a post.
  Future<void> deletePost(String postId) async {
    try {
      await _postRepository.deletePost(postId, '');
      _state = _state.copyWith(
        forYouPosts: _state.forYouPosts.where((p) => p.id != postId).toList(),
        followingPosts:
            _state.followingPosts.where((p) => p.id != postId).toList(),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('[FeedProvider] Delete post error: $e');
      rethrow;
    }
  }

  /// Add a new post to the feed (after creation).
  void addPost(Post post) {
    _state = _state.copyWith(
      forYouPosts: [post, ..._state.forYouPosts],
      followingPosts: [post, ..._state.followingPosts],
    );
    notifyListeners();
  }

  /// Update a specific post in the feed.
  void updatePost(Post updatedPost) {
    _state = _state.copyWith(
      forYouPosts:
          _state.forYouPosts
              .map((p) => p.id == updatedPost.id ? updatedPost : p)
              .toList(),
      followingPosts:
          _state.followingPosts
              .map((p) => p.id == updatedPost.id ? updatedPost : p)
              .toList(),
    );
    notifyListeners();
  }

  /// Update comment count for a post.
  void updatePostCommentCount(String postId, int newCount) {
    void updateList(List<Post> posts) {
      for (int i = 0; i < posts.length; i++) {
        if (posts[i].id == postId) {
          posts[i] = posts[i].copyWith(comments: newCount);
          break;
        }
      }
    }

    updateList(_state.forYouPosts);
    updateList(_state.followingPosts);
    notifyListeners();
  }

  /// Clear all data.
  void clear() {
    _state = const FeedState();
    notifyListeners();
  }

  // ─── Comment Operations ───────────────────────────────────────────

  Future<List<Comment>> getComments({
    required String postId,
    required String currentUserId,
    int limit = 50,
  }) async {
    return _commentRepository.getPostComments(
      postId: postId,
      currentUserId: currentUserId,
      limit: limit,
    );
  }

  Future<Comment> createComment({
    required String userId,
    required String postId,
    required String content,
    String? parentCommentId,
  }) async {
    return _commentRepository.createComment(
      userId: userId,
      postId: postId,
      content: content,
      parentCommentId: parentCommentId,
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────

  void _updatePostLikeStatus(String postId, bool isLiked) {
    void updateList(List<Post> posts) {
      for (int i = 0; i < posts.length; i++) {
        if (posts[i].id == postId) {
          final post = posts[i];
          if (post.isLiked == isLiked) return;
          int newLikes = isLiked ? post.likes + 1 : post.likes - 1;
          if (newLikes < 0) newLikes = 0;
          posts[i] = post.copyWith(isLiked: isLiked, likes: newLikes);
          break;
        }
      }
    }

    updateList(_state.forYouPosts);
    updateList(_state.followingPosts);
  }

  void _updatePostBookmarkStatus(String postId, bool isBookmarked) {
    void updateList(List<Post> posts) {
      for (int i = 0; i < posts.length; i++) {
        if (posts[i].id == postId) {
          posts[i] = posts[i].copyWith(isBookmarked: isBookmarked);
          break;
        }
      }
    }

    updateList(_state.forYouPosts);
    updateList(_state.followingPosts);
  }
}
