import 'package:oasis/features/feed/domain/models/post.dart';

/// Repository contract for feed operations.
///
/// Defines feed retrieval and caching. Implementations
/// live in the data layer.
abstract class FeedRepository {
  /// Get "For You" feed posts (algorithmic).
  Future<List<Post>> getFeedPosts({
    required String userId,
    int limit = 20,
    int offset = 0,
  });

  /// Get "Following" feed posts (chronological).
  Future<List<Post>> getFollowingFeedPosts({
    required String userId,
    int limit = 20,
    int offset = 0,
  });

  /// Get unified feed posts (merged).
  Future<List<Post>> getUnifiedFeed({
    required String userId,
    int limit = 20,
    int offset = 0,
  });

  /// Stream feed posts for real-time updates.
  Stream<List<Post>> watchFeedPosts({required String userId, int limit = 20});
}
