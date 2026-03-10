import 'package:flutter/foundation.dart';
import 'package:morrow_v2/config/supabase_config.dart';
import 'package:morrow_v2/models/post.dart';
import 'package:morrow_v2/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeedService {
  final _supabase = SupabaseService().client;

  /// Get feed posts (For You feed)
  /// Uses the get_feed_posts function from the database
  Future<List<Post>> getFeedPosts({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase.rpc(
        SupabaseConfig.getFeedPostsFn,
        params: {'p_user_id': userId, 'p_limit': limit, 'p_offset': offset},
      );

      if (response == null) return [];

      final List<dynamic> data = response as List<dynamic>;
      final posts =
          data
              .map((json) => Post.fromJson(json as Map<String, dynamic>))
              .toList();

      final user = _supabase.auth.currentUser;
      final isPro = user?.userMetadata?['is_pro'] == true;

      if (!isPro) {
        final List<Post> feedWithAds = [];
        for (int i = 0; i < posts.length; i++) {
          feedWithAds.add(posts[i]);
          if ((i + 1) % 5 == 0) {
            feedWithAds.add(
              Post(
                id: 'ad_${DateTime.now().millisecondsSinceEpoch}_$i',
                userId: 'ad_system',
                username: 'Sponsored',
                userAvatar:
                    'https://ui-avatars.com/api/?name=Ad&background=random',
                content:
                    'Get Morrow Pro to enjoy an ad-free experience, unlimited time capsules, advanced analytics, and more.',
                timestamp: DateTime.now(),
                isAd: true,
              ),
            );
          }
        }
        return feedWithAds;
      }
      return posts;
    } catch (e) {
      debugPrint('Error fetching feed posts: $e');
      rethrow;
    }
  }

  /// Get following feed posts
  /// Uses the get_following_feed_posts function from the database
  Future<List<Post>> getFollowingFeedPosts({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase.rpc(
        SupabaseConfig.getFollowingFeedPostsFn,
        params: {'p_user_id': userId, 'p_limit': limit, 'p_offset': offset},
      );

      if (response == null) return [];

      final List<dynamic> data = response as List<dynamic>;
      final posts =
          data
              .map((json) => Post.fromJson(json as Map<String, dynamic>))
              .toList();

      final user = _supabase.auth.currentUser;
      final isPro = user?.userMetadata?['is_pro'] == true;

      if (!isPro) {
        final List<Post> feedWithAds = [];
        for (int i = 0; i < posts.length; i++) {
          feedWithAds.add(posts[i]);
          if ((i + 1) % 5 == 0) {
            feedWithAds.add(
              Post(
                id: 'ad_${DateTime.now().millisecondsSinceEpoch}_$i',
                userId: 'ad_system',
                username: 'Sponsored',
                userAvatar:
                    'https://ui-avatars.com/api/?name=Ad&background=random',
                content:
                    'Get Morrow Pro to enjoy an ad-free experience, unlimited time capsules, advanced analytics, and more.',
                timestamp: DateTime.now(),
                isAd: true,
              ),
            );
          }
        }
        return feedWithAds;
      }
      return posts;
    } catch (e) {
      debugPrint('Error fetching following feed posts: $e');
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
    } catch (e) {
      debugPrint('Error liking post: $e');
      rethrow;
    }
  }

  /// Unlike a post
  Future<void> unlikePost({
    required String userId,
    required String postId,
  }) async {
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

  /// Get user's bookmarked posts
  Future<List<Post>> getBookmarkedPosts({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.bookmarksTable)
          .select('''
            post_id,
            ${SupabaseConfig.postsTable} (
              *,
              ${SupabaseConfig.profilesTable}:user_id (
                username,
                full_name,
                avatar_url
              )
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      if (response == null || response.isEmpty) return [];

      final List<Post> posts = [];
      for (final item in response) {
        final postData = item['posts'] as Map<String, dynamic>?;
        if (postData != null) {
          final profile = postData['profiles'] as Map<String, dynamic>?;
          if (profile != null) {
            postData['username'] = profile['username'];
            postData['user_avatar'] = profile['avatar_url'];
          }
          posts.add(Post.fromJson(postData));
        }
      }

      return posts;
    } catch (e) {
      debugPrint('Error fetching bookmarked posts: $e');
      rethrow;
    }
  }

  /// Delete a post
  Future<void> deletePost(String postId) async {
    try {
      await _supabase.from(SupabaseConfig.postsTable).delete().eq('id', postId);
    } catch (e) {
      debugPrint('Error deleting post: $e');
      rethrow;
    }
  }

  /// Stream feed posts for real-time updates
  Stream<List<Post>> watchFeedPosts({required String userId, int limit = 20}) {
    return _supabase
        .from(SupabaseConfig.postsTable)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(limit)
        .map((data) {
          return data.map((json) {
            // Note: This won't have user info, you'd need to join or fetch separately
            return Post.fromJson(json);
          }).toList();
        });
  }

  /// Increment post views
  Future<void> incrementViews(String postId) async {
    try {
      await _supabase.rpc('increment_post_views', params: {'post_id': postId});
    } catch (e) {
      // Silently fail for views, not critical
      debugPrint('Error incrementing views: $e');
    }
  }

  /// Share a post (increment share count)
  Future<void> sharePost(String postId) async {
    try {
      final response =
          await _supabase
              .from(SupabaseConfig.postsTable)
              .select('shares_count')
              .eq('id', postId)
              .single();

      final currentCount = response['shares_count'] as int? ?? 0;

      await _supabase
          .from(SupabaseConfig.postsTable)
          .update({'shares_count': currentCount + 1})
          .eq('id', postId);
    } catch (e) {
      debugPrint('Error sharing post: $e');
      rethrow;
    }
  }
}
