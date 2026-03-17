class Conversation {
  final String id;
  final String otherUserId;
  final String otherUserName;
  final String otherUserAvatar;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final DateTime? lastMessageReadAt;
  final String? lastMessageSenderId;
  final int unreadCount;
  final String? lastMessageType; // 'text', 'image', 'document', etc.
  final bool isOtherUserTyping;
  final bool isWhisperMode;

  Conversation({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserAvatar,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageReadAt,
    this.lastMessageSenderId,
    this.unreadCount = 0,
    this.lastMessageType,
    this.isOtherUserTyping = false,
    this.isWhisperMode = false,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      otherUserId: json['other_user_id'] as String? ?? '',
      otherUserName: json['other_user_name'] as String? ?? json['other_user_username'] as String? ?? '',
      otherUserAvatar: json['other_user_avatar'] as String? ?? json['other_user_avatar_url'] as String? ?? '',
      lastMessage: json['last_message'] as String?,
      lastMessageTime:
          json['last_message_time'] != null
              ? DateTime.parse(json['last_message_time'] as String)
              : null,
      lastMessageReadAt:
          json['last_message_read_at'] != null
              ? DateTime.parse(json['last_message_read_at'] as String)
              : null,
      lastMessageSenderId: json['last_message_sender_id'] as String?,
      unreadCount: json['unread_count'] as int? ?? 0,
      lastMessageType: json['last_message_type'] as String?,
      isOtherUserTyping: json['is_other_user_typing'] as bool? ?? false,
      isWhisperMode: json['is_whisper_mode'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'other_user_id': otherUserId,
      'other_user_name': otherUserName,
      'other_user_avatar': otherUserAvatar,
      'last_message': lastMessage,
      'last_message_time': lastMessageTime?.toIso8601String(),
      'last_message_read_at': lastMessageReadAt?.toIso8601String(),
      'last_message_sender_id': lastMessageSenderId,
      'unread_count': unreadCount,
      'last_message_type': lastMessageType,
      'is_other_user_typing': isOtherUserTyping,
      'is_whisper_mode': isWhisperMode,
    };
  }

  Conversation copyWith({
    String? id,
    String? otherUserId,
    String? otherUserName,
    String? otherUserAvatar,
    String? lastMessage,
    DateTime? lastMessageTime,
    DateTime? lastMessageReadAt,
    String? lastMessageSenderId,
    int? unreadCount,
    String? lastMessageType,
    bool? isOtherUserTyping,
    bool? isWhisperMode,
  }) {
    return Conversation(
      id: id ?? this.id,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserAvatar: otherUserAvatar ?? this.otherUserAvatar,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageReadAt: lastMessageReadAt ?? this.lastMessageReadAt,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      isOtherUserTyping: isOtherUserTyping ?? this.isOtherUserTyping,
      isWhisperMode: isWhisperMode ?? this.isWhisperMode,
    );
  }

  // Helper method to get display text for last message
  String getLastMessageDisplay([String? currentUserId]) {
    if (lastMessage == null || lastMessage!.isEmpty) {
      return '';
    }

    String prefix = '';
    if (currentUserId != null && lastMessageSenderId == currentUserId) {
      prefix = 'You: ';
    }

    switch (lastMessageType) {
      case 'image':
        return '$prefix📷 Photo';
      case 'document':
        return '$prefix📄 Document';
      case 'voice':
        return '$prefix🎤 Voice message';
      case 'poll':
        return '$prefix📊 Poll';
      case 'location':
        return '$prefix📍 Location';
      default:
        return '$prefix$lastMessage';
    }
  }
}
