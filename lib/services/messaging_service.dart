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
  final SupabaseClient _supabase;
  final _uuid = const Uuid();
  late final NotificationService _notificationService;

  MessagingService({SupabaseClient? client, NotificationService? notificationService}) 
      : _supabase = client ?? SupabaseService().client,
        _notificationService = notificationService ?? NotificationService();

  /// Get user's conversations
  Future<List<Conversation>> getConversations({
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      // Use the bulletproof RPC that queries messages directly for each conversation
      // to ensure the TRUE latest message is always fetched for sorting and preview.
      final List<dynamic> response = await _supabase.rpc(
        'get_user_conversations_v2',
        params: {'p_user_id': userId},
      );

      if (response.isEmpty) return [];

      final List<Conversation> conversations = [];
      for (final item in response) {
        final conversationMap = Map<String, dynamic>.from(item);
        
        // 1. Extract "other user" info from the all_participants list
        if (conversationMap['type'] == 'direct' && conversationMap['all_participants'] != null) {
          final participants = conversationMap['all_participants'] as List;
          final otherParticipant = participants.firstWhere(
            (p) => p['user_id'] != userId,
            orElse: () => participants.isNotEmpty ? participants[0] : null,
          );

          if (otherParticipant != null && otherParticipant['profile'] != null) {
            final profile = otherParticipant['profile'];
            conversationMap['other_user_id'] = otherParticipant['user_id'];
            conversationMap['other_user_name'] = profile['username'] ?? profile['full_name'] ?? 'Unknown';
            conversationMap['other_user_avatar'] = profile['avatar_url'] ?? '';
          }
        } else {
          conversationMap['other_user_id'] = '';
          conversationMap['other_user_name'] = conversationMap['name'] ?? 'Group Chat';
          conversationMap['other_user_avatar'] = conversationMap['image_url'] ?? '';
        }

        // Initialize last_message_time from sort_time (which is the true latest activity)
        conversationMap['last_message_time'] = conversationMap['sort_time'];

        // 2. Process the TRUE last message data
        final lastMsgData = conversationMap['last_message_data'];
        if (lastMsgData != null) {
          String content = lastMsgData['content'] ?? '';
          final isSender = lastMsgData['sender_id'] == userId;

          // Decryption Logic
          try {
            if (isSender && lastMsgData['msg_signal_sender_content'] != null && lastMsgData['msg_encrypted_keys'] != null && lastMsgData['msg_iv'] != null) {
              final decrypted = await EncryptionService().decryptMessage(
                lastMsgData['msg_signal_sender_content'],
                Map<String, String>.from(lastMsgData['msg_encrypted_keys']),
                lastMsgData['msg_iv'],
              );
              content = decrypted ?? '🔒 Message encrypted';
            } else if (!isSender && lastMsgData['msg_signal_type'] != null) {
              await SignalService().init();
              content = await SignalService().decryptMessage(
                lastMsgData['sender_id'],
                content,
                lastMsgData['msg_signal_type'],
              );
              
              if (content.contains('🔒') && lastMsgData['msg_encrypted_keys'] != null && lastMsgData['msg_iv'] != null && lastMsgData['msg_signal_sender_content'] != null) {
                final rsaDecrypted = await EncryptionService().decryptMessage(
                  lastMsgData['msg_signal_sender_content'],
                  Map<String, String>.from(lastMsgData['msg_encrypted_keys']),
                  lastMsgData['msg_iv'],
                );
                if (rsaDecrypted != null) content = rsaDecrypted;
              }
            } else if (lastMsgData['msg_encrypted_keys'] != null && lastMsgData['msg_iv'] != null) {
              final decrypted = await EncryptionService().decryptMessage(
                content,
                Map<String, String>.from(lastMsgData['msg_encrypted_keys']),
                lastMsgData['msg_iv'],
              );
              content = decrypted ?? '🔒 Message encrypted';
            }
          } catch (e) {
            content = '🔒 Message encrypted';
          }

          conversationMap['last_message'] = content;
          conversationMap['last_message_sender_id'] = lastMsgData['sender_id'];
          
          // Type detection
          String messageType = 'text';
          if (lastMsgData['msg_voice_url'] != null && lastMsgData['msg_voice_url'].toString().isNotEmpty) messageType = 'voice';
          else if (lastMsgData['msg_image_url'] != null && lastMsgData['msg_image_url'].toString().isNotEmpty) messageType = 'image';
          else if (lastMsgData['msg_video_url'] != null && lastMsgData['msg_video_url'].toString().isNotEmpty) messageType = 'video';
          else if (lastMsgData['msg_file_url'] != null && lastMsgData['msg_file_url'].toString().isNotEmpty) messageType = 'document';
          conversationMap['last_message_type'] = messageType;
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
    DateTime? sessionStart,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      // Fetch cleared_at timestamp for this user in this conversation
      final participantResponse = await _supabase
          .from('conversation_participants')
          .select('cleared_at')
          .eq('conversation_id', conversationId)
          .eq('user_id', userId)
          .maybeSingle();

      final clearedAt = participantResponse != null && participantResponse['cleared_at'] != null
          ? DateTime.parse(participantResponse['cleared_at'])
          : null;

      var query = _supabase
          .from(SupabaseConfig.messagesTable)
          .select('''
            *,
            sender_profile:sender_id (
              username,
              avatar_url
            ),
            reply_to:reply_to_id (
              id,
              content,
              sender_id,
              image_url,
              video_url,
              file_url,
              voice_url,
              iv,
              encrypted_keys,
              signal_message_type,
              signal_sender_content,
              profiles:sender_id (
                username
              )
            ),
            reactions:message_reactions(*)
          ''')
          .eq('conversation_id', conversationId);

      // Filter out messages deleted before 'cleared_at'
      if (clearedAt != null) {
        query = query.gte('created_at', clearedAt.toIso8601String());
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      if (response.isEmpty) return [];

      final currentUserId = _supabase.auth.currentUser?.id;
      final List<Message> messages = [];
      final List<String> messageIds = [];

      for (final item in response) {
        final messageMap = Map<String, dynamic>.from(item);
        final profile = messageMap['sender_profile'];
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
          final myReadTimeStr = myReadMap[messages[i].id];
          final anyReadTimeStr = firstReadMap[messages[i].id];

          DateTime? myReadAt;
          DateTime? anyReadAt;

          if (myReadTimeStr != null) {
            myReadAt = DateTime.parse(myReadTimeStr);
          }
          if (anyReadTimeStr != null) {
            anyReadAt = DateTime.parse(anyReadTimeStr);
          }

          if (myReadAt != null || anyReadAt != null) {
            messages[i] = messages[i].copyWith(
              readAt: myReadAt,
              anyReadAt: anyReadAt,
              isRead: myReadAt != null, // Message is read if the current user has read it
            );
          }
        }
      }

      // Filter out expired ephemeral messages
      final visibleMessages = MessagingService.filterExpiredMessages(
        messages,
        sessionStart: sessionStart,
      );

      return visibleMessages.reversed.toList(); // Reverse to show oldest first
    } catch (e) {
      debugPrint('Error fetching messages: $e');
      rethrow;
    }
  }

  /// Filter out expired ephemeral messages
  /// Visible if:
  /// 1. Not ephemeral
  /// 2. Is ephemeral but not read yet by ANYONE
  /// 3. Is ephemeral (Duration > 0), read by someone, but seen < duration ago
  /// 4. Is ephemeral (Duration 0 - Vanish Mode), but read during CURRENT session
  static List<Message> filterExpiredMessages(
    List<Message> messages, {
    DateTime? sessionStart,
  }) {
    if (messages.isEmpty) return [];

    final now = DateTime.now();

    return messages.where((message) {
      if (!message.isEphemeral) return true;

      // Use anyReadAt to determine if the message should vanish for everyone
      // If nobody has read it yet, it's visible to everyone
      if (message.anyReadAt == null) return true;

      // Calculate expiration based on message's duration
      final duration = Duration(seconds: message.ephemeralDuration);

      // Duration 0 (Vanish instantly on reopen - Instagram style)
      if (message.ephemeralDuration == 0) {
        if (sessionStart != null) {
          // Keep it visible if it was read DURING this session
          return message.anyReadAt!.isAfter(sessionStart);
        }
        // If no session start provided (e.g. background check), we assume it's "old"
        return false;
      }

      final expirationTime = message.anyReadAt!.add(duration);
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
    String? replyToId,
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
        'reply_to_id': replyToId,
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
          case MessageType.voice:
            insertData['voice_url'] = mediaUrl;
            insertData['voice_duration'] = voiceDuration;
            break;
          default:
            // For text or other types, don't set a media URL
            break;
        }
      }

      await _supabase.from(SupabaseConfig.messagesTable).insert(insertData);

      // Fetch the created message with sender details
      final response =
          await _supabase
              .from(SupabaseConfig.messagesTable)
              .select('''
            *,
            sender_profile:sender_id (
              username,
              avatar_url
            ),
            reply_to:reply_to_id (
              id,
              content,
              sender_id,
              image_url,
              video_url,
              file_url,
              voice_url,
              iv,
              encrypted_keys,
              signal_message_type,
              signal_sender_content,
              profiles:sender_id (
                username
              )
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

      // Update conversation's last message and timestamp manually using the message's actual creation time
      // This ensures consistency even if the trigger is delayed or missing.
      await _supabase
          .from(SupabaseConfig.conversationsTable)
          .update({
            'last_message_id': message.id,
            'last_message_at': message.timestamp.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', conversationId);

      // Trigger notifications for other participants
      try {
        final participantsResponse = await _supabase
            .from('conversation_participants')
            .select('user_id')
            .eq('conversation_id', conversationId)
            .neq('user_id', senderId);

        // Fetch sender's profile for the notification title
        final senderProfile = await _supabase
            .from(SupabaseConfig.profilesTable)
            .select('username')
            .eq('id', senderId)
            .single();
            
        final senderName = senderProfile['username'] ?? 'Someone';

        for (final participant in participantsResponse) {
          final recipientId = participant['user_id'] as String;
          
          // Use a placeholder for encrypted messages in notifications
          final notificationMessage = (encryptedKeys != null || signalMessageType != null)
              ? '🔒 Encrypted Message'
              : content;
          
          await _notificationService.createNotification(
            userId: recipientId,
            type: 'dm',
            actorId: senderId,
            title: senderName,
            message: notificationMessage,
            messageId: messageId,
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
    Function(String)? onDeleteMessage,
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

              // If it's a reply, fetch the replied message details
              if (messageData['reply_to_id'] != null) {
                final replyResponse = await _supabase
                    .from(SupabaseConfig.messagesTable)
                    .select('''
                      id,
                      content,
                      sender_id,
                      image_url,
                      video_url,
                      file_url,
                      voice_url,
                      iv,
                      encrypted_keys,
                      signal_message_type,
                      signal_sender_content,
                      profiles:sender_id (
                        username
                      )
                    ''')
                    .eq('id', messageData['reply_to_id'])
                    .maybeSingle();
                
                if (replyResponse != null) {
                  messageData['reply_to'] = replyResponse;
                }
              }

              final message = Message.fromJson(messageData);
              onNewMessage(message);
            } catch (e) {
              debugPrint('Error processing new message: $e');
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: SupabaseConfig.messagesTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            if (onDeleteMessage != null) {
              final messageId = payload.oldRecord['id'] as String;
              onDeleteMessage(messageId);
            }
          },
        )
        .subscribe();

    return channel;
  }

  /// Delete (unsend) a message
  Future<void> deleteMessage(String messageId) async {
    try {
      // First, get message details to check for media
      final messageResponse = await _supabase
          .from(SupabaseConfig.messagesTable)
          .select('image_url, video_url, file_url, voice_url')
          .eq('id', messageId)
          .maybeSingle();

      if (messageResponse != null) {
        // Collect all potential media URLs
        final mediaUrls = [
          messageResponse['image_url'],
          messageResponse['video_url'],
          messageResponse['file_url'],
          messageResponse['voice_url'],
        ].where((url) => url != null && url.toString().isNotEmpty).toList();

        // Delete from database first
        await _supabase
            .from(SupabaseConfig.messagesTable)
            .delete()
            .eq('id', messageId);

        // Then attempt to delete from storage if URLs are present
        for (final url in mediaUrls) {
          try {
            final uri = Uri.parse(url as String);
            final pathSegments = uri.pathSegments;
            // Expected path: /storage/v1/object/public/bucket-name/folder/filename
            // Segments: [storage, v1, object, public, bucket-name, folder, user-id, folder, filename]
            // This is complex to parse reliably from URL, but usually it's after the bucket name
            
            final bucketName = SupabaseConfig.messageAttachmentsBucket;
            final bucketIndex = pathSegments.indexOf(bucketName);
            if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
              final storagePath = pathSegments.sublist(bucketIndex + 1).join('/');
              await _supabase.storage.from(bucketName).remove([storagePath]);
              debugPrint('Deleted storage object: $storagePath');
            }
          } catch (e) {
            debugPrint('Failed to delete media from storage: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error deleting message: $e');
      rethrow;
    }
  }

  /// Subscribe to conversation updates (unread count, participants changes)
  RealtimeChannel subscribeToConversations({
    required String userId,
    required Function(String conversationId) onUpdate,
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
            if (payload.newRecord.isNotEmpty) {
              final conversationId = payload.newRecord['conversation_id'] as String;
              onUpdate(conversationId);
            }
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

  /// Clear chat for current user only (hides messages before now)
  Future<void> clearChatForMe(String conversationId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      // Use database-side NOW() with a small buffer to avoid clock sync issues
      await _supabase
          .from('conversation_participants')
          .update({'cleared_at': 'now()'})
          .eq('conversation_id', conversationId)
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('Error clearing chat for me: $e');
      rethrow;
    }
  }

  /// Clear all messages in a conversation
  Future<void> clearConversationMessages(String conversationId) async {
    try {
      // Delete all messages in the conversation
      await _supabase
          .from(SupabaseConfig.messagesTable)
          .delete()
          .eq('conversation_id', conversationId);

      // Update conversation's last message and timestamp to null
      await _supabase
          .from(SupabaseConfig.conversationsTable)
          .update({
            'last_message_id': null,
            'last_message_at': null,
          })
          .eq('id', conversationId);
    } catch (e) {
      debugPrint('Error clearing conversation messages: $e');
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

  /// Update chat background for all participants
  Future<void> updateChatBackground(String conversationId, String? backgroundUrl) async {
    try {
      // Fetch all participants
      final participants = await _supabase
          .from('conversation_participants')
          .select('user_id')
          .eq('conversation_id', conversationId);

      // Upsert theme for each participant
      for (final participant in participants) {
        final userId = participant['user_id'] as String;
        await _supabase.from('chat_themes').upsert({
          'conversation_id': conversationId,
          'user_id': userId,
          'background_image_url': backgroundUrl,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'conversation_id, user_id');
      }
    } catch (e) {
      debugPrint('Error updating chat background: $e');
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

      // 1. Fetch conversation and participant info
      final response =
          await _supabase
              .from(SupabaseConfig.conversationsTable)
              .select('''
            *,
            my_participant_info:conversation_participants!inner(
              unread_count,
              user_id,
              cleared_at
            ),
            all_participants:conversation_participants(
              user_id,
              profile:${SupabaseConfig.profilesTable}(
                username,
                full_name,
                avatar_url
              )
            )
          ''')
              .eq('id', conversationId)
              .eq('my_participant_info.user_id', userId)
              .single();

      final conversationMap = Map<String, dynamic>.from(response);
      
      // Extract unread count and cleared_at
      final myInfo = conversationMap['my_participant_info'] as List;
      conversationMap['unread_count'] = myInfo.isNotEmpty ? (myInfo[0]['unread_count'] ?? 0) : 0;
      final clearedAtStr = myInfo.isNotEmpty ? myInfo[0]['cleared_at'] as String? : null;
      final clearedAt = clearedAtStr != null ? DateTime.parse(clearedAtStr) : null;

      // Extract "other user" info
      if (conversationMap['type'] == 'direct' && conversationMap['all_participants'] != null) {
        final participants = conversationMap['all_participants'] as List;
        final otherParticipant = participants.firstWhere(
          (p) => p['user_id'] != userId,
          orElse: () => participants.isNotEmpty ? participants[0] : null,
        );

        if (otherParticipant != null && otherParticipant['profile'] != null) {
          final profile = otherParticipant['profile'];
          conversationMap['other_user_id'] = otherParticipant['user_id'];
          conversationMap['other_user_name'] = profile['username'] ?? profile['full_name'] ?? 'Unknown';
          conversationMap['other_user_avatar'] = profile['avatar_url'] ?? '';
        }
      } else {
        conversationMap['other_user_id'] = '';
        conversationMap['other_user_name'] = conversationMap['name'] ?? 'Group Chat';
        conversationMap['other_user_avatar'] = conversationMap['image_url'] ?? '';
      }

      // 2. Fetch the TRUE latest message directly from messages table (bulletproof)
      final lastMsgResponse = await _supabase
          .from(SupabaseConfig.messagesTable)
          .select('''
            id,
            content,
            sender_id,
            created_at,
            image_url,
            video_url,
            file_url,
            voice_url,
            iv,
            encrypted_keys,
            signal_message_type,
            signal_sender_content
          ''')
          .eq('conversation_id', conversationId)
          .filter('created_at', 'gt', clearedAt?.toIso8601String() ?? '1970-01-01')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (lastMsgResponse != null) {
        final lastMsgData = Map<String, dynamic>.from(lastMsgResponse);
        final msgCreatedAtStr = lastMsgData['created_at'] as String?;
        final msgCreatedAt = msgCreatedAtStr != null ? DateTime.parse(msgCreatedAtStr) : null;

        String content = lastMsgData['content'] ?? '';
        final isSender = lastMsgData['sender_id'] == userId;

        // Decryption Logic
        try {
          if (isSender && lastMsgData['signal_sender_content'] != null && lastMsgData['encrypted_keys'] != null && lastMsgData['iv'] != null) {
            final decrypted = await EncryptionService().decryptMessage(
              lastMsgData['signal_sender_content'],
              Map<String, String>.from(lastMsgData['encrypted_keys']),
              lastMsgData['iv'],
            );
            content = decrypted ?? '🔒 Message encrypted';
          } else if (!isSender && lastMsgData['signal_message_type'] != null) {
            await SignalService().init();
            content = await SignalService().decryptMessage(
              lastMsgData['sender_id'],
              content,
              lastMsgData['signal_message_type'],
            );
            
            if (content.contains('🔒') && lastMsgData['encrypted_keys'] != null && lastMsgData['iv'] != null && lastMsgData['signal_sender_content'] != null) {
              final rsaDecrypted = await EncryptionService().decryptMessage(
                lastMsgData['signal_sender_content'],
                Map<String, String>.from(lastMsgData['encrypted_keys']),
                lastMsgData['iv'],
              );
              if (rsaDecrypted != null) content = rsaDecrypted;
            }
          } else if (lastMsgData['encrypted_keys'] != null && lastMsgData['iv'] != null) {
            final decrypted = await EncryptionService().decryptMessage(
              content,
              Map<String, String>.from(lastMsgData['encrypted_keys']),
              lastMsgData['iv'],
            );
            content = decrypted ?? '🔒 Message encrypted';
          }
        } catch (e) {
          content = '🔒 Message encrypted';
        }

        conversationMap['last_message'] = content;
        conversationMap['last_message_time'] = lastMsgData['created_at'];
        conversationMap['last_message_sender_id'] = lastMsgData['sender_id'];
        
        // Type detection
        String messageType = 'text';
        if (lastMsgData['voice_url'] != null) messageType = 'voice';
        else if (lastMsgData['image_url'] != null) messageType = 'image';
        else if (lastMsgData['video_url'] != null) messageType = 'video';
        else if (lastMsgData['file_url'] != null) messageType = 'document';
        conversationMap['last_message_type'] = messageType;
      } else {
        // No messages after cleared_at
        conversationMap['last_message'] = null;
        conversationMap['last_message_time'] = conversationMap['last_message_at'] ?? conversationMap['created_at'];
      }

      return Conversation.fromJson(conversationMap);
    } catch (e) {
      debugPrint('Error getting conversation details: $e');
      rethrow;
    }
  }
}
