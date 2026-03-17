class Comment {
  final String id;
  final String postId;
  final String userId;
  final String? parentCommentId;
  final String username;
  final String userAvatar;
  final String content;
  final int likes;
  final int repliesCount;
  final bool isLiked;
  final DateTime timestamp;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    this.parentCommentId,
    required this.username,
    required this.userAvatar,
    required this.content,
    required this.likes,
    required this.repliesCount,
    required this.isLiked,
    required this.timestamp,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      parentCommentId: json['parent_comment_id'] as String?,
      username: json['username'] as String? ?? '',
      userAvatar: json['user_avatar'] as String? ?? json['avatar_url'] as String? ?? '',
      content: json['content'] as String,
      likes: json['likes_count'] as int? ?? 0,
      repliesCount: json['replies_count'] as int? ?? 0,
      isLiked: json['is_liked'] as bool? ?? false,
      timestamp: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'user_id': userId,
      'parent_comment_id': parentCommentId,
      'username': username,
      'user_avatar': userAvatar,
      'content': content,
      'likes_count': likes,
      'replies_count': repliesCount,
      'is_liked': isLiked,
      'created_at': timestamp.toIso8601String(),
    };
  }

  Comment copyWith({
    String? id,
    String? postId,
    String? userId,
    String? parentCommentId,
    String? username,
    String? userAvatar,
    String? content,
    int? likes,
    int? repliesCount,
    bool? isLiked,
    DateTime? timestamp,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      username: username ?? this.username,
      userAvatar: userAvatar ?? this.userAvatar,
      content: content ?? this.content,
      likes: likes ?? this.likes,
      repliesCount: repliesCount ?? this.repliesCount,
      isLiked: isLiked ?? this.isLiked,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

