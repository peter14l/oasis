import 'package:oasis/core/result/result.dart';
import 'package:oasis/features/search/domain/models/search_entity.dart';
import 'package:oasis/features/search/domain/repositories/search_repository.dart';
import 'package:oasis/features/feed/domain/models/post.dart';

class SearchUsers {
  final SearchRepository _repository;

  SearchUsers(this._repository);

  Future<Result<List<SearchResult>>> call(String query) {
    return _repository.searchUsers(query);
  }
}

class SearchPosts {
  final SearchRepository _repository;

  SearchPosts(this._repository);

  Future<Result<List<Post>>> call(String query) {
    return _repository.searchPosts(query);
  }
}

class SearchHashtags {
  final SearchRepository _repository;

  SearchHashtags(this._repository);

  Future<Result<List<Hashtag>>> call(String query) {
    return _repository.searchHashtags(query);
  }
}

class GetHashtagPosts {
  final SearchRepository _repository;

  GetHashtagPosts(this._repository);

  Future<Result<List<Post>>> call(String tag) {
    return _repository.getHashtagPosts(tag);
  }
}

class GetTrendingHashtags {
  final SearchRepository _repository;

  GetTrendingHashtags(this._repository);

  Future<Result<List<Hashtag>>> call({int limit = 10}) {
    return _repository.getTrendingHashtags(limit: limit);
  }
}
