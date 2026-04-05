import 'package:oasis/core/result/result.dart';
import 'package:oasis/features/search/data/datasources/search_remote_datasource.dart';
import 'package:oasis/features/search/domain/models/search_entity.dart';
import 'package:oasis/features/search/domain/repositories/search_repository.dart';
import 'package:oasis/features/feed/domain/models/post.dart';

class SearchRepositoryImpl implements SearchRepository {
  final SearchRemoteDatasource _remoteDatasource;

  SearchRepositoryImpl({SearchRemoteDatasource? remoteDatasource})
    : _remoteDatasource = remoteDatasource ?? SearchRemoteDatasource();

  @override
  Future<Result<List<SearchResult>>> searchAll(String query) async {
    try {
      final users = await _remoteDatasource.searchUsers(query);
      return Result.success(users);
    } catch (e) {
      return Result.failure(message: e.toString());
    }
  }

  @override
  Future<Result<List<SearchResult>>> searchUsers(String query) async {
    try {
      final users = await _remoteDatasource.searchUsers(query);
      return Result.success(users);
    } catch (e) {
      return Result.failure(message: e.toString());
    }
  }

  @override
  Future<Result<List<Post>>> searchPosts(String query) async {
    try {
      final posts = await _remoteDatasource.searchPosts(query);
      return Result.success(posts);
    } catch (e) {
      return Result.failure(message: e.toString());
    }
  }

  @override
  Future<Result<List<Hashtag>>> searchHashtags(String query) async {
    try {
      final hashtags = await _remoteDatasource.searchHashtags(query);
      return Result.success(hashtags);
    } catch (e) {
      return Result.failure(message: e.toString());
    }
  }

  @override
  Future<Result<List<Post>>> getHashtagPosts(String tag) async {
    try {
      final posts = await _remoteDatasource.getHashtagPosts(tag);
      return Result.success(posts);
    } catch (e) {
      return Result.failure(message: e.toString());
    }
  }

  @override
  Future<Result<List<Hashtag>>> getTrendingHashtags({int limit = 10}) async {
    try {
      final hashtags = await _remoteDatasource.getTrendingHashtags(
        limit: limit,
      );
      return Result.success(hashtags);
    } catch (e) {
      return Result.failure(message: e.toString());
    }
  }
}
