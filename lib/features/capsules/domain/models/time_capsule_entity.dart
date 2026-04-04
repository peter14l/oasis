/// Domain entity for Time Capsule
class TimeCapsuleEntity {
  final String id;
  final String userId;
  final String username;
  final String userAvatar;
  final String content;
  final String? mediaUrl;
  final String mediaType; // 'image', 'video', 'none'
  final DateTime unlockDate;
  final DateTime createdAt;
  final bool isLocked;

  const TimeCapsuleEntity({
    required this.id,
    required this.userId,
    required this.username,
    required this.userAvatar,
    required this.content,
    this.mediaUrl,
    this.mediaType = 'none',
    required this.unlockDate,
    required this.createdAt,
    required this.isLocked,
  });

  factory TimeCapsuleEntity.fromJson(Map<String, dynamic> json) {
    return TimeCapsuleEntity(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      username: json['username'] as String? ?? '',
      userAvatar: json['user_avatar'] as String? ?? '',
      content: json['content'] as String,
      mediaUrl: json['media_url'] as String?,
      mediaType: json['media_type'] as String? ?? 'none',
      unlockDate: DateTime.parse(json['unlock_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      isLocked: json['is_locked'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'username': username,
      'user_avatar': userAvatar,
      'content': content,
      'media_url': mediaUrl,
      'media_type': mediaType,
      'unlock_date': unlockDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'is_locked': isLocked,
    };
  }

  /// Helper properties to display time remaining
  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(unlockDate)) {
      return Duration.zero;
    }
    return unlockDate.difference(now);
  }

  /// Check if capsule is ready to be opened
  bool get canOpen => !isLocked && DateTime.now().isAfter(unlockDate);

  /// Check if capsule is still locked
  bool get isStillLocked => isLocked || DateTime.now().isBefore(unlockDate);

  TimeCapsuleEntity copyWith({
    String? id,
    String? userId,
    String? username,
    String? userAvatar,
    String? content,
    String? mediaUrl,
    String? mediaType,
    DateTime? unlockDate,
    DateTime? createdAt,
    bool? isLocked,
  }) {
    return TimeCapsuleEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userAvatar: userAvatar ?? this.userAvatar,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      unlockDate: unlockDate ?? this.unlockDate,
      createdAt: createdAt ?? this.createdAt,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}
