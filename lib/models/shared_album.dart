/// Model for shared albums in chat
class SharedAlbum {
  final String id;
  final String conversationId;
  final String name;
  final String? description;
  final String creatorId;
  final String creatorUsername;
  final List<String> contributorIds;
  final int photoCount;
  final String? coverImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  SharedAlbum({
    required this.id,
    required this.conversationId,
    required this.name,
    this.description,
    required this.creatorId,
    required this.creatorUsername,
    this.contributorIds = const [],
    this.photoCount = 0,
    this.coverImageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SharedAlbum.fromJson(Map<String, dynamic> json) {
    return SharedAlbum(
      id: json['id'],
      conversationId: json['conversation_id'],
      name: json['name'],
      description: json['description'],
      creatorId: json['creator_id'],
      creatorUsername: json['creator_username'] ?? 'Unknown',
      contributorIds: (json['contributor_ids'] as List?)?.cast<String>() ?? [],
      photoCount: json['photo_count'] ?? 0,
      coverImageUrl: json['cover_image_url'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'name': name,
      'description': description,
      'creator_id': creatorId,
      'contributor_ids': contributorIds,
    };
  }
}

class SharedAlbumPhoto {
  final String id;
  final String albumId;
  final String imageUrl;
  final String? thumbnailUrl;
  final String uploaderId;
  final String uploaderUsername;
  final String? uploaderAvatarUrl;
  final String? caption;
  final DateTime createdAt;
  final int likesCount;
  final bool isLiked;

  SharedAlbumPhoto({
    required this.id,
    required this.albumId,
    required this.imageUrl,
    this.thumbnailUrl,
    required this.uploaderId,
    required this.uploaderUsername,
    this.uploaderAvatarUrl,
    this.caption,
    required this.createdAt,
    this.likesCount = 0,
    this.isLiked = false,
  });

  factory SharedAlbumPhoto.fromJson(Map<String, dynamic> json) {
    return SharedAlbumPhoto(
      id: json['id'],
      albumId: json['album_id'],
      imageUrl: json['image_url'],
      thumbnailUrl: json['thumbnail_url'],
      uploaderId: json['uploader_id'],
      uploaderUsername: json['uploader_username'] ?? 'Unknown',
      uploaderAvatarUrl: json['uploader_avatar_url'],
      caption: json['caption'],
      createdAt: DateTime.parse(json['created_at']),
      likesCount: json['likes_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'album_id': albumId,
      'image_url': imageUrl,
      'thumbnail_url': thumbnailUrl,
      'uploader_id': uploaderId,
      'caption': caption,
    };
  }
}
