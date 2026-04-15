import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oasis/core/config/supabase_config.dart';
import 'package:oasis/core/network/supabase_client.dart';
import 'package:oasis/features/messages/data/chat_media_service.dart';
import 'package:oasis/features/messages/domain/models/message_reaction.dart';

/// Service for handling auxiliary chat operations.
///
/// Manages message deletions (including media cleanup), clearing chat history,
/// typing indicators, and real-time subscriptions for receipts and conversation
/// metadata.
class MessageOperationsService {
  final SupabaseClient _supabase;
  final ChatMediaService _mediaService = ChatMediaService();

  MessageOperationsService({SupabaseClient? client})
    : _supabase = client ?? SupabaseService().client;

  /// Deletes a message and removes any associated media from storage.
  Future<void> deleteMessage(String messageId) async {
    try {
      final response =
          await _supabase
              .from(SupabaseConfig.messagesTable)
              .select('image_url, video_url, file_url, voice_url')
              .eq('id', messageId)
              .maybeSingle();

      if (response != null) {
        final mediaUrls =
            [
                  response['image_url'],
                  response['video_url'],
                  response['file_url'],
                  response['voice_url'],
                ]
                .where((url) => url != null && url.toString().isNotEmpty)
                .cast<String>()
                .toList();

        await _supabase
            .from(SupabaseConfig.messagesTable)
            .delete()
            .eq('id', messageId);

        for (final url in mediaUrls) {
          await _mediaService.deleteMediaFromUrl(url);
        }
      }
    } catch (e) {
      debugPrint('[MessageOps] Error deleting message: $e');
      rethrow;
    }
  }

