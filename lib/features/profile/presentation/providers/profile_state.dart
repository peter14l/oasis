import 'package:oasis/features/profile/domain/models/user_profile_entity.dart';

class ProfileState {
  final UserProfileEntity? currentProfile;
  final UserProfileEntity? viewedProfile;
  final List<UserProfileEntity> followers;
  final List<UserProfileEntity> following;
  final bool isLoading;
  final bool isFollowing;
  final bool hasSentRequest;
  final String? error;

  const ProfileState({
    this.currentProfile,
    this.viewedProfile,
    this.followers = const [],
    this.following = const [],
    this.isLoading = false,
    this.isFollowing = false,
    this.hasSentRequest = false,
    this.error,
  });

  ProfileState copyWith({
    UserProfileEntity? currentProfile,
    UserProfileEntity? viewedProfile,
    List<UserProfileEntity>? followers,
    List<UserProfileEntity>? following,
    bool? isLoading,
    bool? isFollowing,
    bool? hasSentRequest,
    String? error,
  }) {
    return ProfileState(
      currentProfile: currentProfile ?? this.currentProfile,
      viewedProfile: viewedProfile ?? this.viewedProfile,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      isLoading: isLoading ?? this.isLoading,
      isFollowing: isFollowing ?? this.isFollowing,
      hasSentRequest: hasSentRequest ?? this.hasSentRequest,
      error: error,
    );
  }
}
