import 'package:oasis_v2/features/feed/domain/models/post.dart';
import 'package:oasis_v2/features/feed/domain/repositories/feed_repository.dart';

/// Get "Following" chronological feed posts.
class GetFollowingPosts {
  final FeedRepository _repository;

  GetFollowingPosts(this._repository);

  Future<List<Post>> call({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) {
    return _repository.getFollowingFeedPosts(
      userId: userId,
      limit: limit,
      offset: offset,
    );
  }
}
