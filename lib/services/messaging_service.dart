import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:oasis_v2/config/supabase_config.dart';
import 'package:oasis_v2/models/message.dart';
import 'package:oasis_v2/models/conversation.dart';
import 'package:oasis_v2/services/supabase_service.dart';
import 'package:oasis_v2/services/notification_service.dart';
import 'package:oasis_v2/services/signal/signal_service.dart';
import 'package:oasis_v2/services/encryption_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class MessagingService {
  final _supabase = SupabaseService().client;
  final _uuid = const Uuid();
  final NotificationService _notificationService = NotificationService();

  /// Get user's conversations
  Future<List<Conversation>> getConversations({
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      // Query conversations where user is a participant
      final response = await _supabase
          .from('conversation_participants')
          .select('''
            conversation_id,
            unread_count,
            ${SupabaseConfig.conversationsTable}:conversation_id (
              id,
              type,
              name,
              image_url,
              last_message_at,
              last_message_id,
              is_whisper_mode,
              created_at,
              updated_at,
              last_message:last_message_id (
                content,
                sender_id,
                image_url,
                video_url,
                file_url,
                created_at,
                iv,
                encrypted_keys,
                signal_message_type
              )
            )
          ''')
          .eq('user_id', userId)
          .order(
            '${SupabaseConfig.conversationsTable}(last_message_at)',
            ascending: false,
          )
          .range(offset, offset + limit - 1);

      if (response.isEmpty) return [];

      final List<Conversation> conversations = [];
      for (final item in response) {
        final participantData = Map<String, dynamic>.from(item);
        final conversationData =
            participantData[SupabaseConfig.conversationsTable];

        if (conversationData == null) continue;

        final conversationMap = Map<String, dynamic>.from(conversationData);
        conversationMap['unread_count'] = participantData['unread_count'] ?? 0;

        // For direct conversations, get the other participant
        if (conversationMap['type'] == 'direct') {
          final otherParticipants = await _supabase
              .from('conversation_participants')
              .select('user_id')
              .eq('conversation_id', conversationMap['id'])
              .neq('user_id', userId);

          if (otherParticipants.isNotEmpty) {
            final otherUserId = otherParticipants.first['user_id'];

            // Fetch other user's profile
            final profileResponse =
                await _supabase
                    .from(SupabaseConfig.profilesTable)
                    .select('username, full_name, avatar_url')
                    .eq('id', otherUserId)
                    .single();

            conversationMap['other_user_id'] = otherUserId;
            conversationMap['other_user_name'] =
                profileResponse['username'] ??
                profileResponse['full_name'] ??
                'Unknown';
            conversationMap['other_user_avatar'] =
                profileResponse['avatar_url'] ?? '';
          }
        } else {
          // For group conversations, use conversation name and image
          conversationMap['other_user_id'] = '';
          conversationMap['other_user_name'] =
              conversationMap['name'] ?? 'Group Chat';
          conversationMap['other_user_avatar'] =
              conversationMap['image_url'] ?? '';
        }

        // Get last message
        final lastMessage = conversationMap['last_message'];
        if (lastMessage != null) {
          String content = lastMessage['content'] ?? '';

          // Decrypt if necessary
          final isSender = lastMessage['sender_id'] == userId;

          if (isSender && lastMessage['signal_sender_content'] != null && lastMessage['encrypted_keys'] != null && lastMessage['iv'] != null) {
            try {
              final decrypted = await EncryptionService().decryptMessage(
                lastMessage['signal_sender_content'],
                lastMessage['encrypted_keys'],
                lastMessage['iv'],
              );
              if (decrypted != null) {
                content = decrypted;
              } else {
                content = '🔒 Message encrypted';
              }
            } catch (e) {
              debugPrint('Standard decryption failed for sender preview: $e');
              content = '🔒 Message encrypted';
            }
          } else if (!isSender && lastMessage['signal_message_type'] != null) {
            try {
              content = await SignalService().decryptMessage(
                lastMessage['sender_id'],
                content,
                lastMessage['signal_message_type'],
              );
              
              // Fallback to RSA if Signal decryption returns a failure placeholder
              if (content.contains('🔒 Message encrypted') && 
                  lastMessage['encrypted_keys'] != null && 
                  lastMessage['iv'] != null &&
                  lastMessage['signal_sender_content'] != null) {
                final rsaDecrypted = await EncryptionService().decryptMessage(
                  lastMessage['signal_sender_content'],
                  lastMessage['encrypted_keys'],
                  lastMessage['iv'],
                );
                if (rsaDecrypted != null) {
                   content = rsaDecrypted;
                   debugPrint('[MessagingService] Recovered preview via RSA fallback.');
                }
              }
            } catch (e) {
              debugPrint('Signal decryption failed for preview: $e');
              content = '🔒 Message encrypted';
            }
          } else if (lastMessage['encrypted_keys'] != null &&
              lastMessage['iv'] != null) {
            try {
              final decrypted = await EncryptionService().decryptMessage(
                content,
                lastMessage['encrypted_keys'],
                lastMessage['iv'],
              );
              if (decrypted != null) {
                content = decrypted;
              } else {
                content = '🔒 Message encrypted';
              }
            } catch (e) {
              debugPrint('Standard decryption failed for preview: $e');
              content = '🔒 Message encrypted';
            }
          }

          conversationMap['last_message'] = content;
          conversationMap['last_message_time'] = lastMessage['created_at'];

          // Derive message type from URL fields
          String? messageType = 'text';
          if (lastMessage['image_url'] != null &&
              lastMessage['image_url'].toString().isNotEmpty) {
            messageType = 'image';
          } else if (lastMessage['video_url'] != null &&
              lastMessage['video_url'].toString().isNotEmpty) {
            messageType = 'video';
          } else if (lastMessage['file_url'] != null &&
              lastMessage['file_url'].toString().isNotEmpty) {
            messageType = 'document';
          }
          conversationMap['last_message_type'] = messageType;
          conversationMap['last_message_sender_id'] = lastMessage['sender_id'];

          // Fetch read receipt for last message from other user
          if (lastMessage['sender_id'] == userId &&
              conversationMap['other_user_id'] != null) {
            final readReceiptResponse =
                await _supabase
                    .from(SupabaseConfig.messageReadReceiptsTable)
                    .select('read_at')
                    .eq('message_id', conversationMap['last_message_id'])
                    .eq('user_id', conversationMap['other_user_id'])
                    .maybeSingle();

            if (readReceiptResponse != null) {
              conversationMap['last_message_read_at'] =
                  readReceiptResponse['read_at'];
            }
          }
        }

        conversations.add(Conversation.fromJson(conversationMap));
      }

      return conversations;
    } catch (e) {
      debugPrint('Error fetching conversations: $e');
      rethrow;
    }
  }

  /// Get or create conversation between two users
  Future<String> getOrCreateConversation({
    required String user1Id,
    required String user2Id,
  }) async {
    try {
      // Use the database function to get or create direct conversation
      final response = await _supabase.rpc(
        'get_or_create_direct_conversation',
        params: {'p_user1_id': user1Id, 'p_user2_id': user2Id},
      );

      return response as String;
    } catch (e) {
      debugPrint('Error getting/creating conversation: $e');
      rethrow;
    }
  }

  /// Get messages for a conversation
  Future<List<Message>> getMessages({
    required String conversationId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.messagesTable)
          .select('''
            *,
            ${SupabaseConfig.profilesTable}:sender_id (
              username,
              avatar_url
            ),
            reactions:message_reactions(*)
          ''')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      if (response.isEmpty) return [];

      final currentUserId = _supabase.auth.currentUser?.id;
      final List<Message> messages = [];
      final List<String> messageIds = [];

      for (final item in response) {
        final messageMap = Map<String, dynamic>.from(item);
        final profile = messageMap[SupabaseConfig.profilesTable];
        if (profile != null) {
          messageMap['sender_name'] = profile['username'];
          messageMap['sender_avatar'] = profile['avatar_url'];
        }
        messages.add(Message.fromJson(messageMap));
        messageIds.add(messageMap['id']);
      }

      // Fetch read receipts for these messages
      if (currentUserId != null && messageIds.isNotEmpty) {
        final readReceipts = await _supabase
            .from(SupabaseConfig.messageReadReceiptsTable)
            .select('message_id, user_id, read_at')
            .inFilter('message_id', messageIds);

        final myReadMap = <String, String>{};
        final firstReadMap = <String, String>{};

        for (final r in readReceipts) {
          final messageId = r['message_id'] as String;
          final userId = r['user_id'] as String;
          final readAt = r['read_at'] as String;

          if (userId == currentUserId) {
            myReadMap[messageId] = readAt;
          }

          if (!firstReadMap.containsKey(messageId) ||
              DateTime.parse(
                readAt,
              ).isBefore(DateTime.parse(firstReadMap[messageId]!))) {
            firstReadMap[messageId] = readAt;
          }
        }

        // Update messages with readAt info
        for (var i = 0; i < messages.length; i++) {
          final isSender = messages[i].senderId == currentUserId;
          final readTimeStr =
              isSender
                  ? firstReadMap[messages[i].id]
                  : myReadMap[messages[i].id];

          if (readTimeStr != null) {
            final readAt = DateTime.parse(readTimeStr);
            messages[i] = messages[i].copyWith(
              readAt: readAt,
              isRead: true, // Explicitly set as read
            );
          }
        }
      }

      // Filter out expired ephemeral messages
      final visibleMessages = MessagingService.filterExpiredMessages(messages);

      return visibleMessages.reversed.toList(); // Reverse to show oldest first
    } catch (e) {
      debugPrint('Error fetching messages: $e');
      rethrow;
    }
  }

  /// Filter out expired ephemeral messages
  /// Visible if:
  /// 1. Not ephemeral
  /// 2. Is ephemeral but not read yet
  /// 3. Is ephemeral, read, but seen < 24 hours ago
  static List<Message> filterExpiredMessages(List<Message> messages) {
    if (messages.isEmpty) return [];

    final now = DateTime.now();

    return messages.where((message) {
      if (!message.isEphemeral) return true;

      // If not read (by current user), it shouldn't vanish yet
      if (message.readAt == null) return true;

      // Calculate expiration based on message's duration
      final duration = Duration(seconds: message.ephemeralDuration);

      // If duration is 0 (Immediate), it vanishes immediately after reading
      // We allow a small grace period (e.g. 1 second) to ensure UI updates smoothly
      if (message.ephemeralDuration == 0) {
        return false; // Vanish immediately if readAt is present
      }

      final expirationTime = message.readAt!.add(duration);
      return now.isBefore(expirationTime);
    }).toList();
  }

  /// Send a message
  Future<Message> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
    MessageType messageType = MessageType.text,
    String? mediaUrl,
    String? mediaFileName,
    int? mediaFileSize,
    String? mediaMimeType,
    int? voiceDuration,
    Map<String, String>? encryptedKeys,
    String? iv,
    int? signalMessageType,
    String? signalSenderContent,
    int? signalSenderMessageType,
    bool isWhisperMode = false,
    int? ephemeralDuration,
    String? callId,
  }) async {
    try {
      final messageId = _uuid.v4();

      // Map message type to appropriate URL column
      final insertData = {
        'id': messageId,
        'conversation_id': conversationId,
        'sender_id': senderId,
        'content': content,
        'file_name': mediaFileName,
        'file_size': mediaFileSize,
        'is_ephemeral': isWhisperMode,
        'ephemeral_duration': ephemeralDuration ?? 86400, // Default to 24h
        'call_id': callId,
      };

      // Add encryption fields if provided
      if (encryptedKeys != null) {
        insertData['encrypted_keys'] = encryptedKeys;
      }
      if (iv != null) {
        insertData['iv'] = iv;
      }
      if (signalMessageType != null) {
        insertData['signal_message_type'] = signalMessageType;
      }
      if (signalSenderContent != null) {
        insertData['signal_sender_content'] = signalSenderContent;
      }
      if (signalSenderMessageType != null) {
        insertData['signal_sender_message_type'] = signalSenderMessageType;
      }

      // Store media URL in the appropriate column based on message type
      if (mediaUrl != null) {
        switch (messageType) {
          case MessageType.image:
            insertData['image_url'] = mediaUrl;
            break;
          case MessageType.document:
            insertData['file_url'] = mediaUrl;
            break;
          default:
            // For text or other types, don't set a media URL
            break;
        }
      }

      await _supabase.from(SupabaseConfig.messagesTable).insert(insertData);

      // Update conversation's last message and timestamp
      await _supabase
          .from(SupabaseConfig.conversationsTable)
          .update({
            'last_message_id': messageId,
            'last_message_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', conversationId);

      // Fetch the created message with sender details
      final response =
          await _supabase
              .from(SupabaseConfig.messagesTable)
              .select('''
            *,
            ${SupabaseConfig.profilesTable}:sender_id (
              username,
              avatar_url
            ),
            reactions:message_reactions(*)
          ''')
              .eq('id', messageId)
              .single();

      final messageMap = Map<String, dynamic>.from(response);
      final profile = messageMap[SupabaseConfig.profilesTable];
      if (profile != null) {
        messageMap['sender_name'] = profile['username'];
        messageMap['sender_avatar'] = profile['avatar_url'];
      }

      final message = Message.fromJson(messageMap);

      // Trigger notifications for other participants
      try {
        final participantsResponse = await _supabase
            .from('conversation_participants')
            .select('user_id')
            .eq('conversation_id', conversationId)
            .neq('user_id', senderId);

        for (final participant in participantsResponse) {
          final recipientId = participant['user_id'] as String;
          await _notificationService.createNotification(
            userId: recipientId,
            type: 'dm',
            actorId: senderId,
            message: content,
          );
        }
      } catch (e) {
        debugPrint('Error triggering message notification: $e');
      }

      return message;
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  /// Upload chat media (supports encryption)
  Future<String> uploadChatMedia(
    String filePath, {
    String folder = 'images',
    Uint8List? encryptedBytes, // If provided, uploads these bytes directly
    String? fileExtension, // Required if encryptedBytes is provided
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final fileExt = fileExtension ?? filePath.split('.').last;
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4()}.$fileExt';

      if (encryptedBytes != null) {
        // Upload encrypted bytes directly
        await _supabase.storage
            .from(SupabaseConfig.messageAttachmentsBucket)
            .uploadBinary('$userId/$folder/$fileName', encryptedBytes);
      } else {
        // Upload normal file
        final file = File(filePath);
        await _supabase.storage
            .from(SupabaseConfig.messageAttachmentsBucket)
            .upload('$userId/$folder/$fileName', file);
      }

      final publicUrl = _supabase.storage
          .from(SupabaseConfig.messageAttachmentsBucket)
          .getPublicUrl('$userId/$folder/$fileName');

      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading chat media: $e');
      rethrow;
    }
  }

  /// Mark message as read
  Future<void> markAsRead({
    required String messageId,
    required String userId,
  }) async {
    try {
      // Use message_read_receipts table instead of is_read column
      await _supabase.from(SupabaseConfig.messageReadReceiptsTable).upsert({
        'message_id': messageId,
        'user_id': userId,
        'read_at': DateTime.now().toIso8601String(),
      }, onConflict: 'message_id,user_id');
    } catch (e) {
      debugPrint('Error marking message as read: $e');
      rethrow;
    }
  }

  /// Subscribe to new messages in a conversation
  RealtimeChannel subscribeToMessages({
    required String conversationId,
    required Function(Message) onNewMessage,
  }) {
    final channel = _supabase.channel('messages:$conversationId');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: SupabaseConfig.messagesTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) async {
            try {
              final messageData = payload.newRecord;

              // Fetch sender details
              final profile =
                  await _supabase
                      .from(SupabaseConfig.profilesTable)
                      .select('username, avatar_url')
                      .eq('id', messageData['sender_id'])
                      .single();

              messageData['sender_name'] = profile['username'];
              messageData['sender_avatar'] = profile['avatar_url'];

              final message = Message.fromJson(messageData);
              onNewMessage(message);
            } catch (e) {
              debugPrint('Error processing new message: $e');
            }
          },
        )
        .subscribe();

    return channel;
  }

  /// Subscribe to conversation updates (unread count, participants changes)
  RealtimeChannel subscribeToConversations({
    required String userId,
    required Function() onUpdate,
  }) {
    final channel = _supabase.channel('user_conversations:$userId');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: SupabaseConfig.conversationParticipantsTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            onUpdate();
          },
        )
        .subscribe();

    return channel;
  }

  /// Subscribe to read receipts for a conversation
  RealtimeChannel subscribeToReadReceipts({
    required String conversationId,
    required Function(String messageId, String userId, DateTime readAt)
    onUpdate,
  }) {
    final channel = _supabase.channel('read_receipts:$conversationId');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: SupabaseConfig.messageReadReceiptsTable,
          callback: (payload) {
            try {
              final data = payload.newRecord;
              final messageId = data['message_id'] as String;
              final userId = data['user_id'] as String;
              final readAt = DateTime.parse(data['read_at'] as String);
              onUpdate(messageId, userId, readAt);
            } catch (e) {
              debugPrint('Error processing read receipt: $e');
            }
          },
        )
        .subscribe();

    return channel;
  }

  /// Unsubscribe from messages
  Future<void> unsubscribeFromMessages(RealtimeChannel channel) async {
    await _supabase.removeChannel(channel);
  }

  /// Delete a message
  Future<void> deleteMessage({
    required String messageId,
    required String userId,
  }) async {
    try {
      // Verify sender
      final message =
          await _supabase
              .from(SupabaseConfig.messagesTable)
              .select('sender_id')
              .eq('id', messageId)
              .single();

      if (message['sender_id'] != userId) {
        throw Exception('Not authorized to delete this message');
      }

      await _supabase
          .from(SupabaseConfig.messagesTable)
          .delete()
          .eq('id', messageId);
    } catch (e) {
      debugPrint('Error deleting message: $e');
      rethrow;
    }
  }

  /// Update typing status
  Future<void> updateTypingStatus(
    String conversationId,
    String userId,
    bool isTyping,
  ) async {
    try {
      await _supabase.from('typing_indicators').upsert({
        'conversation_id': conversationId,
        'user_id': userId,
        'is_typing': isTyping,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error updating typing status: $e');
      rethrow;
    }
  }

  /// Subscribe to chat background changes
  RealtimeChannel subscribeToBackgroundChanges({
    required String conversationId,
    required Function(String? backgroundUrl) onUpdate,
  }) {
    final channel = _supabase.channel('chat_backgrounds:$conversationId');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_themes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            try {
              final data = payload.newRecord;
              final backgroundUrl = data['background_image_url'] as String?;
              onUpdate(backgroundUrl);
            } catch (e) {
              debugPrint('Error processing background update: $e');
            }
          },
        )
        .subscribe();

    return channel;
  }

  /// Subscribe to typing status updates
  RealtimeChannel subscribeToTypingStatus({
    required String conversationId,
    required Function(String userId, bool isTyping) onTypingUpdate,
  }) {
    final channel = _supabase.channel('typing:$conversationId');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'typing_indicators',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            try {
              final data = payload.newRecord;
              final userId = data['user_id'] as String;
              final isTyping = data['is_typing'] as bool;
              onTypingUpdate(userId, isTyping);
            } catch (e) {
              debugPrint('Error processing typing status update: $e');
            }
          },
        )
        .subscribe();

    return channel;
  }

  /// Unsubscribe from typing status
  Future<void> unsubscribeFromTypingStatus(RealtimeChannel channel) async {
    await _supabase.removeChannel(channel);
  }

  /// Get unread message count for a conversation
  Future<int> getUnreadCount(String conversationId, String userId) async {
    try {
      // Get all messages in conversation not sent by user
      final messages = await _supabase
          .from(SupabaseConfig.messagesTable)
          .select('id')
          .eq('conversation_id', conversationId)
          .neq('sender_id', userId);

      if (messages.isEmpty) return 0;

      // Get read receipts for these messages
      final messageIds = messages.map((m) => m['id']).toList();
      final readReceipts = await _supabase
          .from(SupabaseConfig.messageReadReceiptsTable)
          .select('message_id')
          .inFilter('message_id', messageIds)
          .eq('user_id', userId);

      final readMessageIds = readReceipts.map((r) => r['message_id']).toSet();
      return messages.where((m) => !readMessageIds.contains(m['id'])).length;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  /// Mark all messages in conversation as read
  Future<void> markConversationAsRead(
    String conversationId,
    String userId,
  ) async {
    try {
      // Get all messages in conversation not sent by user
      final messages = await _supabase
          .from(SupabaseConfig.messagesTable)
          .select('id')
          .eq('conversation_id', conversationId)
          .neq('sender_id', userId);

      // We still want to reset unread count even if there are no messages,
      // just to be safe and ensure UI consistency
      await _supabase.rpc(
        'reset_unread_count',
        params: {'p_conversation_id': conversationId, 'p_user_id': userId},
      );

      if (messages.isEmpty) return;

      // Create read receipts for all messages
      final readReceipts =
          messages
              .map(
                (m) => {
                  'message_id': m['id'],
                  'user_id': userId,
                  'read_at': DateTime.now().toIso8601String(),
                },
              )
              .toList();

      // Use upsert to avoid duplicates
      await _supabase
          .from(SupabaseConfig.messageReadReceiptsTable)
          .upsert(readReceipts, onConflict: 'message_id,user_id');
    } catch (e) {
      debugPrint('Error marking conversation as read: $e');
      rethrow;
    }
  }

  /// Toggle Whisper Mode for a conversation
  Future<void> toggleWhisperMode(String conversationId, bool isEnabled) async {
    try {
      await _supabase
          .from(SupabaseConfig.conversationsTable)
          .update({'is_whisper_mode': isEnabled})
          .eq('id', conversationId);
    } catch (e) {
      debugPrint('Error toggling whisper mode: $e');
      rethrow;
    }
  }

  /// Get conversation details
  Future<Conversation> getConversationDetails(String conversationId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final response =
          await _supabase
              .from(SupabaseConfig.conversationsTable)
              .select('''
            *,
            conversation_participants!inner(user_id)
          ''')
              .eq('id', conversationId)
              .single();

      final conversationMap = Map<String, dynamic>.from(response);

      // For direct conversations, get the other participant
      if (conversationMap['type'] == 'direct') {
        final participants = await _supabase
            .from('conversation_participants')
            .select('user_id')
            .eq('conversation_id', conversationId)
            .neq('user_id', userId);

        if (participants.isNotEmpty) {
          final otherUserId = participants.first['user_id'];
          final profile =
              await _supabase
                  .from(SupabaseConfig.profilesTable)
                  .select('username, avatar_url')
                  .eq('id', otherUserId)
                  .single();

          conversationMap['other_user_id'] = otherUserId;
          conversationMap['other_user_name'] = profile['username'] ?? 'Unknown';
          conversationMap['other_user_avatar'] = profile['avatar_url'] ?? '';
        }
      }

      return Conversation.fromJson(conversationMap);
    } catch (e) {
      debugPrint('Error getting conversation details: $e');
      rethrow;
    }
  }
}
