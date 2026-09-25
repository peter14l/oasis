import 'call.dart';

/// Data access for call rows. Every status transition is a *conditional*
/// update (`WHERE status = ...`) so concurrent accept/end/timeout races
/// resolve deterministically: a `null` result means someone else already
/// moved the call out of that state.
abstract class CallRepository {
  String? get currentUserId;

  /// Create a ringing call row. Returns the persisted row.
  Future<Call> createCall({
    required String conversationId,
    required String callerId,
    required String receiverId,
    required CallType type,
    required String roomName,
  });

  Future<Call?> getCall(String callId);

  /// ringing -> active. Returns null if the call is no longer ringing.
  Future<Call?> acceptCall(String callId);

  /// ringing -> declined. Returns null if already answered/ended.
  Future<Call?> declineCall(String callId);

  /// ringing -> missed (used by caller-side timeout / stale guards).
  Future<Call?> markMissed(String callId);

  /// ringing|active -> ended. Returns null if already resolved.
  Future<Call?> endCall(String callId);

  /// Updates to a specific call row (status changes, both directions).
  Stream<Call> watchCall(String callId);

  /// All rows where [userId] is the receiver (client filters ringing).
  Stream<List<Call>> watchCallsFor(String userId);
}
