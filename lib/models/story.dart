class Story {
  final String id;
  final String userId;
  final String username;
  final String userAvatar;
  final String mediaUrl;
  final DateTime createdAt;
  final bool isViewed;

  Story({
    required this.id,
    required this.userId,
    required this.username,
    required this.userAvatar,
    required this.mediaUrl,
    required this.createdAt,
    this.isViewed = false,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      username: json['username'] as String? ?? 'Unknown',
      userAvatar: json['user_avatar'] as String? ?? '',
      mediaUrl: json['media_url'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isViewed: false, // Default to false, can be updated later
    );
  }
}
