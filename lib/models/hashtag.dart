class Hashtag {
  final String id;
  final String tag;
  final String normalizedTag;
  final int usageCount;
  final DateTime createdAt;
  final DateTime lastUsedAt;

  Hashtag({
    required this.id,
    required this.tag,
    required this.normalizedTag,
    required this.usageCount,
    required this.createdAt,
    required this.lastUsedAt,
  });

  factory Hashtag.fromJson(Map<String, dynamic> json) {
    return Hashtag(
      id: json['id'] as String,
      tag: json['tag'] as String,
      normalizedTag: json['normalized_tag'] as String,
      usageCount: json['usage_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastUsedAt: DateTime.parse(json['last_used_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tag': tag,
      'normalized_tag': normalizedTag,
      'usage_count': usageCount,
      'created_at': createdAt.toIso8601String(),
      'last_used_at': lastUsedAt.toIso8601String(),
    };
  }

  String get displayTag => '#$tag';
}

class Mention {
  final String id;
  final String? postId;
  final String? commentId;
  final String mentionedUserId;
  final String mentionedByUserId;
  final DateTime createdAt;

  // Additional fields from joins
  final String? mentionedUsername;
  final String? mentionedUserAvatar;

  Mention({
    required this.id,
    this.postId,
    this.commentId,
    required this.mentionedUserId,
    required this.mentionedByUserId,
    required this.createdAt,
    this.mentionedUsername,
    this.mentionedUserAvatar,
  });

  factory Mention.fromJson(Map<String, dynamic> json) {
    return Mention(
      id: json['id'] as String,
      postId: json['post_id'] as String?,
      commentId: json['comment_id'] as String?,
      mentionedUserId: json['mentioned_user_id'] as String,
      mentionedByUserId: json['mentioned_by_user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      mentionedUsername: json['mentioned_username'] as String?,
      mentionedUserAvatar: json['mentioned_user_avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'comment_id': commentId,
      'mentioned_user_id': mentionedUserId,
      'mentioned_by_user_id': mentionedByUserId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isPostMention => postId != null;
  bool get isCommentMention => commentId != null;
}
