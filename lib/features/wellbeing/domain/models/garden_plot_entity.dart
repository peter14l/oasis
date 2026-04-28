class GardenPlotEntity {
  final String id;
  final String userId;
  final String seedText;
  final int stage;
  final double xPos;
  final double yPos;
  final DateTime plantedAt;
  final DateTime lastTendedAt;

  const GardenPlotEntity({
    required this.id,
    required this.userId,
    required this.seedText,
    required this.stage,
    required this.xPos,
    required this.yPos,
    required this.plantedAt,
    required this.lastTendedAt,
  });

  factory GardenPlotEntity.fromJson(Map<String, dynamic> json) {
    return GardenPlotEntity(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      seedText: json['seed_text'] as String,
      stage: json['stage'] as int,
      xPos: (json['x_pos'] as num).toDouble(),
      yPos: (json['y_pos'] as num).toDouble(),
      plantedAt: DateTime.parse(json['planted_at'] as String),
      lastTendedAt: DateTime.parse(json['last_tended_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'seed_text': seedText,
      'stage': stage,
      'x_pos': xPos,
      'y_pos': yPos,
      'planted_at': plantedAt.toIso8601String(),
      'last_tended_at': lastTendedAt.toIso8601String(),
    };
  }

  GardenPlotEntity copyWith({
    String? id,
    String? userId,
    String? seedText,
    int? stage,
    double? xPos,
    double? yPos,
    DateTime? plantedAt,
    DateTime? lastTendedAt,
  }) {
    return GardenPlotEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      seedText: seedText ?? this.seedText,
      stage: stage ?? this.stage,
      xPos: xPos ?? this.xPos,
      yPos: yPos ?? this.yPos,
      plantedAt: plantedAt ?? this.plantedAt,
      lastTendedAt: lastTendedAt ?? this.lastTendedAt,
    );
  }
}
