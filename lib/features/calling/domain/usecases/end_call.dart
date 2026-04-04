import '../models/call_entity.dart';
import '../repositories/call_repository.dart';

/// Use case for ending an active call
class EndCall {
  final CallRepository _repository;

  EndCall(this._repository);

  /// End an active call
  Future<CallEntity> call(String callId) {
    return _repository.endCall(callId);
  }

  /// Decline an incoming call
  Future<void> decline(String callId, String userId) {
    return _repository.declineCall(callId, userId);
  }
}
