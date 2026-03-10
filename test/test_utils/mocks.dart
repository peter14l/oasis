/// Mock implementations for Morrow app services
///
/// These mocks are used for unit and widget testing without
/// requiring actual Supabase or other external service connections.
library;

import 'package:flutter/foundation.dart';
import 'package:morrow_v2/models/user_model.dart';
import 'package:morrow_v2/models/post.dart';
import 'package:morrow_v2/models/community_model.dart';

/// Mock user for testing
class MockUser {
  static const String testUserId = 'test-user-id-12345';
  static const String testEmail = 'test@example.com';
  static const String testUsername = 'testuser';
  static const String testDisplayName = 'Test User';
  static const String testAvatarUrl = 'https://example.com/avatar.jpg';

  static AppUser get testAppUser => AppUser(
    id: testUserId,
    email: testEmail,
    username: testUsername,
    displayName: testDisplayName,
    photoUrl: testAvatarUrl,
  );
}

/// Mock post for testing
class MockPost {
  static const String testPostId = 'test-post-id-12345';
  static const String testContent = 'This is a test post content';

  static Post get testPost => Post(
    id: testPostId,
    userId: MockUser.testUserId,
    username: MockUser.testUsername,
    userAvatar: MockUser.testAvatarUrl,
    content: testContent,
    timestamp: DateTime(2024, 1, 1, 12, 0),
    likes: 10,
    comments: 5,
  );

  static List<Post> get testPosts => [
    testPost,
    Post(
      id: 'test-post-id-2',
      userId: MockUser.testUserId,
      username: MockUser.testUsername,
      userAvatar: MockUser.testAvatarUrl,
      content: 'Second test post',
      timestamp: DateTime(2024, 1, 2, 12, 0),
      likes: 5,
      comments: 2,
    ),
  ];
}

/// Mock community for testing
class MockCommunity {
  static const String testCommunityId = 'test-community-id-12345';
  static const String testCommunityName = 'Test Community';

  static Community get testCommunity => Community(
    id: testCommunityId,
    name: testCommunityName,
    description: 'A test community for testing purposes',
    imageUrl: 'https://example.com/community.jpg',
    theme: 'Technology',
    isPrivate: false,
    memberCount: 100,
    createdAt: DateTime(2024, 1, 1),
  );
}

/// Mock AuthService for testing (simplified version)
/// For full mock, use mockito with @GenerateMocks annotation
class MockAuthServiceSimple extends ChangeNotifier {
  AppUser? _currentUser;
  bool _isLoading = false;
  String? _error;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  void setUser(AppUser? user) {
    _currentUser = user;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  Future<void> signOut() async {
    _currentUser = null;
    notifyListeners();
  }
}

/// Mock for testing Supabase responses
class MockSupabaseResponse<T> {
  final T? data;
  final String? error;
  final int statusCode;

  MockSupabaseResponse({this.data, this.error, this.statusCode = 200});

  bool get hasError => error != null;
  bool get isSuccess => !hasError && statusCode >= 200 && statusCode < 300;
}
