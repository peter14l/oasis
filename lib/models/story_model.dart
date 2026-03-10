class StoryModel {
  final String id;
  final String userId;
  final String username;
  final String userAvatar;
  final String mediaUrl;
  final String mediaType; // 'image' or 'video'
  final String? thumbnailUrl;
  final String? caption;
  final int duration; // seconds to display
  final DateTime createdAt;
  final DateTime expiresAt;
  final int viewCount;
  final bool hasViewed; // has current user viewed this story

  StoryModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.userAvatar,
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

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
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

  StoryModel copyWith({
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
    return StoryModel(
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

class StoryGroup {
  final String userId;
  final String username;
  final String avatarUrl;
  final List<StoryModel> stories;
  final bool hasUnviewed;
  final DateTime latestStoryAt;

  StoryGroup({
    required this.userId,
    required this.username,
    required this.avatarUrl,
    required this.stories,
    required this.hasUnviewed,
    required this.latestStoryAt,
  });

  factory StoryGroup.fromJson(Map<String, dynamic> json) {
    final storiesList =
        (json['stories'] as List<dynamic>?)?.map((s) {
          final storyMap = s as Map<String, dynamic>;
          // Inject user info into story model
          storyMap['username'] = json['username'];
          storyMap['user_avatar'] = json['avatar_url'];
          return StoryModel.fromJson(storyMap);
        }).toList() ??
        [];

    return StoryGroup(
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
