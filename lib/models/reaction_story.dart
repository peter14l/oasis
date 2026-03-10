/// Model for Reaction Stories
class ReactionStory {
  final String id;
  final String userId;
  final String username;
  final String? avatarUrl;
  final String mediaUrl;
  final StoryMediaType mediaType;
  final List<StoryReaction> reactions;
  final int reactionCount;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool hasViewed;
  final bool hasReacted;
  final String? caption;
  final String? musicUrl;
  final String? musicTitle;

  ReactionStory({
    required this.id,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.mediaUrl,
    this.mediaType = StoryMediaType.image,
    this.reactions = const [],
    this.reactionCount = 0,
    required this.createdAt,
    required this.expiresAt,
    this.hasViewed = false,
    this.hasReacted = false,
    this.caption,
    this.musicUrl,
    this.musicTitle,
  });

  factory ReactionStory.fromJson(Map<String, dynamic> json) {
    return ReactionStory(
      id: json['id'],
      userId: json['user_id'],
      username: json['username'] ?? 'Unknown',
      avatarUrl: json['avatar_url'],
      mediaUrl: json['media_url'],
      mediaType: StoryMediaType.fromString(json['media_type'] ?? 'image'),
      reactions:
          (json['reactions'] as List?)
              ?.map((r) => StoryReaction.fromJson(r))
              .toList() ??
          [],
      reactionCount: json['reaction_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      expiresAt: DateTime.parse(json['expires_at']),
      hasViewed: json['has_viewed'] ?? false,
      hasReacted: json['has_reacted'] ?? false,
      caption: json['caption'],
      musicUrl: json['music_url'],
      musicTitle: json['music_title'],
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isActive => !isExpired;

  Duration get timeRemaining => expiresAt.difference(DateTime.now());

  String get timeRemainingText {
    final remaining = timeRemaining;
    if (remaining.isNegative) return 'Expired';
    if (remaining.inHours > 0) return '${remaining.inHours}h';
    return '${remaining.inMinutes}m';
  }
}

enum StoryMediaType {
  image('image'),
  video('video'),
  text('text');

  final String value;
  const StoryMediaType(this.value);

  static StoryMediaType fromString(String value) {
    return StoryMediaType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => StoryMediaType.image,
    );
  }
}

class StoryReaction {
  final String id;
  final String storyId;
  final String userId;
  final String username;
  final String? avatarUrl;
  final String emoji;
  final DateTime createdAt;

  StoryReaction({
    required this.id,
    required this.storyId,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.emoji,
    required this.createdAt,
  });

  factory StoryReaction.fromJson(Map<String, dynamic> json) {
    return StoryReaction(
      id: json['id'],
      storyId: json['story_id'],
      userId: json['user_id'],
      username: json['username'] ?? 'Unknown',
      avatarUrl: json['avatar_url'],
      emoji: json['emoji'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

/// Story reaction options
class StoryReactionEmojis {
  static const List<String> emojis = [
    '❤️',
    '🔥',
    '😂',
    '😍',
    '😢',
    '😮',
    '👏',
    '💯',
  ];

  static const Map<String, String> emojiLabels = {
    '❤️': 'Love',
    '🔥': 'Fire',
    '😂': 'Laugh',
    '😍': 'Heart Eyes',
    '😢': 'Sad',
    '😮': 'Wow',
    '👏': 'Clap',
    '💯': 'Perfect',
  };
}

/// Grouped story reactions for display
class GroupedStoryReaction {
  final String emoji;
  final int count;
  final List<String> recentUsernames;
  final bool includesCurrentUser;

  GroupedStoryReaction({
    required this.emoji,
    required this.count,
    required this.recentUsernames,
    this.includesCurrentUser = false,
  });

  factory GroupedStoryReaction.fromReactions(
    String emoji,
    List<StoryReaction> reactions,
    String currentUserId,
  ) {
    return GroupedStoryReaction(
      emoji: emoji,
      count: reactions.length,
      recentUsernames: reactions.take(3).map((r) => r.username).toList(),
      includesCurrentUser: reactions.any((r) => r.userId == currentUserId),
    );
  }
}
