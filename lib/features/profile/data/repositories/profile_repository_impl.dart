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
}
