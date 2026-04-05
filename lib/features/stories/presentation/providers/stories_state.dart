import 'package:oasis/features/stories/domain/models/story_entity.dart';

/// Immutable state class for stories feature.
class StoriesState {
  final List<StoryGroupEntity> storyGroups;
  final List<StoryEntity> userStories;
  final bool isLoading;
  final String? error;
  final String? currentStoryId;

  const StoriesState({
    this.storyGroups = const [],
    this.userStories = const [],
    this.isLoading = false,
    this.error,
    this.currentStoryId,
  });

  StoriesState copyWith({
    List<StoryGroupEntity>? storyGroups,
    List<StoryEntity>? userStories,
    bool? isLoading,
    String? error,
    String? currentStoryId,
  }) {
    return StoriesState(
      storyGroups: storyGroups ?? this.storyGroups,
      userStories: userStories ?? this.userStories,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentStoryId: currentStoryId ?? this.currentStoryId,
    );
  }
}
