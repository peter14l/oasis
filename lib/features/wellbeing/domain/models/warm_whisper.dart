import 'package:oasis/features/profile/domain/models/user_profile_entity.dart';

class WarmWhisper {
  final String id;
  final String senderId;
  final String recipientId;
  final String? message;
  final bool isAnonymous;
  final DateTime? revealedAt;
  final DateTime createdAt;
  final UserProfileEntity? senderProfile;

  WarmWhisper({
    required this.id,
    required this.senderId,
    required this.recipientId,
    this.message,
    this.isAnonymous = false,
    this.revealedAt,
    required this.createdAt,
    this.senderProfile,
  });

  factory WarmWhisper.fromJson(Map<String, dynamic> json) {
    return WarmWhisper(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      recipientId: json['recipient_id'] as String,
      message: json['message'] as String?,
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      revealedAt: json['revealed_at'] != null 
          ? DateTime.parse(json['revealed_at'] as String) 
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      senderProfile: json['profiles'] != null 
          ? UserProfileEntity.fromJson(json['profiles'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'recipient_id': recipientId,
      'message': message,
      'is_anonymous': isAnonymous,
      'revealed_at': revealedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  WarmWhisper copyWith({
    String? id,
    String? senderId,
    String? recipientId,
    String? message,
    bool? isAnonymous,
    DateTime? revealedAt,
    DateTime? createdAt,
    UserProfileEntity? senderProfile,
  }) {
    return WarmWhisper(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      recipientId: recipientId ?? this.recipientId,
      message: message ?? this.message,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      revealedAt: revealedAt ?? this.revealedAt,
      createdAt: createdAt ?? this.createdAt,
      senderProfile: senderProfile ?? this.senderProfile,
    );
  }

  bool get isRevealed => revealedAt != null;
}
