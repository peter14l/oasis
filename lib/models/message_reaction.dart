/// Available message reaction emojis
enum MessageReaction {
  heart('❤️'),
  thumbsUp('👍'),
  thumbsDown('👎'),
  laugh('😂'),
  surprised('😮'),
  sad('😢'),
  fire('🔥'),
  celebrate('🎉');

  final String emoji;
  const MessageReaction(this.emoji);

  static MessageReaction? fromEmoji(String emoji) {
    for (final reaction in MessageReaction.values) {
      if (reaction.emoji == emoji) return reaction;
    }
    return null;
  }
}

/// Model for a reaction on a message
class MessageReactionModel {
  final String id;
  final String messageId;
  final String userId;
  final String username;
  final String reaction;
  final DateTime createdAt;

  MessageReactionModel({
    required this.id,
    required this.messageId,
    required this.userId,
    required this.username,
    required this.reaction,
    required this.createdAt,
  });

  factory MessageReactionModel.fromJson(Map<String, dynamic> json) {
    return MessageReactionModel(
      id: json['id'] as String? ?? '',
      messageId: json['message_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      username: json['username'] as String? ?? 'Unknown',
      reaction: json['emoji'] as String? ?? json['reaction'] as String? ?? '',
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message_id': messageId,
      'user_id': userId,
      'username': username,
      'emoji': reaction,
      'reaction': reaction,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Grouped reactions for display
class GroupedReaction {
  final String emoji;
  final int count;
  final List<String> usernames;
  final bool hasCurrentUserReacted;

  GroupedReaction({
    required this.emoji,
    required this.count,
    required this.usernames,
    this.hasCurrentUserReacted = false,
  });
}
