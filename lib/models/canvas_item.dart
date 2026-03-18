enum CanvasItemType { text, photo, voice, sticker, milestone }

class CanvasItem {
  final String id;
  final String canvasId;
  final String authorId;
  final CanvasItemType type;
  final String content; // raw text, storage URL for photo/voice, emoji for sticker
  final double xPos; // 0.0–1.0 relative to canvas width
  final double yPos; // 0.0–1.0 relative to canvas height
  final double rotation; // degrees
  final double scale;
  final String color; // hex background tint for the sticky-note feel
  final DateTime createdAt;
  final DateTime? unlockAt; // New: For Time Capsule
  final String? groupId; 
  final Map<String, dynamic> metadata; 

  CanvasItem({
    required this.id,
    required this.canvasId,
    required this.authorId,
    required this.type,
    required this.content,
    required this.xPos,
    required this.yPos,
    this.rotation = 0.0,
    this.scale = 1.0,
    this.color = '#252930',
    required this.createdAt,
    this.unlockAt,
    this.groupId,
    this.metadata = const {},
  });

  factory CanvasItem.fromJson(Map<String, dynamic> json) {
    return CanvasItem(
      id: json['id'] as String,
      canvasId: json['canvas_id'] as String,
      authorId: json['author_id'] as String,
      type: CanvasItemType.values.firstWhere(
        (e) => e.name == (json['type'] as String? ?? 'text'),
        orElse: () => CanvasItemType.text,
      ),
      content: json['content'] as String? ?? '',
      xPos: (json['x_pos'] as num?)?.toDouble() ?? 0.1,
      yPos: (json['y_pos'] as num?)?.toDouble() ?? 0.1,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      color: json['color'] as String? ?? '#252930',
      createdAt: DateTime.parse(json['created_at'] as String),
      unlockAt: json['unlock_at'] != null ? DateTime.parse(json['unlock_at'] as String) : null,
      groupId: json['group_id'] as String?,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'canvas_id': canvasId,
      'author_id': authorId,
      'type': type.name,
      'content': content,
      'x_pos': xPos,
      'y_pos': yPos,
      'rotation': rotation,
      'scale': scale,
      'color': color,
      'created_at': createdAt.toIso8601String(),
      'unlock_at': unlockAt?.toIso8601String(),
      'group_id': groupId,
      'metadata': metadata,
    };
  }

  CanvasItem copyWith({
    String? id,
    String? canvasId,
    String? authorId,
    CanvasItemType? type,
    String? content,
    double? xPos,
    double? yPos,
    double? rotation,
    double? scale,
    String? color,
    DateTime? createdAt,
    DateTime? unlockAt,
    String? groupId,
    Map<String, dynamic>? metadata,
  }) {
    return CanvasItem(
      id: id ?? this.id,
      canvasId: canvasId ?? this.canvasId,
      authorId: authorId ?? this.authorId,
      type: type ?? this.type,
      content: content ?? this.content,
      xPos: xPos ?? this.xPos,
      yPos: yPos ?? this.yPos,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      unlockAt: unlockAt ?? this.unlockAt,
      groupId: groupId ?? this.groupId,
      metadata: metadata ?? this.metadata,
    );
  }
}
