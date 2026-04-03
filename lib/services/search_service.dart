import 'package:flutter/foundation.dart';
import 'package:oasis_v2/core/config/supabase_config.dart';
import 'package:oasis_v2/features/feed/domain/models/post.dart';
import 'package:oasis_v2/core/network/supabase_client.dart';

class SearchService {
  final _supabase = SupabaseService().client;

  /// Search users by username or full name
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.isEmpty) return [];

    try {
      final response = await _supabase
          .from(SupabaseConfig.profilesTable)
          .select('id, username, full_name, avatar_url')
          .or('username.ilike.%$query%,full_name.ilike.%$query%')
          .limit(20);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }

  /// Search posts by content
  Future<List<Post>> searchPosts(String query) async {
    if (query.isEmpty) return [];

    try {
      final response = await _supabase
          .from(SupabaseConfig.postsTable)
          .select('''
            *,
            ${SupabaseConfig.profilesTable}:user_id (
              username,
              avatar_url
            )
          ''')
          .ilike('content', '%$query%')
          .order('created_at', ascending: false)
          .limit(20);

      if (response.isEmpty) return [];

      final List<Post> posts = [];
      for (final item in response) {
        final postMap = Map<String, dynamic>.from(item);
        final profile = postMap[SupabaseConfig.profilesTable];

        if (profile != null) {
          postMap['username'] = profile['username'];
          postMap['userAvatar'] = profile['avatar_url'];
        }

        // Map database fields to model fields if they differ
        // Note: Post.fromJson handles snake_case to camelCase mapping

        posts.add(Post.fromJson(postMap));
      }

      return posts;
    } catch (e) {
      debugPrint('Error searching posts: $e');
      return [];
    }
  }
}
