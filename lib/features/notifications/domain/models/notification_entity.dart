import 'package:flutter/material.dart';

class AppNotification {
  final String id;
  final String userId;
  final String type; // 'like', 'comment', 'follow', 'mention', 'dm'
  final String? title;
  final String? actorId;
  final String? actorName;
  final String? actorAvatar;
  final String? postId;
  final String? commentId;
  final String? messageId;
  final String? message;
  final bool isRead;
  final DateTime timestamp;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    this.title,
    this.actorId,
    this.actorName,
    this.actorAvatar,
    this.postId,
    this.commentId,
    this.messageId,
    this.message,
    this.isRead = false,
    required this.timestamp,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      title: json['title'] as String?,
      actorId: json['actor_id'] as String?,
      actorName: json['actor_name'] as String?,
      actorAvatar: json['actor_avatar'] as String?,
      postId: json['post_id'] as String?,
      commentId: json['comment_id'] as String?,
      messageId: json['message_id'] as String?,
      message: (json['content'] ?? json['message']) as String?,
      isRead: json['is_read'] as bool? ?? false,
      timestamp:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'title': title,
      'actor_id': actorId,
      'actor_name': actorName,
      'actor_avatar': actorAvatar,
      'post_id': postId,
      'comment_id': commentId,
      'message_id': messageId,
      'message': message,
      'is_read': isRead,
      'created_at': timestamp.toIso8601String(),
    };
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? actorId,
    String? actorName,
    String? actorAvatar,
    String? postId,
    String? commentId,
    String? messageId,
    String? message,
    bool? isRead,
    DateTime? timestamp,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      actorId: actorId ?? this.actorId,
      actorName: actorName ?? this.actorName,
      actorAvatar: actorAvatar ?? this.actorAvatar,
      postId: postId ?? this.postId,
      commentId: commentId ?? this.commentId,
      messageId: messageId ?? this.messageId,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

enum NotificationType { like, comment, follow, mention, dm, ripple, system }

extension NotificationTypeExtension on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.like:
        return 'Like';
      case NotificationType.comment:
        return 'Comment';
      case NotificationType.follow:
        return 'Follow';
      case NotificationType.mention:
        return 'Mention';
      case NotificationType.dm:
        return 'Message';
      case NotificationType.ripple:
        return 'Ripple';
      case NotificationType.system:
        return 'System';
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationType.like:
        return Icons.favorite;
      case NotificationType.comment:
        return Icons.comment;
      case NotificationType.follow:
        return Icons.person_add;
      case NotificationType.mention:
        return Icons.alternate_email;
      case NotificationType.dm:
        return Icons.message;
      case NotificationType.ripple:
        return Icons.waves;
      case NotificationType.system:
        return Icons.info;
    }
  }
}
