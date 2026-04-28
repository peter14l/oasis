class UserProfileEntity {
  final String id;
  final String username;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final String? bio;
  final String? location;
  final String? website;
  final bool isVerified;
  final bool isPrivate;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final String? bannerUrl;
  final String? bannerColor;
  final String? fcmToken;
  final String? publicKey;
  final String? encryptedPrivateKey;
  final bool focusModeEnabled;
  final Map<String, dynamic>? focusModeSchedule;
  final bool windDownEnabled;
  final String? windDownTime;
  final int xp;
  final int level;
  final bool isPro;
  final String? cozyStatus;
  final String? cozyStatusText;
  final DateTime? cozyUntil;
  final String? pulseStatus;
  final String? pulseText;
  final DateTime? pulseSince;
  final bool pulseVisible;
  final String? currentMood;
  final String? moodEmoji;
  final bool fortressMode;
  final String? fortressMessage;
  final DateTime createdAt;

  String get displayName => (fullName != null && fullName!.isNotEmpty) ? fullName! : username;
  bool get hasActiveCozyStatus =>
      cozyStatus != null && cozyStatus!.isNotEmpty &&
      (cozyUntil == null || cozyUntil!.isAfter(DateTime.now()));
  bool get hasActivePulse => pulseStatus != null && pulseStatus!.isNotEmpty;

  const UserProfileEntity({
    required this.id,
    required this.username,
    required this.email,
    this.fullName,
    this.avatarUrl,
    this.bio,
    this.location,
    this.website,
    this.isVerified = false,
    this.isPrivate = false,
    this.isPro = false,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.bannerUrl,
    this.bannerColor,
    this.fcmToken,
    this.publicKey,
    this.encryptedPrivateKey,
    this.focusModeEnabled = false,
    this.focusModeSchedule,
    this.windDownEnabled = false,
    this.windDownTime,
    this.xp = 0,
    this.level = 1,
    this.cozyStatus,
    this.cozyStatusText,
    this.cozyUntil,
    this.pulseStatus,
    this.pulseText,
    this.pulseSince,
    this.pulseVisible = true,
    this.currentMood,
    this.moodEmoji,
    this.fortressMode = false,
    this.fortressMessage,
    required this.createdAt,
  });

  factory UserProfileEntity.fromJson(Map<String, dynamic> json) {
    return UserProfileEntity(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      website: json['website'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      isPrivate: json['is_private'] as bool? ?? false,
      isPro: json['is_pro'] as bool? ?? false,
      followersCount: json['followers_count'] as int? ?? 0,
      followingCount: json['following_count'] as int? ?? 0,
      postsCount: json['posts_count'] as int? ?? 0,
      bannerUrl: json['banner_url'] as String?,
      bannerColor: json['banner_color'] as String?,
      fcmToken: json['fcm_token'] as String?,
      publicKey: json['public_key'] as String?,
      encryptedPrivateKey: json['encrypted_private_key'] as String?,
      focusModeEnabled: json['focus_mode_enabled'] as bool? ?? false,
      focusModeSchedule: json['focus_mode_schedule'] as Map<String, dynamic>?,
      windDownEnabled: json['wind_down_enabled'] as bool? ?? false,
      windDownTime: json['wind_down_time'] as String?,
      xp: json['xp'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      cozyStatus: json['cozy_status'] as String?,
      cozyStatusText: json['cozy_status_text'] as String?,
      cozyUntil: json['cozy_until'] != null
          ? DateTime.parse(json['cozy_until'] as String)
          : null,
      pulseStatus: json['pulse_status'] as String?,
      pulseText: json['pulse_text'] as String?,
      pulseSince: json['pulse_since'] != null
          ? DateTime.parse(json['pulse_since'] as String)
          : null,
      pulseVisible: json['pulse_visible'] as bool? ?? true,
      currentMood: json['current_mood'] as String?,
      moodEmoji: json['mood_emoji'] as String?,
      fortressMode: json['fortress_mode'] as bool? ?? false,
      fortressMessage: json['fortress_message'] as String?,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'location': location,
      'website': website,
      'is_verified': isVerified,
      'is_private': isPrivate,
      'is_pro': isPro,
      'followers_count': followersCount,
      'following_count': followingCount,
      'posts_count': postsCount,
      'banner_url': bannerUrl,
      'banner_color': bannerColor,
      'fcm_token': fcmToken,
      'public_key': publicKey,
      'encrypted_private_key': encryptedPrivateKey,
      'focus_mode_enabled': focusModeEnabled,
      'focus_mode_schedule': focusModeSchedule,
      'wind_down_enabled': windDownEnabled,
      'wind_down_time': windDownTime,
      'xp': xp,
      'level': level,
      'cozy_status': cozyStatus,
      'cozy_status_text': cozyStatusText,
      'cozy_until': cozyUntil?.toIso8601String(),
      'pulse_status': pulseStatus,
      'pulse_text': pulseText,
      'pulse_since': pulseSince?.toIso8601String(),
      'pulse_visible': pulseVisible,
      'current_mood': currentMood,
      'mood_emoji': moodEmoji,
      'fortress_mode': fortressMode,
      'fortress_message': fortressMessage,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserProfileEntity copyWith({
    String? id,
    String? username,
    String? email,
    String? fullName,
    String? avatarUrl,
    String? bio,
    String? location,
    String? website,
    bool? isVerified,
    bool? isPrivate,
    bool? isPro,
    int? followersCount,
    int? followingCount,
    int? postsCount,
    String? bannerUrl,
    String? bannerColor,
    String? fcmToken,
    String? publicKey,
    String? encryptedPrivateKey,
    bool? focusModeEnabled,
    Map<String, dynamic>? focusModeSchedule,
    bool? windDownEnabled,
    String? windDownTime,
    int? xp,
    int? level,
    String? cozyStatus,
    String? cozyStatusText,
    DateTime? cozyUntil,
    String? pulseStatus,
    String? pulseText,
    DateTime? pulseSince,
    bool? pulseVisible,
    String? currentMood,
    String? moodEmoji,
    bool? fortressMode,
    String? fortressMessage,
    DateTime? createdAt,
  }) {
    return UserProfileEntity(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      website: website ?? this.website,
      isVerified: isVerified ?? this.isVerified,
      isPrivate: isPrivate ?? this.isPrivate,
      isPro: isPro ?? this.isPro,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      bannerColor: bannerColor ?? this.bannerColor,
      fcmToken: fcmToken ?? this.fcmToken,
      publicKey: publicKey ?? this.publicKey,
      encryptedPrivateKey: encryptedPrivateKey ?? this.encryptedPrivateKey,
      focusModeEnabled: focusModeEnabled ?? this.focusModeEnabled,
      focusModeSchedule: focusModeSchedule ?? this.focusModeSchedule,
      windDownEnabled: windDownEnabled ?? this.windDownEnabled,
      windDownTime: windDownTime ?? this.windDownTime,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      cozyStatus: cozyStatus ?? this.cozyStatus,
      cozyStatusText: cozyStatusText ?? this.cozyStatusText,
      cozyUntil: cozyUntil ?? this.cozyUntil,
      pulseStatus: pulseStatus ?? this.pulseStatus,
      pulseText: pulseText ?? this.pulseText,
      pulseSince: pulseSince ?? this.pulseSince,
      pulseVisible: pulseVisible ?? this.pulseVisible,
      currentMood: currentMood ?? this.currentMood,
      moodEmoji: moodEmoji ?? this.moodEmoji,
      fortressMode: fortressMode ?? this.fortressMode,
      fortressMessage: fortressMessage ?? this.fortressMessage,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
