import 'package:oasis/core/result/result.dart';
import 'package:oasis/features/messages/domain/models/message_entity.dart';
import 'package:oasis/features/messages/domain/repositories/message_repository.dart';

/// Use case for getting messages in a conversation
class GetMessages {
  final MessageRepository _repository;

  GetMessages(this._repository);

  Future<Result<List<MessageEntity>>> call({
    required String conversationId,
    int limit = 50,
    String? before,
  }) async {
    try {
      final messages = await _repository.getMessages(
        conversationId: conversationId,
        limit: limit,
        before: before,
      );
      return Result.success(messages);
    } catch (e) {
      return Result.failure(message: e.toString());
    }
  }
}

/// Use case for sending a message
class SendMessage {
  final MessageRepository _repository;

  SendMessage(this._repository);

  Future<Result<MessageEntity>> call({
    required String conversationId,
    required String senderId,
    required String content,
    MessageTypeEntity type = MessageTypeEntity.text,
    String? mediaUrl,
    String? mediaFileName,
    String? replyToId,
    String? rippleId,
    String? storyId,
  }) async {
    try {
      final message = await _repository.sendMessage(
        conversationId: conversationId,
        senderId: senderId,
        content: content,
        type: type,
        mediaUrl: mediaUrl,
        mediaFileName: mediaFileName,
        replyToId: replyToId,
        rippleId: rippleId,
        storyId: storyId,
      );
      return Result.success(message);
    } catch (e) {
      return Result.failure(message: e.toString());
    }
  }
}

/// Use case for deleting a message
class DeleteMessage {
  final MessageRepository _repository;

  DeleteMessage(this._repository);

  Future<Result<void>> call(String messageId) async {
    try {
      await _repository.deleteMessage(messageId);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(message: e.toString());
    }
  }
}

/// Use case for reacting to a message
class ReactToMessage {
  final MessageRepository _repository;

  ReactToMessage(this._repository);

  Future<Result<MessageReactionEntity>> call({
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    try {
      final reaction = await _repository.reactToMessage(
        messageId: messageId,
        userId: userId,
        emoji: emoji,
      );
      return Result.success(reaction);
    } catch (e) {
      return Result.failure(message: e.toString());
    }
  }
}

/// Use case for removing a reaction from a message
class RemoveReaction {
  final MessageRepository _repository;

  RemoveReaction(this._repository);

  Future<Result<void>> call({
    required String messageId,
    required String userId,
  }) async {
    try {
      await _repository.removeReaction(messageId, userId);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(message: e.toString());
    }
  }
}

/// Use case for getting message reactions
class GetReactions {
  final MessageRepository _repository;

  GetReactions(this._repository);

  Future<Result<List<MessageReactionEntity>>> call(String messageId) async {
    try {
      final reactions = await _repository.getReactions(messageId);
      return Result.success(reactions);
    } catch (e) {
      return Result.failure(message: e.toString());
    }
  }
}
