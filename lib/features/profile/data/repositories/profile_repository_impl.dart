import 'package:oasis/features/profile/domain/models/user_profile_entity.dart';
import 'package:oasis/features/profile/domain/repositories/profile_repository.dart';
import 'package:oasis/features/profile/data/datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDatasource _remoteDatasource;

  ProfileRepositoryImpl({ProfileRemoteDatasource? remoteDatasource})
    : _remoteDatasource = remoteDatasource ?? ProfileRemoteDatasource();

  @override
  Future<UserProfileEntity> getProfile(String userId) async {
    final profileMap = await _remoteDatasource.getProfile(userId);
    return UserProfileEntity.fromJson(profileMap);
  }

  @override
  Future<UserProfileEntity> getProfileByUsername(String username) async {
    final profileMap = await _remoteDatasource.getProfileByUsername(username);
    return UserProfileEntity.fromJson(profileMap);
  }

  @override
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
  }) async {
    final profileMap = await _remoteDatasource.updateProfile(
      userId: userId,
      username: username,
      fullName: fullName,
      bio: bio,
      location: location,
      website: website,
      bannerColor: bannerColor,
      avatarFilePath: avatarFilePath,
      bannerFilePath: bannerFilePath,
    );
    return UserProfileEntity.fromJson(profileMap);
  }

  @override
  Future<void> followUser({
    required String followerId,
    required String followingId,
  }) async {
    await _remoteDatasource.followUser(
      followerId: followerId,
      followingId: followingId,
    );
  }

  @override
  Future<void> sendFollowRequest({
    required String followerId,
    required String followingId,
  }) async {
    await _remoteDatasource.sendFollowRequest(
      followerId: followerId,
      followingId: followingId,
    );
  }

  @override
  Future<void> acceptFollowRequest({
    required String followerId,
    required String followingId,
  }) async {
    await _remoteDatasource.acceptFollowRequest(
      followerId: followerId,
      followingId: followingId,
    );
  }

  @override
  Future<void> declineFollowRequest({
    required String followerId,
    required String followingId,
  }) async {
    await _remoteDatasource.declineFollowRequest(
      followerId: followerId,
      followingId: followingId,
    );
  }

  @override
  Future<bool> hasSentFollowRequest({
    required String followerId,
    required String followingId,
  }) async {
    return _remoteDatasource.hasSentFollowRequest(
      followerId: followerId,
      followingId: followingId,
    );
  }

  @override
  Future<void> unfollowUser({
    required String followerId,
    required String followingId,
  }) async {
    await _remoteDatasource.unfollowUser(
      followerId: followerId,
      followingId: followingId,
    );
  }

  @override
  Future<bool> isFollowing({
    required String followerId,
    required String followingId,
  }) async {
    return _remoteDatasource.isFollowing(
      followerId: followerId,
      followingId: followingId,
    );
  }

  @override
  Future<List<UserProfileEntity>> getFollowers({
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    final rawProfiles = await _remoteDatasource.getFollowers(
      userId: userId,
      limit: limit,
      offset: offset,
    );
    return rawProfiles.map((json) => UserProfileEntity.fromJson(json)).toList();
  }

  @override
  Future<List<UserProfileEntity>> getFollowing({
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    final rawProfiles = await _remoteDatasource.getFollowing(
      userId: userId,
      limit: limit,
      offset: offset,
    );
    return rawProfiles.map((json) => UserProfileEntity.fromJson(json)).toList();
  }

  @override
  Future<List<UserProfileEntity>> searchUsers({
    required String query,
    int limit = 20,
  }) async {
    final rawProfiles = await _remoteDatasource.searchUsers(
      query: query,
      limit: limit,
    );
    return rawProfiles.map((json) => UserProfileEntity.fromJson(json)).toList();
  }

  @override
  Future<void> updatePrivacy({
    required String userId,
    required bool isPrivate,
  }) async {
    await _remoteDatasource.updatePrivacy(userId: userId, isPrivate: isPrivate);
  }

  @override
  Future<void> setCozyMode({
    required String userId,
    String? status,
    String? statusText,
    DateTime? until,
  }) async {
    await _remoteDatasource.setCozyMode(
      userId: userId,
      status: status,
      statusText: statusText,
      until: until,
    );
  }

  @override
  Future<void> setMood({
    required String userId,
    String? mood,
    String? emoji,
  }) async {
    await _remoteDatasource.setMood(
      userId: userId,
      mood: mood,
      emoji: emoji,
    );
  }

  @override
  Future<void> setFortressMode({
    required String userId,
    required bool enabled,
    String? message,
  }) async {
    await _remoteDatasource.setFortressMode(
      userId: userId,
      enabled: enabled,
      message: message,
    );
  }

  @override
  Future<void> clearCozyMode(String userId) async {
    await _remoteDatasource.clearCozyMode(userId);
  }

  @override
  Future<void> setPulseStatus({
    required String userId,
    required String status,
    String? text,
  }) async {
    await _remoteDatasource.setPulseStatus(
      userId: userId,
      status: status,
      text: text,
    );
  }

  @override
  Future<void> clearPulseStatus(String userId) async {
    await _remoteDatasource.clearPulseStatus(userId);
  }

  @override
  Future<void> togglePulseVisibility({
    required String userId,
    required bool visible,
  }) async {
    await _remoteDatasource.togglePulseVisibility(
      userId: userId,
      visible: visible,
    );
  }
}
