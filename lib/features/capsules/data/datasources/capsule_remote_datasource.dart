import 'package:oasis_v2/features/capsules/domain/models/time_capsule_entity.dart';

/// Remote datasource for Time Capsule operations via Supabase
class CapsuleRemoteDatasource {
  /// Get all capsules for a user
  Future<List<TimeCapsuleEntity>> getCapsules({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    throw UnimplementedError(
      'TODO: Implement using existing TimeCapsuleService logic',
    );
  }

  /// Get a single capsule by ID
  Future<TimeCapsuleEntity?> getCapsuleById(String capsuleId) async {
    throw UnimplementedError(
      'TODO: Implement using existing TimeCapsuleService logic',
    );
  }

  /// Create a new time capsule
  Future<TimeCapsuleEntity> createCapsule({
    required String userId,
    required String content,
    required DateTime unlockDate,
    String? mediaUrl,
    String mediaType = 'none',
  }) async {
    throw UnimplementedError(
      'TODO: Implement using existing TimeCapsuleService logic',
    );
  }

  /// Open/unlock a capsule
  Future<TimeCapsuleEntity> openCapsule(String capsuleId) async {
    throw UnimplementedError(
      'TODO: Implement using existing TimeCapsuleService logic',
    );
  }

  /// Contribute to an existing capsule
  Future<TimeCapsuleEntity> contributeToCapsule({
    required String capsuleId,
    required String content,
    String? mediaUrl,
    String mediaType = 'none',
  }) async {
    throw UnimplementedError(
      'TODO: Implement using existing TimeCapsuleService logic',
    );
  }

  /// Delete a capsule
  Future<void> deleteCapsule(String capsuleId) async {
    throw UnimplementedError(
      'TODO: Implement using existing TimeCapsuleService logic',
    );
  }
}
