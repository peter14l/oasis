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
    return (response as List<dynamic>).map((json) {
      final map = Map<String, dynamic>.from(json as Map);
      if (map['comments_count'] == null && map['comments'] != null) {
        map['comments_count'] = map['comments'];
      }
      return map;
    }).toList();
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
    return (response as List<dynamic>).map((json) {
      final map = Map<String, dynamic>.from(json as Map);
      if (map['comments_count'] == null && map['comments'] != null) {
        map['comments_count'] = map['comments'];
      }
      return map;
    }).toList();
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
          debugPrint('[FeedRemoteDatasource] Watch error: $error');
          return <Map<String, dynamic>>[];
        });
  }
}
