import '../models/call_entity.dart';
import '../models/call_participant_entity.dart';

/// Abstract repository interface for call operations
abstract class CallRepository {
  /// Create a new call
  Future<CallEntity> createCall({
    required String conversationId,
    required String hostId,
    required CallType type,
  });

  /// Get call by ID
  Future<CallEntity?> getCall(String callId);

  /// Get active calls for user
  Future<List<CallEntity>> getActiveCalls(String userId);

  /// Accept incoming call
  Future<CallEntity> acceptCall(String callId, String userId);

  /// Decline incoming call
  Future<void> declineCall(String callId, String userId);

  /// End a call
  Future<CallEntity> endCall(String callId);

  /// Get call participants
  Future<List<CallParticipantEntity>> getCallParticipants(String callId);

  /// Add participant to call
  Future<CallParticipantEntity> addParticipant({
    required String callId,
    required String userId,
  });

  /// Update participant status
  Future<CallParticipantEntity> updateParticipant({
    required String participantId,
    bool? isMuted,
    bool? isVideoOn,
    bool? isScreenSharing,
    String? status,
  });

  /// Get call token for Agora
  Future<String> getCallToken(String callId, String userId);

  /// Stream of call updates
  Stream<CallEntity> watchCall(String callId);

  /// Stream of call participants
  Stream<List<CallParticipantEntity>> watchParticipants(String callId);
}
