class Post {
  final String id;
  final String userId;
  final String username;
  final String userAvatar;
  final String? content;
  final String? imageUrl;
  final String? thumbnailUrl; // Low-res preview for Pulse Map orbs
  final String? dominantColor; // Hex color for adaptive backdrops
  final List<String> mediaUrls;
  final List<String> mediaTypes; // 'image' or 'video'
  final String? communityId;
  final String? communityName;
  final DateTime timestamp;
  final int likes;
  final int comments;
  final int shares;
  final bool isLiked;
  final bool isBookmarked;
  final bool isAd;
  final bool isVerified;
  final String? mood;

  Post({
    required this.id,
    required this.userId,
    required this.username,
    required this.userAvatar,
    this.content,
    this.imageUrl,
    this.thumbnailUrl,
    this.dominantColor,
    this.mediaUrls = const [],
    this.mediaTypes = const [],
    this.communityId,
    this.communityName,
    required this.timestamp,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.isLiked = false,
    this.isBookmarked = false,
    this.isAd = false,
    this.isVerified = false,
    this.mood,
  });

  Post copyWith({
    String? id,
    String? userId,
    String? username,
    String? userAvatar,
    String? content,
    String? imageUrl,
    String? thumbnailUrl,
    String? dominantColor,
    List<String>? mediaUrls,
    List<String>? mediaTypes,
    String? communityId,
    String? communityName,
    DateTime? timestamp,
    int? likes,
    int? comments,
    int? shares,
    bool? isLiked,
    bool? isBookmarked,
    bool? isAd,
    bool? isVerified,
    String? mood,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userAvatar: userAvatar ?? this.userAvatar,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      dominantColor: dominantColor ?? this.dominantColor,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      mediaTypes: mediaTypes ?? this.mediaTypes,
      communityId: communityId ?? this.communityId,
      communityName: communityName ?? this.communityName,
      timestamp: timestamp ?? this.timestamp,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isAd: isAd ?? this.isAd,
      isVerified: isVerified ?? this.isVerified,
      mood: mood ?? this.mood,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'userAvatar': userAvatar,
      'content': content,
      'imageUrl': imageUrl,
      'thumbnail_url': thumbnailUrl,
      'dominant_color': dominantColor,
      'media_urls': mediaUrls,
      'media_types': mediaTypes,
      'community_id': communityId,
      'community_name': communityName,
      'timestamp': timestamp.toIso8601String(),
      'likes': likes,
      'comments': comments,
      'shares': shares,
      'isLiked': isLiked,
      'isBookmarked': isBookmarked,
      'isAd': isAd,
      'isVerified': isVerified,
      'mood': mood,
    };
  }

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? json['userId'] as String,
      username: json['username'] as String? ?? '',
      userAvatar:
          json['user_avatar'] as String? ?? json['userAvatar'] as String? ?? '',
      content: json['content'] as String?,
      imageUrl: json['image_url'] as String? ?? json['imageUrl'] as String?,
      thumbnailUrl:
          json['thumbnail_url'] as String? ?? json['thumbnailUrl'] as String?,
      dominantColor:
          json['dominant_color'] as String? ?? json['dominantColor'] as String?,
      mediaUrls:
          (json['media_urls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      mediaTypes:
          (json['media_types'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      communityId: json['community_id'] as String?,
      communityName: json['community_name'] as String?,
      timestamp:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : (json['timestamp'] != null
                   ? DateTime.parse(json['timestamp'] as String)
                   : DateTime.now()),
      likes: json['likes_count'] as int? ?? json['likes'] as int? ?? 0,
      comments: json['comments_count'] as int? ?? json['comments'] as int? ?? 0,
      shares: json['shares_count'] as int? ?? json['shares'] as int? ?? 0,
      isLiked: json['is_liked'] as bool? ?? json['isLiked'] as bool? ?? false,
      isBookmarked:
          json['is_bookmarked'] as bool? ??
          json['isBookmarked'] as bool? ??
          false,
      isAd: json['is_ad'] as bool? ?? json['isAd'] as bool? ?? false,
      isVerified: json['is_verified'] as bool? ?? json['isVerified'] as bool? ?? false,
      mood: json['mood'] as String?,
    );
  }
}
