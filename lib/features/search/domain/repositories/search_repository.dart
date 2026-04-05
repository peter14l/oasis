import 'package:oasis/core/result/result.dart';
import 'package:oasis/features/search/domain/models/search_entity.dart';
import 'package:oasis/features/feed/domain/models/post.dart';

abstract class SearchRepository {
  Future<Result<List<SearchResult>>> searchAll(String query);
  Future<Result<List<SearchResult>>> searchUsers(String query);
  Future<Result<List<Post>>> searchPosts(String query);
  Future<Result<List<Hashtag>>> searchHashtags(String query);
  Future<Result<List<Post>>> getHashtagPosts(String tag);
  Future<Result<List<Hashtag>>> getTrendingHashtags({int limit = 10});
}
