import 'package:oasis/features/feed/domain/models/post.dart';
import 'package:oasis/features/feed/domain/repositories/feed_repository.dart';

/// Get "For You" algorithmic feed posts.
class GetFeedPosts {
  final FeedRepository _repository;

  GetFeedPosts(this._repository);

  Future<List<Post>> call({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) {
    return _repository.getFeedPosts(
      userId: userId,
      limit: limit,
      offset: offset,
    );
  }
}
