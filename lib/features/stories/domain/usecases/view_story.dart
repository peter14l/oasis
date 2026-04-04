import 'package:oasis_v2/features/stories/domain/models/story_entity.dart';
import 'package:oasis_v2/features/stories/domain/repositories/stories_repository.dart';

/// Use case for viewing a story (marks as viewed).
class ViewStory {
  final StoriesRepository _repository;

  ViewStory(this._repository);

  Future<bool> call(String storyId) async {
    return _repository.viewStory(storyId);
  }
}

/// Use case for getting story viewers.
class GetStoryViewers {
  final StoriesRepository _repository;

  GetStoryViewers(this._repository);

  Future<List<StoryViewerEntity>> call(String storyId) async {
    return _repository.getStoryViewers(storyId);
  }
}

/// Use case for reacting to a story.
class ReactToStory {
  final StoriesRepository _repository;

  ReactToStory(this._repository);

  Future<bool> call(String storyId, String emoji) async {
    return _repository.reactToStory(storyId, emoji);
  }
}

/// Use case for removing a story reaction.
class RemoveStoryReaction {
  final StoriesRepository _repository;

  RemoveStoryReaction(this._repository);

  Future<bool> call(String storyId) async {
    return _repository.removeReaction(storyId);
  }
}
