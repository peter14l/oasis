import 'package:flutter/foundation.dart';
import 'package:oasis/core/config/supabase_config.dart';
import 'package:oasis/core/network/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote datasource for feed operations.
///
/// Handles raw Supabase RPC calls and table queries for feed retrieval.
/// Does NOT handle business logic — that belongs in the repository.
class FeedRemoteDatasource {
  final SupabaseService _supabaseService = SupabaseService();
  SupabaseClient get _supabase => _supabaseService.client;

  /// Fetch "For You" feed posts via RPC function.
  Future<List<Map<String, dynamic>>> getFeedPosts({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _supabase.rpc(
      SupabaseConfig.getFeedPostsFn,
      params: {'p_user_id': userId, 'p_limit': limit, 'p_offset': offset},
    );

    if (response == null) return [];
    final posts = (response as List<dynamic>).map((json) {
      final map = Map<String, dynamic>.from(json as Map);
      if (map['comments_count'] == null && map['comments'] != null) {
        map['comments_count'] = map['comments'];
      }
      return map;
    }).toList();

    return _hydratePolls(posts);
  }

  /// Fetch "Following" feed posts via RPC function.
  Future<List<Map<String, dynamic>>> getFollowingFeedPosts({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _supabase.rpc(
      SupabaseConfig.getFollowingFeedPostsFn,
      params: {'p_user_id': userId, 'p_limit': limit, 'p_offset': offset},
    );

    if (response == null) return [];
    final posts = (response as List<dynamic>).map((json) {
      final map = Map<String, dynamic>.from(json as Map);
      if (map['comments_count'] == null && map['comments'] != null) {
        map['comments_count'] = map['comments'];
      }
      return map;
    }).toList();

    return _hydratePolls(posts);
  }

  /// Fetch unified feed posts (Following + Public).
  Future<List<Map<String, dynamic>>> getUnifiedFeed({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _supabase.rpc(
      SupabaseConfig.getUnifiedFeedFn,
      params: {'p_user_id': userId, 'p_limit': limit, 'p_offset': offset},
    );

    if (response == null) return [];
    final posts = (response as List<dynamic>).map((json) {
      final map = Map<String, dynamic>.from(json as Map);
      if (map['comments_count'] == null && map['comments'] != null) {
        map['comments_count'] = map['comments'];
      }
      return map;
    }).toList();

    return _hydratePolls(posts);
  }

  /// Hydrate posts with their corresponding polls and options.
  Future<List<Map<String, dynamic>>> _hydratePolls(
    List<Map<String, dynamic>> posts,
  ) async {
    if (posts.isEmpty) return posts;

    final postIds = posts.map((p) => p['id'] as String).toList();

    try {
      final pollsResponse = await _supabase
          .from(SupabaseConfig.pollsTable)
          .select('*, poll_options(*)')
          .inFilter('post_id', postIds);

      if (pollsResponse.isNotEmpty) {
        final pollsList = pollsResponse;
        for (final post in posts) {
          final postPolls = pollsList
              .where((poll) => poll['post_id'] == post['id'])
              .toList();
          if (postPolls.isNotEmpty) {
            post['polls'] = postPolls;
          }
        }
      }
    } catch (e) {
      debugPrint('[FeedRemoteDatasource] Poll hydration error: $e');
    }

    return posts;
  }

  /// Stream posts table for real-time updates.
  Stream<List<Map<String, dynamic>>> watchFeedPosts({
    required String userId,
    int limit = 20,
  }) {
    return _supabase
        .from(SupabaseConfig.postsTable)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(limit)
        .handleError((error) {
          debugPrint('[FeedRemoteDatasource] Realtime stream error: $error');
          return <Map<String, dynamic>>[];
        });
  }

  /// Get a single post from approximately 1 year ago for the user.
  Future<Map<String, dynamic>?> getMemoryLanePost({required String userId}) async {
    try {
      final now = DateTime.now();
      final oneYearAgo = now.subtract(const Duration(days: 365));
      final startDate = oneYearAgo.subtract(const Duration(days: 2)).toIso8601String();
      final endDate = oneYearAgo.add(const Duration(days: 2)).toIso8601String();

      // For simplicity we use the existing view or table
      // It's better to use RPC to get the joined data, but we can also just fetch from the table
      // and map it correctly. The `posts_with_stats` view is ideal if it exists, otherwise `posts`
      final response = await _supabase
          .from('posts_with_stats') // Assuming this view exists, fallback to standard posts query if not
          .select('*')
          .eq('user_id', userId)
          .gte('created_at', startDate)
          .lte('created_at', endDate)
          .order('likes_count', ascending: false) // Get their most liked post from that window
          .limit(1)
          .maybeSingle();

      if (response != null) {
        final hydrated = await _hydratePolls([response]);
        return hydrated.first;
      }
      return null;
    } catch (e) {
      // If `posts_with_stats` doesn't exist, we fallback to just `posts`
      debugPrint('[FeedRemoteDatasource] Memory Lane view error: $e, falling back to basic posts table');
      try {
        final now = DateTime.now();
        final oneYearAgo = now.subtract(const Duration(days: 365));
        final startDate = oneYearAgo.subtract(const Duration(days: 2)).toIso8601String();
        final endDate = oneYearAgo.add(const Duration(days: 2)).toIso8601String();

        final response = await _supabase
            .from(SupabaseConfig.postsTable)
            .select('*, profiles(username, avatar_url, full_name, is_verified, is_pro)')
            .eq('user_id', userId)
            .gte('created_at', startDate)
            .lte('created_at', endDate)
            .limit(1)
            .maybeSingle();

        if (response != null) {
          final map = Map<String, dynamic>.from(response);
          if (map['profiles'] != null) {
             map['username'] = map['profiles']['username'];
             map['user_avatar'] = map['profiles']['avatar_url'];
             map['full_name'] = map['profiles']['full_name'];
             map['is_verified'] = map['profiles']['is_verified'];
             map['is_pro'] = map['profiles']['is_pro'];
          }
          // We need comments/likes count, but it's okay if they are 0 for the memory lane preview
          map['likes_count'] = 0;
          map['comments_count'] = 0;

          final hydrated = await _hydratePolls([map]);
          return hydrated.first;
        }
      } catch (innerError) {
        debugPrint('[FeedRemoteDatasource] Memory Lane fallback error: $innerError');
      }
      return null;
    }
  }
}
