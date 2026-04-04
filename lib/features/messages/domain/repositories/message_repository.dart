import '../models/message_entity.dart';

/// Repository interface for message operations
abstract class MessageRepository {
  /// Get messages for a conversation
  Future<List<MessageEntity>> getMessages({
    required String conversationId,
    int limit = 50,
    String? before,
  });

  /// Send a new message
  Future<MessageEntity> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
    MessageTypeEntity type = MessageTypeEntity.text,
    String? mediaUrl,
    String? mediaFileName,
    String? replyToId,
    String? rippleId,
    String? storyId,
  });

  /// Delete a message
  Future<void> deleteMessage(String messageId);

  /// React to a message
  Future<MessageReactionEntity> reactToMessage({
    required String messageId,
    required String userId,
    required String emoji,
  });

  /// Remove reaction from a message
  Future<void> removeReaction(String messageId, String userId);

  /// Get message reactions
  Future<List<MessageReactionEntity>> getReactions(String messageId);
}
