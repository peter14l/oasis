import 'package:oasis_v2/features/stories/domain/models/story_entity.dart';
import 'package:oasis_v2/features/stories/domain/repositories/stories_repository.dart';

/// Use case for getting following stories.
class GetFollowingStories {
  final StoriesRepository _repository;

  GetFollowingStories(this._repository);

  Future<List<StoryGroupEntity>> call() async {
    return _repository.getFollowingStories();
  }
}

/// Use case for getting user's stories.
class GetUserStories {
  final StoriesRepository _repository;

  GetUserStories(this._repository);

  Future<List<StoryEntity>> call(String userId) async {
    return _repository.getUserStories(userId);
  }
}

/// Use case for getting current user's own stories.
class GetMyStories {
  final StoriesRepository _repository;

  GetMyStories(this._repository);

  Future<List<StoryEntity>> call() async {
    return _repository.getMyStories();
  }
}
