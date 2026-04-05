import 'package:flutter/material.dart';
import 'package:oasis/features/feed/domain/models/post.dart';

/// Immutable UI state for the feed feature.
class FeedState {
  final List<Post> forYouPosts;
  final List<Post> followingPosts;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final FeedType currentFeedType;
  final int forYouOffset;
  final int followingOffset;
  final bool hasMoreForYou;
  final bool hasMoreFollowing;

  const FeedState({
    this.forYouPosts = const [],
    this.followingPosts = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.currentFeedType = FeedType.forYou,
    this.forYouOffset = 0,
    this.followingOffset = 0,
    this.hasMoreForYou = true,
    this.hasMoreFollowing = true,
  });

  List<Post> get posts =>
      currentFeedType == FeedType.forYou ? forYouPosts : followingPosts;

  bool get hasMore =>
      currentFeedType == FeedType.forYou ? hasMoreForYou : hasMoreFollowing;

  int get offset =>
      currentFeedType == FeedType.forYou ? forYouOffset : followingOffset;

  FeedState copyWith({
    List<Post>? forYouPosts,
    List<Post>? followingPosts,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    FeedType? currentFeedType,
    int? forYouOffset,
    int? followingOffset,
    bool? hasMoreForYou,
    bool? hasMoreFollowing,
  }) {
    return FeedState(
      forYouPosts: forYouPosts ?? this.forYouPosts,
      followingPosts: followingPosts ?? this.followingPosts,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      currentFeedType: currentFeedType ?? this.currentFeedType,
      forYouOffset: forYouOffset ?? this.forYouOffset,
      followingOffset: followingOffset ?? this.followingOffset,
      hasMoreForYou: hasMoreForYou ?? this.hasMoreForYou,
      hasMoreFollowing: hasMoreFollowing ?? this.hasMoreFollowing,
    );
  }
}

enum FeedType { forYou, following }
