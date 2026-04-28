import 'package:oasis/features/profile/domain/models/user_profile_entity.dart';

abstract class ProfileRepository {
  Future<UserProfileEntity> getProfile(String userId);

  Future<UserProfileEntity> getProfileByUsername(String username);

  Future<UserProfileEntity> updateProfile({
    required String userId,
    String? username,
    String? fullName,
    String? bio,
    String? location,
    String? website,
    String? bannerColor,
    String? avatarFilePath,
    String? bannerFilePath,
  });

  Future<void> followUser({
    required String followerId,
    required String followingId,
  });

  Future<void> sendFollowRequest({
    required String followerId,
    required String followingId,
  });

  Future<void> acceptFollowRequest({
    required String followerId,
    required String followingId,
  });

  Future<void> declineFollowRequest({
    required String followerId,
    required String followingId,
  });

  Future<bool> hasSentFollowRequest({
    required String followerId,
    required String followingId,
  });

  Future<void> unfollowUser({
    required String followerId,
    required String followingId,
  });

  Future<bool> isFollowing({
    required String followerId,
    required String followingId,
  });

  Future<List<UserProfileEntity>> getFollowers({
    required String userId,
    int limit = 50,
    int offset = 0,
  });

  Future<List<UserProfileEntity>> getFollowing({
    required String userId,
    int limit = 50,
    int offset = 0,
  });

  Future<List<UserProfileEntity>> searchUsers({
    required String query,
    int limit = 20,
  });

  Future<void> updatePrivacy({required String userId, required bool isPrivate});

  Future<void> setCozyMode({
    required String userId,
    String? status,
    String? statusText,
    DateTime? until,
  });

  Future<void> clearCozyMode(String userId);

  Future<void> setPulseStatus({
    required String userId,
    required String status,
    String? text,
  });

  Future<void> clearPulseStatus(String userId);

  Future<void> togglePulseVisibility({
    required String userId,
    required bool visible,
  });
}
