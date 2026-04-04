import 'package:oasis_v2/features/stories/domain/models/story_entity.dart';
import 'package:oasis_v2/features/stories/domain/repositories/stories_repository.dart';

/// Use case for creating a new story.
class CreateStory {
  final StoriesRepository _repository;

  CreateStory(this._repository);

  Future<StoryEntity?> call({
    required String mediaUrl,
    required String mediaType,
    String? thumbnailUrl,
    String? caption,
    int duration = 5,
  }) async {
    return _repository.createStory(
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      thumbnailUrl: thumbnailUrl,
      caption: caption,
      duration: duration,
    );
  }
}

/// Use case for deleting a story.
class DeleteStory {
  final StoriesRepository _repository;

  DeleteStory(this._repository);

  Future<bool> call(String storyId) async {
    return _repository.deleteStory(storyId);
  }
}
