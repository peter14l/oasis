/// Story entity representing a single story (ephemeral content).
class StoryEntity {
  final String id;
  final String userId;
  final String? username;
  final String? userAvatar;
  final String mediaUrl;
  final String mediaType; // 'image' or 'video'
  final String? thumbnailUrl;
  final String? caption;
  final int duration; // seconds to display
  final DateTime createdAt;
  final DateTime expiresAt;
  final int viewCount;
  final bool hasViewed;

  const StoryEntity({
    required this.id,
    required this.userId,
    this.username,
    this.userAvatar,
    required this.mediaUrl,
    required this.mediaType,
    this.thumbnailUrl,
    this.caption,
    this.duration = 5,
    required this.createdAt,
    required this.expiresAt,
    this.viewCount = 0,
    this.hasViewed = false,
  });

  factory StoryEntity.fromJson(Map<String, dynamic> json) {
    return StoryEntity(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      username: json['username'] as String? ?? 'Unknown',
      userAvatar: json['user_avatar'] as String? ?? '',
      mediaUrl: json['media_url'] as String,
      mediaType: json['media_type'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      caption: json['caption'] as String?,
      duration: json['duration'] as int? ?? 5,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      viewCount: json['view_count'] as int? ?? 0,
      hasViewed: json['has_viewed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'username': username,
      'user_avatar': userAvatar,
      'media_url': mediaUrl,
      'media_type': mediaType,
      'thumbnail_url': thumbnailUrl,
      'caption': caption,
      'duration': duration,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'view_count': viewCount,
      'has_viewed': hasViewed,
    };
  }

  StoryEntity copyWith({
    String? id,
    String? userId,
    String? username,
    String? userAvatar,
    String? mediaUrl,
    String? mediaType,
    String? thumbnailUrl,
    String? caption,
    int? duration,
    DateTime? createdAt,
    DateTime? expiresAt,
    int? viewCount,
    bool? hasViewed,
  }) {
    return StoryEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userAvatar: userAvatar ?? this.userAvatar,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      caption: caption ?? this.caption,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      viewCount: viewCount ?? this.viewCount,
      hasViewed: hasViewed ?? this.hasViewed,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isVideo => mediaType == 'video';
  bool get isImage => mediaType == 'image';
}

/// Story group entity representing a user's story bundle.
class StoryGroupEntity {
  final String userId;
  final String username;
  final String avatarUrl;
  final List<StoryEntity> stories;
  final bool hasUnviewed;
  final DateTime latestStoryAt;

  const StoryGroupEntity({
    required this.userId,
    required this.username,
    required this.avatarUrl,
    required this.stories,
    required this.hasUnviewed,
    required this.latestStoryAt,
  });

  factory StoryGroupEntity.fromJson(Map<String, dynamic> json) {
    final storiesList =
        (json['stories'] as List<dynamic>?)?.map((s) {
          final storyMap = Map<String, dynamic>.from(s as Map);
          storyMap['username'] = json['username'];
          storyMap['user_avatar'] = json['avatar_url'];
          return StoryEntity.fromJson(storyMap);
        }).toList() ??
        [];

    return StoryGroupEntity(
      userId: json['user_id'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String? ?? '',
      stories: storiesList,
      hasUnviewed: json['has_unviewed'] as bool? ?? false,
      latestStoryAt: DateTime.parse(json['latest_story_at'] as String),
    );
  }

  int get storyCount => stories.length;
  int get unviewedCount => stories.where((s) => !s.hasViewed).length;
}

/// Story viewer entity representing someone who viewed a story.
class StoryViewerEntity {
  final String userId;
  final String username;
  final String? fullName;
  final String? avatarUrl;
  final DateTime viewedAt;

  const StoryViewerEntity({
    required this.userId,
    required this.username,
    this.fullName,
    this.avatarUrl,
    required this.viewedAt,
  });

  factory StoryViewerEntity.fromJson(
    Map<String, dynamic> json,
    String viewedAt,
  ) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return StoryViewerEntity(
      userId: json['viewer_id'] as String? ?? json['id'] as String,
      username: profile?['username'] as String? ?? 'Unknown',
      fullName: profile?['full_name'] as String?,
      avatarUrl: profile?['avatar_url'] as String?,
      viewedAt: DateTime.parse(viewedAt),
    );
  }
}
