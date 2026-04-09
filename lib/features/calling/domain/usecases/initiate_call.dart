import '../models/call_entity.dart';
import '../repositories/call_repository.dart';

/// Use case for initiating a new call
class InitiateCall {
  final CallRepository _repository;

  InitiateCall(this._repository);

  /// Initiate a voice or video call
  Future<CallEntity> call({
    required String conversationId,
    required String hostId,
    required CallType type,
    required List<String> participantIds,
  }) {
    return _repository.createCall(
      conversationId: conversationId,
      hostId: hostId,
      type: type,
      participantIds: participantIds,
    );
  }

  /// Get Agora token for joining a call
  Future<String> getToken(String callId, String userId) {
    return _repository.getCallToken(callId, userId);
  }
}
