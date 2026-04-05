import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:oasis/models/message.dart';
import 'package:oasis/core/config/supabase_config.dart';
import 'package:oasis/core/network/supabase_client.dart';
import 'package:oasis/services/notification_service.dart';

/// Service dedicated to message transport and lifecycle management.
/// 
/// Handles retrieving messages, applying "whisper mode" (ephemeral) filters,
/// sending new messages with security checks (e.g. blocking), and marking 
/// messages as read.
class ChatMessagingService {
  final SupabaseClient _supabase;
  final _uuid = const Uuid();
  final NotificationService _notificationService = NotificationService();

  ChatMessagingService({SupabaseClient? client})
      : _supabase = client ?? SupabaseService().client;

  /// Retrieves messages for a specific conversation.
  /// 
  /// Includes read receipts, reply-to metadata, and reaction counts.
  /// Filters messages based on the user's "cleared_at" timestamp.
  Future<List<Message>> getMessages({
    required String conversationId,
    int limit = 50,
    int offset = 0,
    DateTime? sessionStart,
  }) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('Not authenticated');

      // 1. Fetch cleared_at timestamp for the current user
      final participantResponse = await _supabase
          .from('conversation_participants')
          .select('cleared_at')
          .eq('conversation_id', conversationId)
          .eq('user_id', currentUserId)
          .maybeSingle();

      final clearedAt = participantResponse != null && participantResponse['cleared_at'] != null
          ? DateTime.parse(participantResponse['cleared_at'])
          : null;

      // 2. Query messages
      var query = _supabase.from(SupabaseConfig.messagesTable).select('''
            *,
            sender_profile:sender_id (username, avatar_url),
            reply_to:reply_to_id (
              id, content, sender_id, image_url, video_url, file_url, voice_url, 
              iv, encrypted_keys, signal_message_type, signal_sender_content,
              profiles:sender_id (username)
            ),
            reactions:message_reactions(*),
            media_views:message_media_views!left(view_count)
          ''').eq('conversation_id', conversationId);

