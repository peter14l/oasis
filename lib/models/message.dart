import 'package:flutter/foundation.dart';
import 'package:oasis_v2/models/message_reaction.dart';

enum MessageType { text, image, document, voice, poll, location, ripple, story_reply, post_share }

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String content;
  final bool isRead;
  final DateTime? readAt;
  final DateTime? anyReadAt; // Earliest read time by ANY participant
  final DateTime timestamp;

  // New fields for media messages
  final MessageType messageType;
  final String? mediaUrl;
  final String? mediaThumbnailUrl;
  final String? mediaFileName;
  final int? mediaFileSize;
  final String? mediaMimeType;
  final Map<String, dynamic>? pollData;
  final Map<String, dynamic>? locationData;
  final Map<String, dynamic>? shareData;
  final int? voiceDuration; // in seconds

  // Reply context
  final String? replyToId;
  final String? replyToContent;
  final String? replyToSenderName;
  final Map<String, dynamic>? replyToData;

  // Reactions
  final List<MessageReactionModel> reactions;

  // E2E Encryption fields
  final bool isEphemeral;
  final int ephemeralDuration; // in seconds, 0 = immediate, 86400 = 24h
  final DateTime? expiresAt;
  final Map<String, dynamic>? encryptedKeys;
  final String? iv;
  final int? signalMessageType; // 2 = Normal, 3 = PreKey
  final String? signalSenderContent; // Encrypted copy for sender
  final int? signalSenderMessageType;
  final String? callId;
  final String? rippleId;
  final String? storyId;
  final String? postId;

  // View once/twice media
  final String mediaViewMode; // 'unlimited', 'once', 'twice'
  final int currentUserViewCount;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.content,
    this.isRead = false,
    this.readAt,
    this.anyReadAt,
    required this.timestamp,
    this.messageType = MessageType.text,
    this.mediaUrl,
    this.mediaThumbnailUrl,
    this.mediaFileName,
    this.mediaFileSize,
    this.mediaMimeType,
    this.pollData,
    this.locationData,
    this.shareData,
    this.voiceDuration,
    this.replyToId,
    this.replyToContent,
    this.replyToSenderName,
    this.replyToData,
    this.reactions = const [],
    this.isEphemeral = false,
    this.ephemeralDuration = 86400, // Default to 24 hours
    this.expiresAt,
    this.encryptedKeys,
    this.iv,
    this.signalMessageType,
    this.signalSenderContent,
    this.signalSenderMessageType,
    this.callId,
    this.rippleId,
    this.storyId,
    this.postId,
    this.mediaViewMode = 'unlimited',
    this.currentUserViewCount = 0,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    // Derive message type from URL fields since message_type column doesn't exist
    MessageType type = MessageType.text;

    if (json['message_type'] != null) {
      type = MessageType.values.firstWhere(
        (e) => e.name == json['message_type'],
        orElse: () => MessageType.text,
      );
    } else {
      if (json['voice_url'] != null && json['voice_url'].toString().isNotEmpty) {
        type = MessageType.voice;
      } else if (json['image_url'] != null && json['image_url'].toString().isNotEmpty) {
        type = MessageType.image;
      } else if (json['video_url'] != null &&
          json['video_url'].toString().isNotEmpty) {
        type = MessageType.image; // Treat video as image for now
      } else if (json['file_url'] != null &&
          json['file_url'].toString().isNotEmpty) {
        type = MessageType.document;
      } else if (json['post_id'] != null) {
        type = MessageType.post_share;
      } else if (json['ripple_id'] != null) {
        type = MessageType.ripple;
      }
    }

    debugPrint('Mapping message ${json['id']} type: $type');

    // Consolidate media URLs into single mediaUrl field
    String? mediaUrl;
    if (json['voice_url'] != null) {
      mediaUrl = json['voice_url'] as String?;
    } else if (json['image_url'] != null) {
      mediaUrl = json['image_url'] as String?;
    } else if (json['video_url'] != null) {
      mediaUrl = json['video_url'] as String?;
    } else if (json['file_url'] != null) {
      mediaUrl = json['file_url'] as String?;
    }

    // Handle replied message metadata if available
    String? replyContent;
    String? replySenderName;
    if (json['reply_to'] != null) {
      final replyData = json['reply_to'] as Map<String, dynamic>;
      final isEncrypted = replyData['encrypted_keys'] != null || replyData['signal_message_type'] != null;
      
      if (isEncrypted) {
        // Use placeholders for encrypted replies in synchronous mapping
        // These will be replaced with decrypted text in the UI layer if possible
        if (replyData['voice_url'] != null) {
          replyContent = '🎤 Voice Message';
        } else if (replyData['image_url'] != null) {
          replyContent = '📷 Photo';
        } else if (replyData['video_url'] != null) {
          replyContent = '🎥 Video';
        } else if (replyData['file_url'] != null) {
          replyContent = '📁 File';
        } else {
          replyContent = '🔒 Encrypted message';
        }
      } else {
        replyContent = replyData['content'] as String?;
      }

      if (replyData['profiles'] != null) {
        replySenderName = replyData['profiles']['username'] as String?;
      }
    }

    return Message(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      senderName: json['sender_name'] as String? ?? '',
      senderAvatar: json['sender_avatar'] as String? ?? '',
      content: json['content'] as String? ?? '',
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      anyReadAt: json['any_read_at'] != null ? DateTime.parse(json['any_read_at']) : null,
      timestamp:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
      messageType: type,
      mediaUrl: mediaUrl,
      mediaThumbnailUrl: json['media_thumbnail_url'] as String?,
      mediaFileName: json['file_name'] as String?,
      mediaFileSize: json['file_size'] as int?,
      mediaMimeType: json['media_mime_type'] as String?,
      pollData: json['poll_data'] as Map<String, dynamic>?,
      locationData: json['location_data'] as Map<String, dynamic>?,
      shareData: json['share_data'] as Map<String, dynamic>?,
      voiceDuration: json['voice_duration'] as int?,
      replyToId: json['reply_to_id'] as String?,
      replyToContent: replyContent,
      replyToSenderName: replySenderName,
      replyToData: json['reply_to'] as Map<String, dynamic>?,
      reactions:
          (json['reactions'] as List<dynamic>?)
              ?.map(
                (e) => MessageReactionModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      isEphemeral: json['is_ephemeral'] as bool? ?? false,
      ephemeralDuration: json['ephemeral_duration'] as int? ?? 86400,
      expiresAt:
          json['expires_at'] != null
              ? DateTime.parse(json['expires_at'] as String)
              : null,
      encryptedKeys: json['encrypted_keys'] as Map<String, dynamic>?,
      iv: json['iv'] as String?,
      signalMessageType: json['signal_message_type'] as int?,
      signalSenderContent: json['signal_sender_content'] as String?,
      signalSenderMessageType: json['signal_sender_message_type'] as int?,
      callId: json['call_id'] as String?,
      rippleId: json['ripple_id'] as String?,
      storyId: json['story_id'] as String?,
      postId: json['post_id'] as String?,
      mediaViewMode: json['media_view_mode'] as String? ?? 'unlimited',
      currentUserViewCount: json['current_user_view_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_avatar': senderAvatar,
      'content': content,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'any_read_at': anyReadAt?.toIso8601String(),
      'created_at': timestamp.toIso8601String(),
      'message_type': messageType.name,
      'image_url': messageType == MessageType.image ? mediaUrl : null,
      'file_url': messageType == MessageType.document ? mediaUrl : null,
      'voice_url': messageType == MessageType.voice ? mediaUrl : null,
      'voice_duration': voiceDuration,
      'reply_to_id': replyToId,
      'file_name': mediaFileName,
      'file_size': mediaFileSize,
      'media_mime_type': mediaMimeType,
      'poll_data': pollData,
      'location_data': locationData,
      'share_data': shareData,
      'is_ephemeral': isEphemeral,
      'ephemeral_duration': ephemeralDuration,
      'expires_at': expiresAt?.toIso8601String(),
      'encrypted_keys': encryptedKeys,
      'iv': iv,
      'signal_message_type': signalMessageType,
      'signal_sender_content': signalSenderContent,
      'signal_sender_message_type': signalSenderMessageType,
      'call_id': callId,
      'ripple_id': rippleId,
      'story_id': storyId,
      'post_id': postId,
      'media_view_mode': mediaViewMode,
    };
  }

  Message copyWith({
    String? content,
    bool? isRead,
    DateTime? readAt,
    DateTime? anyReadAt,
    List<MessageReactionModel>? reactions,
    bool? isEphemeral,
    int? ephemeralDuration,
    DateTime? expiresAt,
    String? replyToId,
    String? replyToContent,
    String? replyToSenderName,
    Map<String, dynamic>? replyToData,
    Map<String, dynamic>? shareData,
    String? mediaViewMode,
    int? currentUserViewCount,
    String? postId,
    String? rippleId,
  }) {
    return Message(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      content: content ?? this.content,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      anyReadAt: anyReadAt ?? this.anyReadAt,
      timestamp: timestamp,
      messageType: messageType,
      mediaUrl: mediaUrl,
      mediaThumbnailUrl: mediaThumbnailUrl,
      mediaFileName: mediaFileName,
      mediaFileSize: mediaFileSize,
      mediaMimeType: mediaMimeType,
      pollData: pollData,
      locationData: locationData,
      shareData: shareData ?? this.shareData,
      voiceDuration: voiceDuration,
      replyToId: replyToId ?? this.replyToId,
      replyToContent: replyToContent ?? this.replyToContent,
      replyToSenderName: replyToSenderName ?? this.replyToSenderName,
      replyToData: replyToData ?? this.replyToData,
      reactions: reactions ?? this.reactions,
      isEphemeral: isEphemeral ?? this.isEphemeral,
      ephemeralDuration: ephemeralDuration ?? this.ephemeralDuration,
      expiresAt: expiresAt ?? this.expiresAt,
      encryptedKeys: encryptedKeys,
      iv: iv,
      signalMessageType: signalMessageType,
      signalSenderContent: signalSenderContent,
      signalSenderMessageType: signalSenderMessageType,
      callId: callId,
      rippleId: rippleId ?? this.rippleId,
      storyId: storyId,
      postId: postId ?? this.postId,
      mediaViewMode: mediaViewMode ?? this.mediaViewMode,
      currentUserViewCount: currentUserViewCount ?? this.currentUserViewCount,
    );
  }

  static String formatBytes(int? bytes) {
    if (bytes == null) return '0 B';
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
