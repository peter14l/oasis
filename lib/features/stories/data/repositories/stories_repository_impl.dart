import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oasis/core/network/supabase_client.dart';
import 'package:oasis/features/stories/data/datasources/stories_remote_datasource.dart';
import 'package:oasis/features/stories/domain/models/story_entity.dart';
import 'package:oasis/features/stories/domain/repositories/stories_repository.dart';

/// Implementation of StoriesRepository.
class StoriesRepositoryImpl implements StoriesRepository {
  final StoriesRemoteDatasource _remoteDatasource;
  final SupabaseClient _supabase;

  StoriesRepositoryImpl({
    StoriesRemoteDatasource? remoteDatasource,
    SupabaseClient? supabase,
  }) : _remoteDatasource = remoteDatasource ?? StoriesRemoteDatasource(),
       _supabase = supabase ?? SupabaseService().client;

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  @override
  Future<List<StoryGroupEntity>> getFollowingStories() async {
    return _remoteDatasource.getFollowingStories();
  }

  @override
  Future<List<StoryEntity>> getUserStories(String targetUserId) async {
    return _remoteDatasource.getUserStories(targetUserId);
  }

  @override
  Future<List<StoryEntity>> getMyStories() async {
    final userId = _currentUserId;
    if (userId == null) return [];
    return _remoteDatasource.getUserStories(userId);
  }

  @override
  Future<StoryEntity?> createStory({
    required String mediaUrl,
    required String mediaType,
    String? thumbnailUrl,
    String? caption,
    int duration = 5,
  }) async {
    final userId = _currentUserId;
    if (userId == null) return null;

    return _remoteDatasource.createStory(
      userId: userId,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      thumbnailUrl: thumbnailUrl,
      caption: caption,
      duration: duration,
    );
  }

  @override
  Future<bool> viewStory(String storyId) async {
    final userId = _currentUserId;
    if (userId == null) return false;
    return _remoteDatasource.viewStory(storyId, userId);
  }

  @override
  Future<List<StoryViewerEntity>> getStoryViewers(String storyId) async {
    return _remoteDatasource.getStoryViewers(storyId);
  }

  @override
  Future<bool> deleteStory(String storyId) async {
    final userId = _currentUserId;
    if (userId == null) return false;
    return _remoteDatasource.deleteStory(storyId, userId);
  }

  @override
  Future<bool> reactToStory(String storyId, String emoji) async {
    final userId = _currentUserId;
    if (userId == null) return false;
    return _remoteDatasource.reactToStory(storyId, userId, emoji);
  }

  @override
  Future<bool> removeReaction(String storyId) async {
    final userId = _currentUserId;
    if (userId == null) return false;
    return _remoteDatasource.removeReaction(storyId, userId);
  }

  @override
  Future<void> cleanupExpiredStories() async {
    return _remoteDatasource.cleanupExpiredStories();
  }
}
