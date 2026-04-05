import 'package:flutter/material.dart';
import 'package:oasis/features/feed/domain/models/post.dart';

/// Enum representing different feed layout types
enum FeedLayoutType { standard, zenCarousel, pulseMap }

/// Type of interaction with a post
enum InteractionType { like, comment, share, bookmark, expand, view }

/// Abstract strategy interface for feed layout implementations
/// Allows switching between different feed visualization paradigms
abstract class FeedLayoutStrategy {
  /// The type of layout this strategy implements
  FeedLayoutType get type;

  /// Build the feed widget for the given posts
  Widget buildFeed(
    BuildContext context,
    List<Post> posts, {
    required VoidCallback onRefresh,
    required VoidCallback onLoadMore,
  });

  /// Handle post interaction events
  /// Used for tracking engagement and updating energy meter
  void onPostInteraction(Post post, InteractionType type);

  /// Dispose of any resources (controllers, subscriptions, etc.)
  void dispose();
}

/// Extension to get human-readable names for layout types
extension FeedLayoutTypeExtension on FeedLayoutType {
  String get displayName {
    switch (this) {
      case FeedLayoutType.standard:
        return 'Standard';
      case FeedLayoutType.zenCarousel:
        return 'Zen Carousel';
      case FeedLayoutType.pulseMap:
        return 'Pulse Map';
    }
  }

  IconData get icon {
    switch (this) {
      case FeedLayoutType.standard:
        return Icons.view_list;
      case FeedLayoutType.zenCarousel:
        return Icons.view_carousel;
      case FeedLayoutType.pulseMap:
        return Icons.bubble_chart;
    }
  }
}
