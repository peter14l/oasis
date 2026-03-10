class AppUser {
  final String id;
  final String username;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? bio;
  final String? location;
  final String? website;
  final DateTime? joinedDate;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final bool isVerified;
  final bool isPrivate;
  final String? bannerUrl;
  final String? bannerColor;
  final bool isPro;

  AppUser({
    required this.id,
    required this.username,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.bio,
    this.location,
    this.website,
    this.joinedDate,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.isVerified = false,
    this.isPrivate = false,
    this.bannerUrl,
    this.bannerColor,
    this.isPro = false,
  });

  String get displayNameOrUsername => displayName ?? username;

  AppUser copyWith({
    String? id,
    String? username,
    String? email,
    String? displayName,
    String? photoUrl,
    String? bio,
    String? location,
    String? website,
    DateTime? joinedDate,
    int? followersCount,
    int? followingCount,
    int? postsCount,
    bool? isVerified,
    bool? isPrivate,
    String? bannerUrl,
    String? bannerColor,
    bool? isPro,
  }) {
    return AppUser(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      website: website ?? this.website,
      joinedDate: joinedDate ?? this.joinedDate,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      isVerified: isVerified ?? this.isVerified,
      isPrivate: isPrivate ?? this.isPrivate,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      bannerColor: bannerColor ?? this.bannerColor,
      isPro: isPro ?? this.isPro,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'bio': bio,
      'location': location,
      'website': website,
      'joinedDate': joinedDate?.toIso8601String(),
      'followersCount': followersCount,
      'followingCount': followingCount,
      'postsCount': postsCount,
      'isVerified': isVerified,
      'isPrivate': isPrivate,
      'banner_url': bannerUrl,
      'banner_color': bannerColor,
      'isPro': isPro,
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      website: json['website'] as String?,
      joinedDate:
          json['joinedDate'] != null
              ? DateTime.parse(json['joinedDate'] as String)
              : null,
      followersCount: (json['followersCount'] as int?) ?? 0,
      followingCount: (json['followingCount'] as int?) ?? 0,
      postsCount: (json['postsCount'] as int?) ?? 0,
      isVerified: (json['isVerified'] as bool?) ?? false,
      isPrivate: (json['isPrivate'] as bool?) ?? false,
      bannerUrl: json['banner_url'] as String?,
      bannerColor: json['banner_color'] as String?,
      isPro: (json['isPro'] as bool?) ?? false,
    );
  }

  static final AppUser empty = AppUser(id: '', username: '', email: '');

  bool get isEmpty => this == AppUser.empty;
  bool get isNotEmpty => this != AppUser.empty;
}
