import 'package:flutter/foundation.dart';
import 'package:oasis_v2/models/post.dart';
import 'package:oasis_v2/services/feed_service.dart';
import 'package:oasis_v2/services/cache_service.dart'; // Added import

enum FeedType { forYou, following }

class FeedProvider with ChangeNotifier {
  final FeedService _feedService = FeedService();
  final CacheService _cacheService =
      CacheService(); // Added CacheService instance

  FeedProvider() {
    // Clear cache once to ensure new schema (avatar_url) is loaded
    _cacheService.saveFeed([]); 
    _loadFromCache();
  }

  Future<void> _loadFromCache() async {
    try {
      final cached = await _cacheService.getFeed();
      if (cached.isNotEmpty) {
        _forYouPosts = cached.map((e) => Post.fromJson(e)).toList();
        _forYouOffset = _forYouPosts.length;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading from cache: $e');
    }
  }

  // State
  List<Post> _forYouPosts = [];
  List<Post> _followingPosts = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  FeedType _currentFeedType = FeedType.forYou;

  // Pagination
  static const int _pageSize = 20;
  int _forYouOffset = 0;
  int _followingOffset = 0;
  bool _hasMoreForYou = true;
  bool _hasMoreFollowing = true;

  // Getters
  List<Post> get posts =>
      _currentFeedType == FeedType.forYou ? _forYouPosts : _followingPosts;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  FeedType get currentFeedType => _currentFeedType;
  bool get hasMore =>
      _currentFeedType == FeedType.forYou ? _hasMoreForYou : _hasMoreFollowing;

  /// Switch between For You and Following feeds
  void switchFeedType(FeedType type, {required String userId}) {
    if (_currentFeedType != type) {
      _currentFeedType = type;
      notifyListeners();

      // Load feed if empty
      if (posts.isEmpty && !_isLoading) {
        loadFeed(userId: userId);
      }
    }
  }

  /// Load initial feed
  Future<void> loadFeed({required String userId, bool refresh = false}) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;

    if (refresh) {
      if (_currentFeedType == FeedType.forYou) {
        _forYouOffset = 0;
        _hasMoreForYou = true;
      } else {
        _followingOffset = 0;
        _hasMoreFollowing = true;
      }
    }

    notifyListeners();

    try {
      final List<Post> newPosts;

      if (_currentFeedType == FeedType.forYou) {
        // Fetch if refresh is requested OR if we have no posts (e.g. cache was cleared)
        final effectiveRefresh = refresh || _forYouPosts.isEmpty;
        
        newPosts = await _feedService.getFeedPosts(
          userId: userId,
          limit: _pageSize,
          offset: effectiveRefresh ? 0 : _forYouOffset,
        );

        if (effectiveRefresh) {
          _forYouPosts = newPosts;
          // Save to cache
          _cacheService.saveFeed(_forYouPosts.map((e) => e.toJson()).toList());
        } else {
          _forYouPosts.addAll(newPosts);
        }

        _forYouOffset = _forYouPosts.length;
        _hasMoreForYou = newPosts.length == _pageSize;
      } else {
        newPosts = await _feedService.getFollowingFeedPosts(
          userId: userId,
          limit: _pageSize,
          offset: refresh ? 0 : _followingOffset,
        );

        if (refresh) {
          _followingPosts = newPosts;
        } else {
          _followingPosts.addAll(newPosts);
        }

        _followingOffset = _followingPosts.length;
        _hasMoreFollowing = newPosts.length == _pageSize;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading feed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load more posts (pagination)
  Future<void> loadMore({required String userId}) async {
    if (_isLoadingMore || !hasMore || _isLoading) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final List<Post> newPosts;

      if (_currentFeedType == FeedType.forYou) {
        newPosts = await _feedService.getFeedPosts(
          userId: userId,
          limit: _pageSize,
          offset: _forYouOffset,
        );

        _forYouPosts.addAll(newPosts);
        _forYouOffset = _forYouPosts.length;
        _hasMoreForYou = newPosts.length == _pageSize;
      } else {
        newPosts = await _feedService.getFollowingFeedPosts(
          userId: userId,
          limit: _pageSize,
          offset: _followingOffset,
        );

        _followingPosts.addAll(newPosts);
        _followingOffset = _followingPosts.length;
        _hasMoreFollowing = newPosts.length == _pageSize;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading more posts: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Refresh feed
  Future<void> refresh({required String userId}) async {
    return loadFeed(userId: userId, refresh: true);
  }

  /// Like a post
  Future<void> likePost({
    required String userId,
    required String postId,
  }) async {
    try {
      // Optimistic update
      _updatePostLikeStatus(postId, true);
      notifyListeners();

      await _feedService.likePost(userId: userId, postId: postId);
    } catch (e) {
      // Revert on error
      _updatePostLikeStatus(postId, false);
      notifyListeners();
      debugPrint('Error liking post: $e');
      rethrow;
    }
  }

  /// Unlike a post
  Future<void> unlikePost({
    required String userId,
    required String postId,
  }) async {
    try {
      // Optimistic update
      _updatePostLikeStatus(postId, false);
      notifyListeners();

      await _feedService.unlikePost(userId: userId, postId: postId);
    } catch (e) {
      // Revert on error
      _updatePostLikeStatus(postId, true);
      notifyListeners();
      debugPrint('Error unliking post: $e');
      rethrow;
    }
  }

  /// Bookmark a post
  Future<void> bookmarkPost({
    required String userId,
    required String postId,
  }) async {
    try {
      // Optimistic update
      _updatePostBookmarkStatus(postId, true);
      notifyListeners();

      await _feedService.bookmarkPost(userId: userId, postId: postId);
    } catch (e) {
      // Revert on error
      _updatePostBookmarkStatus(postId, false);
      notifyListeners();
      debugPrint('Error bookmarking post: $e');
      rethrow;
    }
  }

  /// Remove bookmark from a post
  Future<void> unbookmarkPost({
    required String userId,
    required String postId,
  }) async {
    try {
      // Optimistic update
      _updatePostBookmarkStatus(postId, false);
      notifyListeners();

      await _feedService.unbookmarkPost(userId: userId, postId: postId);
    } catch (e) {
      // Revert on error
      _updatePostBookmarkStatus(postId, true);
      notifyListeners();
      debugPrint('Error removing bookmark: $e');
      rethrow;
    }
  }

  /// Delete a post
  Future<void> deletePost(String postId) async {
    try {
      await _feedService.deletePost(postId);

      // Remove from local lists
      _forYouPosts.removeWhere((post) => post.id == postId);
      _followingPosts.removeWhere((post) => post.id == postId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting post: $e');
      rethrow;
    }
  }

  /// Add a new post to the feed (after creation)
  void addPost(Post post) {
    _forYouPosts.insert(0, post);
    if (_currentFeedType == FeedType.following) {
      _followingPosts.insert(0, post);
    }
    notifyListeners();
  }

  /// Helper: Update post like status
  void _updatePostLikeStatus(String postId, bool isLiked) {
    // Helper to update a list of posts
    void updateList(List<Post> posts) {
      for (int i = 0; i < posts.length; i++) {
        if (posts[i].id == postId) {
          final post = posts[i];
          // If the status is already correct, do nothing to avoid double-counting
          if (post.isLiked == isLiked) return;

          int newLikes = isLiked ? post.likes + 1 : post.likes - 1;
          if (newLikes < 0) newLikes = 0;

          posts[i] = post.copyWith(
            isLiked: isLiked,
            likes: newLikes,
          );
          break;
        }
      }
    }

    updateList(_forYouPosts);
    updateList(_followingPosts);
  }

  /// Helper: Update post bookmark status
  void _updatePostBookmarkStatus(String postId, bool isBookmarked) {
    for (var post in _forYouPosts) {
      if (post.id == postId) {
        final updatedPost = post.copyWith(isBookmarked: isBookmarked);
        final index = _forYouPosts.indexOf(post);
        _forYouPosts[index] = updatedPost;
        break;
      }
    }

    for (var post in _followingPosts) {
      if (post.id == postId) {
        final updatedPost = post.copyWith(isBookmarked: isBookmarked);
        final index = _followingPosts.indexOf(post);
        _followingPosts[index] = updatedPost;
        break;
      }
    }
  }

  /// Clear all data
  void clear() {
    _forYouPosts = [];
    _followingPosts = [];
    _forYouOffset = 0;
    _followingOffset = 0;
    _hasMoreForYou = true;
    _hasMoreFollowing = true;
    _isLoading = false;
    _isLoadingMore = false;
    _error = null;
    notifyListeners();
  }
}
