import 'package:universal_io/io.dart';
import 'package:flutter/foundation.dart';
import 'package:oasis/core/config/supabase_config.dart';
import 'package:oasis/features/feed/domain/models/post.dart';
import 'package:oasis/core/network/supabase_client.dart';
import 'package:oasis/services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class PostService {
  final _supabase = SupabaseService().client;
  final _uuid = const Uuid();
  final NotificationService _notificationService = NotificationService();

  /// Create a new post
  Future<Post> createPost({
    required String userId,
    required String? content,
    List<File>? mediaFiles,
    List<String>? mediaTypes, // 'image' or 'video'
    String? communityId,
    String? mood,
  }) async {
    try {
      final postId = _uuid.v4();
      List<String> mediaUrls = [];
      String? firstImageUrl;

      // Upload media files if they exist
      if (mediaFiles != null && mediaFiles.isNotEmpty) {
        try {
          // Upload files in parallel
          // Note: In a real app we might want to compress videos/images first
          mediaUrls = await Future.wait(
            mediaFiles.map((file) async {
              final fileExt = file.path.split('.').last;
              final fileName = '${_uuid.v4()}.$fileExt';
              final fileBytes = await file.readAsBytes();
              final mimeType =
                  mediaTypes != null &&
                          mediaFiles.indexOf(file) < mediaTypes.length &&
                          mediaTypes[mediaFiles.indexOf(file)] == 'video'
                      ? 'video/$fileExt'
                      : 'image/$fileExt';

              await _supabase.storage
                  .from(SupabaseConfig.postImagesBucket)
                  .uploadBinary(
                    '$userId/$fileName',
                    fileBytes,
                    fileOptions: FileOptions(
                      contentType: mimeType,
                      upsert: true,
                    ),
                  );

              return _supabase.storage
                  .from(SupabaseConfig.postImagesBucket)
                  .getPublicUrl('$userId/$fileName');
            }),
          );

          // Set first image URL for backward compatibility if the first item is an image
          if (mediaTypes == null ||
              mediaTypes.isEmpty ||
              mediaTypes.first == 'image') {
            firstImageUrl = mediaUrls.isNotEmpty ? mediaUrls.first : null;
          } else {
            // Find first image for thumbnail/preview if primarily video?
            // For now, let's just leave it null if first is video, or maybe implement thumbnail generation later.
          }
        } catch (e) {
          debugPrint('Error uploading media: $e');
          throw Exception('Failed to upload media');
        }
      }

      // Create post in database
      final postData = {
        'id': postId,
        'user_id': userId,
        'community_id': communityId,
        'content': content,
        'image_url': firstImageUrl,
        'media_urls': mediaUrls,
        'media_types': mediaTypes ?? [],
        'mood': mood,
      };

      await _supabase.from(SupabaseConfig.postsTable).insert(postData);

      // Fetch the created post with user and community details
      final response =
          await _supabase
              .from(SupabaseConfig.postsTable)
              .select('''
            *,
            ${SupabaseConfig.profilesTable}:user_id (
              username,
              full_name,
              avatar_url,
              is_verified
            ),
            communities:community_id (
              name
            )
          ''')
              .eq('id', postId)
              .single();

      // Transform response to match Post model
      final postMap = Map<String, dynamic>.from(response);
      final profile = postMap[SupabaseConfig.profilesTable];
      if (profile != null) {
        postMap['username'] = profile['username'];
        postMap['user_avatar'] = profile['avatar_url'];
        postMap['is_verified'] = profile['is_verified'] ?? false;
      }

      final community = postMap['communities'];
      if (community != null) {
        postMap['community_name'] = community['name'];
      }

      final post = Post.fromJson(postMap);

      // Trigger notifications for followers
      try {
        final followersResponse = await _supabase
            .from('follows')
            .select('follower_id')
            .eq('following_id', userId);

        for (final follower in followersResponse) {
          final followerId = follower['follower_id'] as String;
          await _notificationService.createNotification(
            userId: followerId,
            type: 'post',
            actorId: userId,
            postId: postId,
          );
        }
      } catch (e) {
        debugPrint('Error triggering post notification: $e');
      }

      return post;
    } catch (e) {
      debugPrint('Error creating post: $e');
      rethrow;
    }
  }

  /// Get a single post by ID
  Future<Post> getPost(String postId, String userId) async {
    try {
      final response =
          await _supabase
              .from(SupabaseConfig.postsTable)
              .select('''
            *,
            ${SupabaseConfig.profilesTable}:user_id (
              username,
              full_name,
              avatar_url,
              is_verified
            )
          ''')
              .eq('id', postId)
              .single();

      // Transform response
      final postMap = Map<String, dynamic>.from(response);
      final profile = postMap[SupabaseConfig.profilesTable];
      if (profile != null) {
        postMap['username'] = profile['username'];
        postMap['user_avatar'] = profile['avatar_url'];
        postMap['is_verified'] = profile['is_verified'] ?? false;
      }

      // Check if user has liked/bookmarked
      final likeResponse =
          await _supabase
              .from(SupabaseConfig.likesTable)
              .select()
              .eq('post_id', postId)
              .eq('user_id', userId)
              .maybeSingle();

      final bookmarkResponse =
          await _supabase
              .from(SupabaseConfig.bookmarksTable)
              .select()
              .eq('post_id', postId)
              .eq('user_id', userId)
              .maybeSingle();

      postMap['is_liked'] = likeResponse != null;
      postMap['is_bookmarked'] = bookmarkResponse != null;

      return Post.fromJson(postMap);
    } catch (e) {
      debugPrint('Error getting post: $e');
      rethrow;
    }
  }

  /// Get user's posts
  Future<List<Post>> getUserPosts({
    required String userId,
    required String currentUserId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.postsTable)
          .select('''
            *,
            ${SupabaseConfig.profilesTable}:user_id (
              username,
              full_name,
              avatar_url,
              is_verified
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      if (response.isEmpty) return [];

      final List<Post> posts = [];
      for (final item in response) {
        final postMap = Map<String, dynamic>.from(item);
        final profile = postMap[SupabaseConfig.profilesTable];
        if (profile != null) {
          postMap['username'] = profile['username'];
          postMap['user_avatar'] = profile['avatar_url'];
          postMap['is_verified'] = profile['is_verified'] ?? false;
        }
        
        // We might want to enrich with is_liked status here too if needed, 
        // but for profile view it might be secondary.
        
        posts.add(Post.fromJson(postMap));
      }

      return posts;
    } catch (e) {
      debugPrint('Error getting user posts: $e');
      rethrow;
    }
  }

  /// Get community posts
  Future<List<Post>> getCommunityPosts({
    required String communityId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.postsTable)
          .select('''
            *,
            ${SupabaseConfig.profilesTable}:user_id (
              username,
              full_name,
              avatar_url,
              is_verified
            )
          ''')
          .eq('community_id', communityId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      if (response.isEmpty) return [];

      final List<Post> posts = [];
      for (final item in response) {
        final postMap = Map<String, dynamic>.from(item);
        final profile = postMap[SupabaseConfig.profilesTable];
        if (profile != null) {
          postMap['username'] = profile['username'];
          postMap['user_avatar'] = profile['avatar_url'];
          postMap['is_verified'] = profile['is_verified'] ?? false;
        }

        posts.add(Post.fromJson(postMap));
      }

      return posts;
    } catch (e) {
      debugPrint('Error getting community posts: $e');
      rethrow;
    }
  }

  /// Delete a post
  Future<void> deletePost(String postId, String userId) async {
    try {
      // Get post to verify ownership and get image URL
      final post =
          await _supabase
              .from(SupabaseConfig.postsTable)
              .select('user_id, image_url')
              .eq('id', postId)
              .single();

      // Verify ownership
      if (post['user_id'] != userId) {
        throw Exception('Not authorized to delete this post');
      }

      // Delete image from storage if exists
      final imageUrl = post['image_url'] as String?;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          final fileName = imageUrl.split('/').last;
          await _supabase.storage.from(SupabaseConfig.postImagesBucket).remove([
            '$userId/$fileName',
          ]);
        } catch (e) {
          debugPrint('Error deleting image: $e');
        }
      }

      // Delete post (cascades to likes, comments, bookmarks)
      await _supabase.from(SupabaseConfig.postsTable).delete().eq('id', postId);
    } catch (e) {
      debugPrint('Error deleting post: $e');
      rethrow;
    }
  }

  /// Like a post
  Future<void> likePost({
    required String userId,
    required String postId,
  }) async {
    try {
      await _supabase.from(SupabaseConfig.likesTable).insert({
        'user_id': userId,
        'post_id': postId,
      });

      // Trigger notification for post owner
      try {
        final postResponse =
            await _supabase
                .from(SupabaseConfig.postsTable)
                .select('user_id')
                .eq('id', postId)
                .single();

        final postOwnerId = postResponse['user_id'] as String;

        if (postOwnerId != userId) {
          await _notificationService.createNotification(
            userId: postOwnerId,
            type: 'like',
            actorId: userId,
            postId: postId,
          );
        }
      } catch (e) {
        debugPrint('Error triggering like notification: $e');
      }
    } catch (e) {
      debugPrint('Error liking post: $e');
      rethrow;
    }
  }

  /// Unlike a post
  Future<void> unlikePost(String postId, String userId) async {
    try {
      await _supabase
          .from(SupabaseConfig.likesTable)
          .delete()
          .eq('user_id', userId)
          .eq('post_id', postId);
    } catch (e) {
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
      await _supabase.from(SupabaseConfig.bookmarksTable).insert({
        'user_id': userId,
        'post_id': postId,
      });
    } catch (e) {
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
      await _supabase
          .from(SupabaseConfig.bookmarksTable)
          .delete()
          .eq('user_id', userId)
          .eq('post_id', postId);
    } catch (e) {
      debugPrint('Error removing bookmark: $e');
      rethrow;
    }
  }
}
