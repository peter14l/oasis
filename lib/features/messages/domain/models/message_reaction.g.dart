// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_reaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MessageReactionModel _$MessageReactionModelFromJson(
  Map<String, dynamic> json,
) => _MessageReactionModel(
  id: json['id'] as String? ?? '',
  messageId: json['message_id'] as String? ?? '',
  userId: json['user_id'] as String? ?? '',
  username: json['username'] as String? ?? 'Unknown',
  reaction: _readReaction(json, 'reaction') as String,
  createdAt: _dateTimeFromJson(json['created_at']),
);

Map<String, dynamic> _$MessageReactionModelToJson(
  _MessageReactionModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'message_id': instance.messageId,
  'user_id': instance.userId,
  'username': instance.username,
  'reaction': instance.reaction,
  'created_at': instance.createdAt.toIso8601String(),
};