  /// Clears chat for the current user only (sets cleared_at timestamp).
  Future<void> clearChatForMe(String conversationId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      await _supabase
          .from('conversation_participants')
          .update({'cleared_at': 'now()'})
          .eq('conversation_id', conversationId)
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('[MessageOps] Error clearing chat: $e');
      rethrow;
    }
  }

  /// Clears all messages in a conversation for all participants.
  Future<void> clearConversationMessages(String conversationId) async {
    try {
      await _supabase
          .from(SupabaseConfig.messagesTable)
          .delete()
          .eq('conversation_id', conversationId);
      await _supabase
          .from(SupabaseConfig.conversationsTable)
          .update({'last_message_id': null, 'last_message_at': null})
          .eq('id', conversationId);
    } catch (e) {
      debugPrint('[MessageOps] Error clearing conversation: $e');
      rethrow;
    }
  }

  /// Updates typing status for the current user.
  Future<void> updateTypingStatus(
    String conversationId,
    String userId,
    bool isTyping,
  ) async {
    try {
      await _supabase.from(SupabaseConfig.typingIndicatorsTable).upsert({
        'conversation_id': conversationId,
        'user_id': userId,
        'is_typing': isTyping,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'conversation_id,user_id');
    } catch (e) {
      debugPrint('[MessageOps] Error updating typing status: $e');
    }
  }

  /// Subscribes to typing indicators for a specific conversation.
  RealtimeChannel subscribeToTypingStatus({
    required String conversationId,
    required Function(String userId, bool isTyping) onTypingUpdate,
  }) {
    final channel = _supabase.channel('typing:$conversationId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: SupabaseConfig.typingIndicatorsTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            final data =
                payload.newRecord.isNotEmpty
                    ? payload.newRecord
                    : payload.oldRecord;
            if (data.isNotEmpty) {
              final userId = data['user_id'] as String?;
              if (userId != null) {
                onTypingUpdate(userId, data['is_typing'] as bool? ?? false);
              }
            }
          },
        )
        .subscribe((status, [error]) {
          if (status == RealtimeSubscribeStatus.channelError) {
            debugPrint('[MessageOps] subscribeToTypingStatus error: $error');
          } else if (status == RealtimeSubscribeStatus.timedOut) {
            debugPrint('[MessageOps] subscribeToTypingStatus timed out. Replication may be missing.');
          }
        });
    return channel;
  }

  /// Marks all messages in a conversation as read for a user.
  Future<void> markConversationAsRead(
    String conversationId,
    String userId,
  ) async {
    try {
      await _supabase.rpc(
        SupabaseConfig.resetUnreadCountFn,
        params: {'p_conversation_id': conversationId, 'p_user_id': userId},
      );
    } catch (e) {
      debugPrint('[MessageOps] Error marking conversation as read: $e');
    }
  }

  /// Marks specific messages as read (batch).
  Future<void> markMessagesAsRead(
    String conversationId,
    List<String> messageIds,
    String userId,
  ) async {
    try {
      if (messageIds.isEmpty) return;

      // Single batch upsert instead of N serial round-trips
      final now = DateTime.now().toIso8601String();
      await _supabase
          .from(SupabaseConfig.messageReadReceiptsTable)
          .upsert(
            messageIds
                .map((id) => {
                      'message_id': id,
                      'user_id': userId,
                      'read_at': now,
                    })
                .toList(),
            onConflict: 'message_id,user_id',
          );

      // Reset unread count for the conversation
      await markConversationAsRead(conversationId, userId);
    } catch (e) {
      debugPrint('[MessageOps] Error marking messages as read: $e');
    }
  }

  /// Toggles whisper mode for a conversation.
  Future<void> toggleWhisperMode(String conversationId, int whisperMode) async {
    try {
      await _supabase
          .from(SupabaseConfig.conversationsTable)
          .update({'whisper_mode': whisperMode})
          .eq('id', conversationId);
    } catch (e) {
      debugPrint('[MessageOps] Error toggling whisper mode: $e');
    }
  }

  /// Increments the view count for a media message.
  Future<void> incrementMediaViewCount(String messageId) async {
    try {
      await _supabase.rpc(
        SupabaseConfig.incrementMediaViewCountFn,
        params: {'p_message_id': messageId},
      );
    } catch (e) {
      debugPrint('[MessageOps] Error incrementing media view count: $e');
    }
  }

  /// Subscribes to read receipts for a specific conversation.
  RealtimeChannel subscribeToReadReceipts({
    required String conversationId,
    required Function(String messageId, String userId, DateTime readAt)
    onUpdate,
  }) {
    final channel = _supabase.channel('read_receipts:$conversationId');
    channel
        .onPostgresChanges(
          // Listen to ALL events — upsert may resolve as UPDATE, not INSERT,
          // so INSERT-only misses updates on already-receipted rows.
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: SupabaseConfig.messageReadReceiptsTable,
          callback: (payload) {
            try {
              final data =
                  payload.newRecord.isNotEmpty
                      ? payload.newRecord
                      : payload.oldRecord;
              if (data.isNotEmpty) {
                final messageId = data['message_id'] as String?;
                final userId = data['user_id'] as String?;
                final readAt = data['read_at'] as String?;

                if (messageId != null && userId != null && readAt != null) {
                  onUpdate(messageId, userId, DateTime.parse(readAt));
                }
              }
            } catch (e) {
              debugPrint('[MessageOps] Read receipt processing error: $e');
            }
          },
        )
        .subscribe((status, [error]) {
          if (status == RealtimeSubscribeStatus.channelError) {
            debugPrint('[MessageOps] subscribeToReadReceipts error: $error');
          } else if (status == RealtimeSubscribeStatus.timedOut) {
            debugPrint('[MessageOps] subscribeToReadReceipts timed out. Replication may be missing.');
          }
        });
    return channel;
  }

  /// Subscribes to reaction changes for a specific conversation.
  RealtimeChannel subscribeToReactions({
    required String conversationId,
    required Function(String messageId, List<MessageReactionModel> reactions)
    onUpdate,
  }) {
    final channel = _supabase.channel('reactions:$conversationId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'message_reactions',
          callback: (payload) {
            try {
              final data =
                  payload.newRecord.isNotEmpty
                      ? payload.newRecord
                      : payload.oldRecord;
              if (data.isNotEmpty) {
                final messageId = data['message_id'] as String?;
                if (messageId != null) {
                  // Fetch all reactions for this message to get the full current state
                  _fetchReactionsForMessage(messageId, onUpdate);
                }
              }
            } catch (e) {
              debugPrint('[MessageOps] Reaction processing error: $e');
            }
          },
        )
        .subscribe((status, [error]) {
          if (status == RealtimeSubscribeStatus.channelError) {
            debugPrint('[MessageOps] subscribeToReactions error: $error');
          } else if (status == RealtimeSubscribeStatus.timedOut) {
            debugPrint('[MessageOps] subscribeToReactions timed out. Replication may be missing.');
          }
        });
    return channel;
  }

  Future<void> _fetchReactionsForMessage(
    String messageId,
    Function(String messageId, List<MessageReactionModel> reactions) onUpdate,
  ) async {
    try {
      final reactions = await _supabase
          .from('message_reactions')
          .select('*, profiles:user_id (username)')
          .eq('message_id', messageId);

      final reactionModels =
          reactions.map((r) {
            final profile = r['profiles'] as Map<String, dynamic>?;
            final createdAtStr = r['created_at'] as String?;

            return MessageReactionModel(
              id: r['id'] as String? ?? '',
              messageId: r['message_id'] as String? ?? '',
              userId: r['user_id'] as String? ?? '',
              username: profile?['username'] ?? 'Unknown',
              reaction: r['emoji'] as String? ?? r['reaction'] as String? ?? '',
              createdAt:
                  createdAtStr != null
                      ? DateTime.parse(createdAtStr)
                      : DateTime.now(),
            );
          }).toList();

      onUpdate(messageId, reactionModels);
    } catch (e) {
      debugPrint('[MessageOps] Error fetching reactions: $e');
    }
  }

  /// Subscribes to general conversation detail updates (e.g. whisper mode).
  RealtimeChannel subscribeToConversationDetails({
    required String conversationId,
    required Function(int whisperMode) onUpdate,
  }) {
    final channel = _supabase.channel('conversation_details:$conversationId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: SupabaseConfig.conversationsTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: conversationId,
          ),
          callback: (payload) {
            final mode = payload.newRecord['whisper_mode'] as int? ?? 0;
            onUpdate(mode);
          },
        )
        .subscribe((status, [error]) {
          if (status == RealtimeSubscribeStatus.channelError) {
            debugPrint('[MessageOps] subscribeToConversationDetails error: $error');
          } else if (status == RealtimeSubscribeStatus.timedOut) {
            debugPrint('[MessageOps] subscribeToConversationDetails timed out. Replication may be missing.');
          }
        });
    return channel;
  }
}
