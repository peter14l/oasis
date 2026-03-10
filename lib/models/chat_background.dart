enum BackgroundType {
  custom,
  preset,
  color,
}

class ChatBackground {
  final String id;
  final String conversationId;
  final String userId;
  final BackgroundType type;
  final String? backgroundUrl;
  final String? backgroundColor;
  final DateTime createdAt;

  ChatBackground({
    required this.id,
    required this.conversationId,
    required this.userId,
    required this.type,
    this.backgroundUrl,
    this.backgroundColor,
    required this.createdAt,
  });

  factory ChatBackground.fromJson(Map<String, dynamic> json) {
    // Parse background type
    BackgroundType type = BackgroundType.preset;
    final typeStr = json['background_type'] as String?;
    if (typeStr != null) {
      type = BackgroundType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => BackgroundType.preset,
      );
    }

    return ChatBackground(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      userId: json['user_id'] as String,
      type: type,
      backgroundUrl: json['background_url'] as String?,
      backgroundColor: json['background_color'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'user_id': userId,
      'background_type': type.name,
      'background_url': backgroundUrl,
      'background_color': backgroundColor,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ChatBackground copyWith({
    String? id,
    String? conversationId,
    String? userId,
    BackgroundType? type,
    String? backgroundUrl,
    String? backgroundColor,
    DateTime? createdAt,
  }) {
    return ChatBackground(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      backgroundUrl: backgroundUrl ?? this.backgroundUrl,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

