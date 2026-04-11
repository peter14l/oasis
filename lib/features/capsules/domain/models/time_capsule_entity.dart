/// Domain entity for Time Capsule
class TimeCapsule {
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
  final Map<String, dynamic>? encryptedKeys;
  final String? iv;

  const TimeCapsule({
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
    this.encryptedKeys,
    this.iv,
  });

  factory TimeCapsule.fromJson(Map<String, dynamic> json) {
    return TimeCapsule(
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
      encryptedKeys: json['encrypted_keys'] as Map<String, dynamic>?,
      iv: json['iv'] as String?,
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
      'encrypted_keys': encryptedKeys,
      'iv': iv,
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

  TimeCapsule copyWith({
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
    Map<String, dynamic>? encryptedKeys,
    String? iv,
  }) {
    return TimeCapsule(
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
      encryptedKeys: encryptedKeys ?? this.encryptedKeys,
      iv: iv ?? this.iv,
    );
  }
}
