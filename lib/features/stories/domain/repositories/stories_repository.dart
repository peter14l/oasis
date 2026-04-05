import 'package:oasis/features/stories/domain/models/story_entity.dart';

/// Repository interface for stories - defines the contract for story operations.
abstract class StoriesRepository {
  /// Get story groups from following users.
  Future<List<StoryGroupEntity>> getFollowingStories();

  /// Get active stories for a specific user.
  Future<List<StoryEntity>> getUserStories(String targetUserId);

  /// Get current user's own stories.
  Future<List<StoryEntity>> getMyStories();

  /// Create a new story.
  Future<StoryEntity?> createStory({
    required String mediaUrl,
    required String mediaType,
    String? thumbnailUrl,
    String? caption,
    int duration = 5,
  });

  /// Mark story as viewed.
  Future<bool> viewStory(String storyId);

  /// Get viewers of a story (for story owner).
  Future<List<StoryViewerEntity>> getStoryViewers(String storyId);

  /// Delete a story.
  Future<bool> deleteStory(String storyId);

  /// React to a story with an emoji.
  Future<bool> reactToStory(String storyId, String emoji);

  /// Remove reaction from a story.
  Future<bool> removeReaction(String storyId);

  /// Clean up expired stories.
  Future<void> cleanupExpiredStories();
}
