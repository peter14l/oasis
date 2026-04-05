import 'package:oasis/core/config/supabase_config.dart';
import 'package:oasis/core/network/supabase_client.dart';
import 'package:oasis/features/search/domain/models/search_entity.dart';
import 'package:oasis/features/feed/domain/models/post.dart';

class SearchRemoteDatasource {
  final _supabase = SupabaseService().client;

  Future<List<SearchResult>> searchUsers(String query, {int limit = 20}) async {
    if (query.isEmpty) return [];

    final response = await _supabase
        .from(SupabaseConfig.profilesTable)
        .select('id, username, full_name, avatar_url')
        .or('username.ilike.%$query%,full_name.ilike.%$query%')
        .limit(limit);

    return (response as List)
        .map((user) => SearchResult.fromUser(user))
        .toList();
  }

  Future<List<Post>> searchPosts(String query, {int limit = 20}) async {
    if (query.isEmpty) return [];

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
        .limit(limit);

    if (response.isEmpty) return [];

    return response.map((item) {
      final postMap = Map<String, dynamic>.from(item);
      final profile = postMap[SupabaseConfig.profilesTable];
      if (profile != null) {
        postMap['user_username'] = profile['username'];
        postMap['user_avatar_url'] = profile['avatar_url'];
      }
      return Post.fromJson(postMap);
    }).toList();
  }

  Future<List<Hashtag>> searchHashtags(String query, {int limit = 10}) async {
    if (query.isEmpty) return [];

    // Search in posts for hashtags
    final postsResponse = await _supabase
        .from(SupabaseConfig.postsTable)
        .select('content')
        .ilike('content', '%#$query%')
        .limit(100);

    // Extract hashtags and count occurrences
    final Map<String, int> hashtagCounts = {};
    for (final post in postsResponse) {
      final content = post['content'] as String? ?? '';
      final regex = RegExp(r'#(\w+)');
      final matches = regex.allMatches(content);
      for (final match in matches) {
        final tag = match.group(1)!.toLowerCase();
        if (tag.contains(query.toLowerCase())) {
          hashtagCounts[tag] = (hashtagCounts[tag] ?? 0) + 1;
        }
      }
    }

    return hashtagCounts.entries
        .map((e) => Hashtag(tag: e.key, postCount: e.value))
        .toList()
      ..sort((a, b) => b.postCount.compareTo(a.postCount));
  }

  Future<List<Post>> getHashtagPosts(String tag, {int limit = 20}) async {
    final response = await _supabase
        .from(SupabaseConfig.postsTable)
        .select('''
          *,
          ${SupabaseConfig.profilesTable}:user_id (
            username,
            avatar_url
          )
        ''')
        .ilike('content', '%#$tag%')
        .order('created_at', ascending: false)
        .limit(limit);

    if (response.isEmpty) return [];

    return response.map((item) {
      final postMap = Map<String, dynamic>.from(item);
      final profile = postMap[SupabaseConfig.profilesTable];
      if (profile != null) {
        postMap['user_username'] = profile['username'];
        postMap['user_avatar_url'] = profile['avatar_url'];
      }
      return Post.fromJson(postMap);
    }).toList();
  }

  Future<List<Hashtag>> getTrendingHashtags({int limit = 10}) async {
    // Get recent posts and extract trending hashtags
    final postsResponse = await _supabase
        .from(SupabaseConfig.postsTable)
        .select('content, created_at')
        .order('created_at', ascending: false)
        .limit(500);

    final Map<String, int> hashtagCounts = {};
    for (final post in postsResponse) {
      final content = post['content'] as String? ?? '';
      final regex = RegExp(r'#(\w+)');
      final matches = regex.allMatches(content);
      for (final match in matches) {
        final tag = match.group(1)!.toLowerCase();
        hashtagCounts[tag] = (hashtagCounts[tag] ?? 0) + 1;
      }
    }

    return hashtagCounts.entries
        .take(limit)
        .map((e) => Hashtag(tag: e.key, postCount: e.value))
        .toList();
  }
}
