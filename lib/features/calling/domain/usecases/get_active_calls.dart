import '../models/call_entity.dart';
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

  /// Watch call updates in real-time
  Stream<CallEntity> watchCall(String callId) {
    return _repository.watchCall(callId);
  }
}
