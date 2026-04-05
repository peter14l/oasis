import 'package:oasis/features/search/domain/models/search_entity.dart';
import 'package:oasis/features/feed/domain/models/post.dart';

enum SearchLoadingState { initial, loading, loaded, error }

class SearchState {
  final String query;
  final SearchLoadingState loadingState;
  final List<SearchResult> users;
  final List<Post> posts;
  final List<Hashtag> hashtags;
  final List<Hashtag> trendingHashtags;
  final String? errorMessage;
  final int selectedTab; // 0 = all, 1 = users, 2 = posts, 3 = hashtags

  const SearchState({
    this.query = '',
    this.loadingState = SearchLoadingState.initial,
    this.users = const [],
    this.posts = const [],
    this.hashtags = const [],
    this.trendingHashtags = const [],
    this.errorMessage,
    this.selectedTab = 0,
  });

  SearchState copyWith({
    String? query,
    SearchLoadingState? loadingState,
    List<SearchResult>? users,
    List<Post>? posts,
    List<Hashtag>? hashtags,
    List<Hashtag>? trendingHashtags,
    String? errorMessage,
    int? selectedTab,
  }) {
    return SearchState(
      query: query ?? this.query,
      loadingState: loadingState ?? this.loadingState,
      users: users ?? this.users,
      posts: posts ?? this.posts,
      hashtags: hashtags ?? this.hashtags,
      trendingHashtags: trendingHashtags ?? this.trendingHashtags,
      errorMessage: errorMessage,
      selectedTab: selectedTab ?? this.selectedTab,
    );
  }
}
