import 'package:flutter/foundation.dart';
import 'package:oasis/features/search/data/repositories/search_repository_impl.dart';
import 'package:oasis/features/search/domain/models/search_entity.dart';
import 'package:oasis/features/search/domain/repositories/search_repository.dart';
import 'package:oasis/features/search/domain/usecases/search_usecases.dart';
import 'package:oasis/features/search/presentation/providers/search_state.dart';

class SearchProvider extends ChangeNotifier {
  final SearchUsers _searchUsers;
  final SearchPosts _searchPosts;
  final SearchHashtags _searchHashtags;
  final GetTrendingHashtags _getTrendingHashtags;

  SearchState _state = const SearchState();
  SearchState get state => _state;

  SearchProvider({SearchRepository? repository})
    : _searchUsers = SearchUsers(repository ?? SearchRepositoryImpl()),
      _searchPosts = SearchPosts(repository ?? SearchRepositoryImpl()),
      _searchHashtags = SearchHashtags(repository ?? SearchRepositoryImpl()),
      _getTrendingHashtags = GetTrendingHashtags(
        repository ?? SearchRepositoryImpl(),
      ) {
    loadTrendingHashtags();
  }

  Future<void> loadTrendingHashtags() async {
    final result = await _getTrendingHashtags(limit: 10);
    result.fold(
      onFailure: (_) {},
      onSuccess: (hashtags) {
        _state = _state.copyWith(trendingHashtags: hashtags);
        notifyListeners();
      },
    );
  }

  Future<void> search(String query) async {
    if (query.isEmpty) {
      _state = _state.copyWith(
        query: '',
        loadingState: SearchLoadingState.initial,
        users: [],
        posts: [],
        hashtags: [],
      );
      notifyListeners();
      return;
    }

    _state = _state.copyWith(
      query: query,
      loadingState: SearchLoadingState.loading,
    );
    notifyListeners();

    // Run searches in parallel
    final usersFuture = _searchUsers(query);
    final postsFuture = _searchPosts(query);
    final hashtagsFuture = _searchHashtags(query);

    final usersResult = await usersFuture;
    final postsResult = await postsFuture;
    final hashtagsResult = await hashtagsFuture;

    _state = _state.copyWith(
      loadingState: SearchLoadingState.loaded,
      users: usersResult.getOrElse((_) => []),
      posts: postsResult.getOrElse((_) => []),
      hashtags: hashtagsResult.getOrElse((_) => []),
      errorMessage: null,
    );
    notifyListeners();
  }

  void setSelectedTab(int index) {
    _state = _state.copyWith(selectedTab: index);
    notifyListeners();
  }

  void clearSearch() {
    _state = const SearchState(trendingHashtags: []);
    loadTrendingHashtags();
    notifyListeners();
  }

  List<dynamic> get allResults => [..._state.users, ..._state.hashtags];
  List<SearchResult> get users => _state.users;
  List<dynamic> get posts => _state.posts;
  List<Hashtag> get hashtags => _state.hashtags;
  List<Hashtag> get trendingHashtags => _state.trendingHashtags;
}
