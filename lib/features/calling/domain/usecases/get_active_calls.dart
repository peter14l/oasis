import '../models/call_entity.dart';
import '../models/call_participant_entity.dart';
import '../repositories/call_repository.dart';

/// Use case for getting active calls
class GetActiveCalls {
  final CallRepository _repository;

  GetActiveCalls(this._repository);

  /// Get all active calls for a user
  Future<List<CallEntity>> calls(String userId) {
    return _repository.getActiveCalls(userId);
  }

  /// Get a specific call by ID
  Future<CallEntity?> call(String callId) {
    return _repository.getCall(callId);
  }

  /// Get participants for a call
  Future<List<CallParticipantEntity>> participants(String callId) {
    return _repository.getCallParticipants(callId);
  }

  /// Watch call updates in real-time
  Stream<CallEntity> watchCall(String callId) {
    return _repository.watchCall(callId);
  }

  /// Watch participants in real-time
  Stream<List<CallParticipantEntity>> watchParticipants(String callId) {
    return _repository.watchParticipants(callId);
  }
}
