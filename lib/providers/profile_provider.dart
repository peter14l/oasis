import 'package:universal_io/io.dart';
import 'package:flutter/foundation.dart';
import 'package:oasis_v2/models/user_profile.dart';
import 'package:oasis_v2/models/post.dart';
import 'package:oasis_v2/services/profile_service.dart';
import 'package:oasis_v2/services/feed_service.dart';
import 'package:oasis_v2/services/messaging_service.dart';

class ProfileProvider with ChangeNotifier {
  final ProfileService _profileService = ProfileService();
  final FeedService _feedService = FeedService();
  final MessagingService _messagingService = MessagingService();

  UserProfile? _currentProfile;
  UserProfile? _viewedProfile;
  List<UserProfile> _followers = [];
  List<UserProfile> _following = [];
  bool _isLoading = false;
  bool _isFollowing = false;
  String? _error;

  // Getters
  UserProfile? get currentProfile => _currentProfile;
  UserProfile? get viewedProfile => _viewedProfile;
  List<UserProfile> get followers => _followers;
  List<UserProfile> get following => _following;
  bool get isLoading => _isLoading;
  bool get isLoadingFollowing => _isLoading; // Map to _isLoading or separate flag if available
  bool get isFollowing => _isFollowing;
  String? get error => _error;

  /// Load current user's profile
  Future<void> loadCurrentProfile(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentProfile = await _profileService.getProfile(userId);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading current profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load another user's profile
  Future<void> loadProfile(String userId, String currentUserId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _viewedProfile = await _profileService.getProfile(userId);

      // Check if current user is following this profile
      if (userId != currentUserId) {
        _isFollowing = await _profileService.isFollowing(
          followerId: currentUserId,
          followingId: userId,
        );
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update current user's profile
  Future<void> updateProfile({
    required String userId,
    String? username,
    String? fullName,
    String? bio,
    String? location,
    String? website,
    String? bannerColor,
    File? avatarFile,
    File? bannerFile,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentProfile = await _profileService.updateProfile(
        userId: userId,
        username: username,
        fullName: fullName,
        bio: bio,
        location: location,
        website: website,
        bannerColor: bannerColor,
        avatarFile: avatarFile,
        bannerFile: bannerFile,
      );
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating profile: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Follow a user
  Future<void> followUser({
    required String followerId,
    required String followingId,
  }) async {
    try {
      // Optimistic update
      _isFollowing = true;
      if (_viewedProfile != null) {
        _viewedProfile = _viewedProfile!.copyWith(
          followersCount: _viewedProfile!.followersCount + 1,
        );
      }
      // Optimistic addition to following list for feed UI
      if (!_following.any((p) => p.id == followingId)) {
        _following.add(UserProfile(
          id: followingId,
          username: '',
          email: '',
          createdAt: DateTime.now(),
        ));
      }
      notifyListeners();

      await _profileService.followUser(
        followerId: followerId,
        followingId: followingId,
      );
    } catch (e) {
      // Revert on error
      _isFollowing = false;
      if (_viewedProfile != null) {
        _viewedProfile = _viewedProfile!.copyWith(
          followersCount: _viewedProfile!.followersCount - 1,
        );
      }
      notifyListeners();
      debugPrint('Error following user: $e');
      rethrow;
    }
  }

  /// Unfollow a user
  Future<void> unfollowUser({
    required String followerId,
    required String followingId,
  }) async {
    try {
      // Optimistic update
      _isFollowing = false;
      if (_viewedProfile != null) {
        _viewedProfile = _viewedProfile!.copyWith(
          followersCount: _viewedProfile!.followersCount - 1,
        );
      }
      // Optimistic removal
      _following.removeWhere((p) => p.id == followingId);
      notifyListeners();

      await _profileService.unfollowUser(
        followerId: followerId,
        followingId: followingId,
      );
    } catch (e) {
      // Revert on error
      _isFollowing = true;
      if (_viewedProfile != null) {
        _viewedProfile = _viewedProfile!.copyWith(
          followersCount: _viewedProfile!.followersCount + 1,
        );
      }
      notifyListeners();
      debugPrint('Error unfollowing user: $e');
      rethrow;
    }
  }

  /// Load followers
  Future<void> loadFollowers(String userId) async {
    try {
      _followers = await _profileService.getFollowers(userId: userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading followers: $e');
      rethrow;
    }
  }

  /// Load following
  Future<void> loadFollowing(String userId) async {
    try {
      _following = await _profileService.getFollowing(userId: userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading following: $e');
      rethrow;
    }
  }

  /// Search users
  Future<List<UserProfile>> searchUsers(String query) async {
    try {
      return await _profileService.searchUsers(query: query);
    } catch (e) {
      debugPrint('Error searching users: $e');
      rethrow;
    }
  }

  /// Load Saved Posts
  Future<List<Post>> loadSavedPosts(String userId) async {
    try {
      return await _feedService.getBookmarkedPosts(userId: userId);
    } catch (e) {
      debugPrint('Error fetching saved posts: $e');
      return [];
    }
  }

  /// Update privacy settings
  Future<void> updatePrivacy({
    required String userId,
    required bool isPrivate,
  }) async {
    try {
      await _profileService.updatePrivacy(userId: userId, isPrivate: isPrivate);

      if (_currentProfile != null) {
        _currentProfile = _currentProfile!.copyWith(isPrivate: isPrivate);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating privacy: $e');
      rethrow;
    }
  }

  /// Clear viewed profile
  void clearViewedProfile() {
    _viewedProfile = null;
    _isFollowing = false;
    notifyListeners();
  }

  /// Get or create a direct conversation
  Future<String> getOrCreateConversation({
    required String user1Id,
    required String user2Id,
  }) async {
    try {
      return await _messagingService.getOrCreateConversation(
        user1Id: user1Id,
        user2Id: user2Id,
      );
    } catch (e) {
      _error = e.toString();
      debugPrint('Error getting/creating conversation: $e');
      rethrow;
    }
  }

  /// Clear all data
  void clear() {
    _currentProfile = null;
    _viewedProfile = null;
    _followers = [];
    _following = [];
    _isLoading = false;
    _isFollowing = false;
    _error = null;
    notifyListeners();
  }
}