      if (clearedAt != null) {
        query = query.gte('created_at', clearedAt.toIso8601String());
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      if (response.isEmpty) return [];

      final List<Message> messages = [];
      final List<String> messageIds = [];

      for (final item in response) {
        final messageMap = Map<String, dynamic>.from(item);
        final profile = messageMap['sender_profile'];
        if (profile != null) {
          messageMap['sender_name'] = profile['username'];
          messageMap['sender_avatar'] = profile['avatar_url'];
        }

        if (messageMap['media_views'] != null) {
          final views = messageMap['media_views'] as List;
          if (views.isNotEmpty) {
            messageMap['current_user_view_count'] = views[0]['view_count'] ?? 0;
          }
        }

        messages.add(Message.fromJson(messageMap));
        messageIds.add(messageMap['id']);
      }

      // 3. Process read receipts
      if (messageIds.isNotEmpty) {
        final readReceipts = await _supabase
            .from(SupabaseConfig.messageReadReceiptsTable)
            .select('message_id, user_id, read_at')
            .inFilter('message_id', messageIds);

        final myReadMap = <String, String>{};
        final firstReadMap = <String, String>{};

        for (final r in readReceipts) {
          final msgId = r['message_id'] as String;
          final uId = r['user_id'] as String;
          final rAt = r['read_at'] as String;

          if (uId == currentUserId) myReadMap[msgId] = rAt;

          final msgIndex = messages.indexWhere((m) => m.id == msgId);
          if (msgIndex >= 0 && uId != messages[msgIndex].senderId) {
            if (!firstReadMap.containsKey(msgId) ||
                DateTime.parse(rAt).isBefore(DateTime.parse(firstReadMap[msgId]!))) {
              firstReadMap[msgId] = rAt;
            }
          }
        }

        for (var i = 0; i < messages.length; i++) {
          final isSender = messages[i].senderId == currentUserId;
          final myReadTimeStr = myReadMap[messages[i].id];
          final anyReadTimeStr = firstReadMap[messages[i].id];

          DateTime? myReadAt = myReadTimeStr != null ? DateTime.parse(myReadTimeStr) : null;
          DateTime? anyReadAt = anyReadTimeStr != null ? DateTime.parse(anyReadTimeStr) : null;

          if (myReadAt != null || anyReadAt != null) {
            messages[i] = messages[i].copyWith(
              readAt: myReadAt,
              anyReadAt: anyReadAt,
              isRead: isSender ? (anyReadAt != null) : (myReadAt != null),
            );

            // Heal expiresAt locally
            if (messages[i].isEphemeral && messages[i].expiresAt == null && anyReadAt != null) {
              final calculatedExpiry = anyReadAt.add(Duration(seconds: messages[i].ephemeralDuration));
              messages[i] = messages[i].copyWith(expiresAt: calculatedExpiry);
            }
          }
        }
      }

      return messages.reversed.toList();
    } catch (e) {
      debugPrint('[ChatMessagingService] Error fetching messages: $e');
      rethrow;
    }
  }

  /// Send a message with all security checks and metadata updates.
  Future<Message> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
    MessageType messageType = MessageType.text,
    String? mediaUrl,
    String? mediaFileName,
    int? mediaFileSize,
    int? voiceDuration,
    Map<String, String>? encryptedKeys,
    String? iv,
    int? signalMessageType,
    String? signalSenderContent,
    int whisperMode = 0,
    String? callId,
    String? replyToId,
    String? rippleId,
    String? storyId,
    String? postId,
    Map<String, dynamic>? shareData,
    String mediaViewMode = 'unlimited',
  }) async {
    try {
      final messageId = _uuid.v4();

      // Block check
      final recipientId = await _getRecipientId(conversationId, senderId);
      if (recipientId != null && await _isBlockedBy(recipientId, senderId)) {
        throw Exception('You cannot send messages to this user.');
      }

      final insertData = {
        'id': messageId,
        'conversation_id': conversationId,
        'sender_id': senderId,
        'content': content,
        'file_name': mediaFileName,
        'file_size': mediaFileSize,
        'is_ephemeral': whisperMode > 0,
        'ephemeral_duration': whisperMode == 1 ? 0 : 86400,
        'call_id': callId,
        'reply_to_id': replyToId,
        'ripple_id': rippleId,
        'story_id': storyId,
        'post_id': postId,
        'share_data': shareData,
        'media_view_mode': mediaViewMode,
        'encrypted_keys': encryptedKeys,
        'iv': iv,
        'signal_message_type': signalMessageType,
        'signal_sender_content': signalSenderContent,
      };

      if (mediaUrl != null) {
        if (messageType == MessageType.image || messageType == MessageType.ripple) {
          insertData['image_url'] = mediaUrl;
        } else if (messageType == MessageType.document) {
          insertData['file_url'] = mediaUrl;
        } else if (messageType == MessageType.voice) {
          insertData['voice_url'] = mediaUrl;
          insertData['voice_duration'] = voiceDuration;
        }
      }

      await _supabase.from(SupabaseConfig.messagesTable).insert(insertData);

      // Fetch created message with details
      final response = await _supabase.from(SupabaseConfig.messagesTable).select('''
            *,
            sender_profile:sender_id (username, avatar_url),
            reply_to:reply_to_id (
              id, content, sender_id, image_url, video_url, file_url, voice_url, 
              iv, encrypted_keys, signal_message_type, signal_sender_content,
              profiles:sender_id (username)
            ),
            reactions:message_reactions(*)
          ''').eq('id', messageId).single();

      final message = Message.fromJson(Map<String, dynamic>.from(response));

      // Manual sync of conversation timestamp
      await _supabase.from(SupabaseConfig.conversationsTable).update({
        'last_message_id': message.id,
        'last_message_at': message.timestamp.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', conversationId);

      // Send notifications
      _triggerNotifications(conversationId, senderId, content, messageId, encryptedKeys != null || signalMessageType != null);

      return message;
    } catch (e) {
      debugPrint('[ChatMessagingService] Error sending message: $e');
      rethrow;
    }
  }

  /// Mark message as read.
  Future<void> markAsRead({required String messageId, required String userId}) async {
    try {
      await _supabase.from(SupabaseConfig.messageReadReceiptsTable).upsert({
        'message_id': messageId,
        'user_id': userId,
        'read_at': DateTime.now().toIso8601String(),
      }, onConflict: 'message_id,user_id');
    } catch (e) {
      debugPrint('[ChatMessagingService] Error marking read: $e');
    }
  }

  /// Subscribe to new messages.
  RealtimeChannel subscribeToMessages({
    required String conversationId,
    required Function(Message) onNewMessage,
    Function(String)? onDeleteMessage,
  }) {
    final channel = _supabase.channel('messages:$conversationId');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: SupabaseConfig.messagesTable,
      filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'conversation_id', value: conversationId),
      callback: (payload) async {
        final messageData = payload.newRecord;
        final profile = await _supabase.from(SupabaseConfig.profilesTable).select('username, avatar_url').eq('id', messageData['sender_id']).single();
        messageData['sender_name'] = profile['username'];
        messageData['sender_avatar'] = profile['avatar_url'];

        if (messageData['reply_to_id'] != null) {
          final replyResponse = await _supabase.from(SupabaseConfig.messagesTable).select('*, profiles:sender_id (username)').eq('id', messageData['reply_to_id']).maybeSingle();
          if (replyResponse != null) messageData['reply_to'] = replyResponse;
        }
        onNewMessage(Message.fromJson(messageData));
      },
    ).onPostgresChanges(
      event: PostgresChangeEvent.delete,
      schema: 'public',
      table: SupabaseConfig.messagesTable,
      callback: (payload) {
        if (onDeleteMessage != null) onDeleteMessage(payload.oldRecord['id'] as String);
      },
    ).subscribe((status, [error]) {
      if (status == RealtimeSubscribeStatus.channelError) {
        debugPrint('[ChatMessagingService] Subscription error: $error');
      }
    });
    return channel;
  }

  // --- Helper Methods ---

  Future<String?> _getRecipientId(String conversationId, String senderId) async {
    final response = await _supabase.from('conversation_participants').select('user_id').eq('conversation_id', conversationId).neq('user_id', senderId).maybeSingle();
    return response?['user_id'] as String?;
  }

  Future<bool> _isBlockedBy(String userId, String actorId) async {
    final response = await _supabase
        .from('blocked_users')
        .select('id')
        .eq('blocker_id', userId)
        .eq('blocked_id', actorId)
        .maybeSingle();
    return response != null;
  }

  void _triggerNotifications(String conversationId, String senderId, String content, String messageId, bool isEncrypted) async {
    try {
      final participants = await _supabase.from('conversation_participants').select('user_id').eq('conversation_id', conversationId).neq('user_id', senderId);
      final senderProfile = await _supabase.from(SupabaseConfig.profilesTable).select('username').eq('id', senderId).single();
      final senderName = senderProfile['username'] ?? 'Someone';

      for (final p in participants) {
        await _notificationService.createNotification(
          userId: p['user_id'],
          type: 'dm',
          actorId: senderId,
          title: senderName,
          message: isEncrypted ? '🔒 Encrypted Message' : content,
          messageId: messageId,
        );
      }
    } catch (e) {
      debugPrint('[ChatMessagingService] Notification Error: $e');
    }
  }
}
