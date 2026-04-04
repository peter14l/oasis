import '../models/conversation_entity.dart';

/// Repository interface for conversation operations
abstract class ConversationRepository {
  /// Get all conversations for a user
  Future<List<ConversationEntity>> getConversations(String userId);

  /// Get a single conversation by ID
  Future<ConversationEntity?> getConversation(String conversationId);

  /// Create a new conversation
  Future<ConversationEntity> createConversation({
    required String userId,
    required String otherUserId,
  });

  /// Delete a conversation
  Future<void> deleteConversation(String conversationId);

  /// Mark conversation as read
  Future<void> markAsRead(String conversationId);

  /// Pin/unpin conversation
  Future<void> togglePin(String conversationId);

  /// Mute/unmute conversation
  Future<void> toggleMute(String conversationId);

  /// Archive/unarchive conversation
  Future<void> toggleArchive(String conversationId);

  /// Get unread conversation count
  Future<int> getUnreadCount(String userId);
}
