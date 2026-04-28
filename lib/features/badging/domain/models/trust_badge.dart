/// Trust badge type (badge definition)
class TrustBadge {
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final Map<String, dynamic> criteria;
  final DateTime? createdAt;

  const TrustBadge({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    required this.criteria,
    this.createdAt,
  });

  factory TrustBadge.fromJson(Map<String, dynamic> json) {
    return TrustBadge(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      criteria: Map<String, dynamic>.from(json['criteria'] ?? {}),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'criteria': criteria,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

/// User badge (earned badge instance)
class UserBadge {
  final String id;
  final String userId;
  final String badgeId;
  final DateTime? earnedAt;

  const UserBadge({
    required this.id,
    required this.userId,
    required this.badgeId,
    this.earnedAt,
  });

  factory UserBadge.fromJson(Map<String, dynamic> json) {
    return UserBadge(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      badgeId: json['badge_id'] as String,
      earnedAt: json['earned_at'] != null
          ? DateTime.parse(json['earned_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'badge_id': badgeId,
      'earned_at': earnedAt?.toIso8601String(),
    };
  }
}