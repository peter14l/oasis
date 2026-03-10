class UserProfile {
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
  final DateTime createdAt;

  UserProfile({
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
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.bannerUrl,
    this.bannerColor,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
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
      followersCount: json['followers_count'] as int? ?? 0,
      followingCount: json['following_count'] as int? ?? 0,
      postsCount: json['posts_count'] as int? ?? 0,
      bannerUrl: json['banner_url'] as String?,
      bannerColor: json['banner_color'] as String?,
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
      'followers_count': followersCount,
      'following_count': followingCount,
      'posts_count': postsCount,
      'banner_url': bannerUrl,
      'banner_color': bannerColor,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
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
    int? followersCount,
    int? followingCount,
    int? postsCount,
    String? bannerUrl,
    String? bannerColor,
    DateTime? createdAt,
  }) {
    return UserProfile(
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
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      bannerColor: bannerColor ?? this.bannerColor,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
