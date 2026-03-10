import 'package:morrow_v2/models/message_reaction.dart';

enum MessageType { text, image, document, voice, poll, location }

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String content;
  final bool isRead;
  final DateTime? readAt;
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
  final int? voiceDuration; // in seconds

  // Reactions
  final List<MessageReactionModel> reactions;

  // E2E Encryption fields
  final bool isEphemeral;
  final int ephemeralDuration; // in seconds, 0 = immediate, 86400 = 24h
  final DateTime? expiresAt;
  final Map<String, dynamic>? encryptedKeys;
  final String? iv;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.content,
    this.isRead = false,
    this.readAt,
    required this.timestamp,
    this.messageType = MessageType.text,
    this.mediaUrl,
    this.mediaThumbnailUrl,
    this.mediaFileName,
    this.mediaFileSize,
    this.mediaMimeType,
    this.pollData,
    this.locationData,
    this.voiceDuration,
    this.reactions = const [],
    this.isEphemeral = false,
    this.ephemeralDuration = 86400, // Default to 24 hours
    this.expiresAt,
    this.encryptedKeys,
    this.iv,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    // Derive message type from URL fields since message_type column doesn't exist
    MessageType type = MessageType.text;

    if (json['image_url'] != null && json['image_url'].toString().isNotEmpty) {
      type = MessageType.image;
    } else if (json['video_url'] != null &&
        json['video_url'].toString().isNotEmpty) {
      type = MessageType.image; // Treat video as image for now
    } else if (json['file_url'] != null &&
        json['file_url'].toString().isNotEmpty) {
      type = MessageType.document;
    }

    // Consolidate media URLs into single mediaUrl field
    String? mediaUrl;
    if (json['image_url'] != null) {
      mediaUrl = json['image_url'] as String?;
    } else if (json['video_url'] != null) {
      mediaUrl = json['video_url'] as String?;
    } else if (json['file_url'] != null) {
      mediaUrl = json['file_url'] as String?;
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
      voiceDuration: json['voice_duration'] as int?,
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
      'created_at': timestamp.toIso8601String(),
      'message_type': messageType.name,
      'media_url': mediaUrl,
      'media_thumbnail_url': mediaThumbnailUrl,
      'media_file_name': mediaFileName,
      'media_file_size': mediaFileSize,
      'media_mime_type': mediaMimeType,
      'poll_data': pollData,
      'location_data': locationData,
      'voice_duration': voiceDuration,
      'reactions': reactions.map((e) => e.toJson()).toList(),
      'is_ephemeral': isEphemeral,
      'ephemeral_duration': ephemeralDuration,
      'expires_at': expiresAt?.toIso8601String(),
      'encrypted_keys': encryptedKeys,
      'iv': iv,
    };
  }

  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? content,
    bool? isRead,
    DateTime? readAt,
    DateTime? timestamp,
    MessageType? messageType,
    String? mediaUrl,
    String? mediaThumbnailUrl,
    String? mediaFileName,
    int? mediaFileSize,
    String? mediaMimeType,
    Map<String, dynamic>? pollData,
    Map<String, dynamic>? locationData,
    int? voiceDuration,
    List<MessageReactionModel>? reactions,
    bool? isEphemeral,
    int? ephemeralDuration,
    DateTime? expiresAt,
    Map<String, dynamic>? encryptedKeys,
    String? iv,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      content: content ?? this.content,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      timestamp: timestamp ?? this.timestamp,
      messageType: messageType ?? this.messageType,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaThumbnailUrl: mediaThumbnailUrl ?? this.mediaThumbnailUrl,
      mediaFileName: mediaFileName ?? this.mediaFileName,
      mediaFileSize: mediaFileSize ?? this.mediaFileSize,
      mediaMimeType: mediaMimeType ?? this.mediaMimeType,
      pollData: pollData ?? this.pollData,
      locationData: locationData ?? this.locationData,
      voiceDuration: voiceDuration ?? this.voiceDuration,
      reactions: reactions ?? this.reactions,
      isEphemeral: isEphemeral ?? this.isEphemeral,
      ephemeralDuration: ephemeralDuration ?? this.ephemeralDuration,
      expiresAt: expiresAt ?? this.expiresAt,
      encryptedKeys: encryptedKeys ?? this.encryptedKeys,
      iv: iv ?? this.iv,
    );
  }

  // Helper methods
  bool get isMediaMessage => messageType != MessageType.text;

  bool get isImageMessage => messageType == MessageType.image;

  bool get isDocumentMessage => messageType == MessageType.document;

  bool get isVoiceMessage => messageType == MessageType.voice;

  bool get isPollMessage => messageType == MessageType.poll;

  bool get isLocationMessage => messageType == MessageType.location;

  String getFileSizeString() {
    if (mediaFileSize == null) return '';

    final bytes = mediaFileSize!;
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
