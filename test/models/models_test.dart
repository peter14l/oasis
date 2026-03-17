import 'package:flutter_test/flutter_test.dart';
import 'package:oasis_v2/models/post.dart';
import 'package:oasis_v2/models/user_model.dart';
import 'package:oasis_v2/models/community_model.dart';

void main() {
  group('Post Model', () {
    test('should create Post from JSON', () {
      final json = {
        'id': 'test-id',
        'user_id': 'user-123',
        'username': 'testuser',
        'user_avatar': 'https://example.com/avatar.jpg',
        'content': 'Test post content',
        'image_url': null,
        'video_url': null,
        'created_at': '2024-01-01T12:00:00.000Z',
        'likes_count': 10,
        'comments_count': 5,
        'is_liked': false,
        'is_bookmarked': false,
      };

      final post = Post.fromJson(json);

      expect(post.id, equals('test-id'));
      expect(post.userId, equals('user-123'));
      expect(post.username, equals('testuser'));
      expect(post.content, equals('Test post content'));
      expect(post.likes, equals(10));
      expect(post.comments, equals(5));
    });

    test('should handle null content', () {
      final json = {
        'id': 'test-id',
        'user_id': 'user-123',
        'username': 'testuser',
        'user_avatar': '',
        'content': null,
        'created_at': '2024-01-01T12:00:00.000Z',
        'likes_count': 0,
        'comments_count': 0,
      };

      final post = Post.fromJson(json);

      expect(post.content, isNull);
    });

    test('should use default values for missing counts', () {
      final json = {
        'id': 'test-id',
        'user_id': 'user-123',
        'username': 'testuser',
        'user_avatar': '',
        'content': 'Test',
        'created_at': '2024-01-01T12:00:00.000Z',
      };

      final post = Post.fromJson(json);

      expect(post.likes, equals(0));
      expect(post.comments, equals(0));
    });
  });

  group('AppUser Model', () {
    test('should create AppUser from JSON', () {
      final json = {
        'id': 'user-123',
        'email': 'test@example.com',
        'username': 'testuser',
        'displayName': 'Test User',
        'photoUrl': 'https://example.com/avatar.jpg',
      };

      final user = AppUser.fromJson(json);

      expect(user.id, equals('user-123'));
      expect(user.email, equals('test@example.com'));
      expect(user.username, equals('testuser'));
      expect(user.displayName, equals('Test User'));
    });

    test('should handle null display name', () {
      final json = {
        'id': 'user-123',
        'email': 'test@example.com',
        'username': 'testuser',
        'displayName': null,
        'photoUrl': null,
      };

      final user = AppUser.fromJson(json);

      expect(user.displayName, isNull);
      expect(user.photoUrl, isNull);
    });

    test('should convert AppUser to JSON', () {
      final user = AppUser(
        id: 'user-123',
        email: 'test@example.com',
        username: 'testuser',
        displayName: 'Test User',
        photoUrl: 'https://example.com/avatar.jpg',
      );

      final json = user.toJson();

      expect(json['id'], equals('user-123'));
      expect(json['email'], equals('test@example.com'));
      expect(json['username'], equals('testuser'));
    });

    test('should provide displayNameOrUsername getter', () {
      final userWithDisplayName = AppUser(
        id: 'user-123',
        email: 'test@example.com',
        username: 'testuser',
        displayName: 'Test User',
      );

      final userWithoutDisplayName = AppUser(
        id: 'user-456',
        email: 'test2@example.com',
        username: 'another_user',
      );

      expect(userWithDisplayName.displayNameOrUsername, equals('Test User'));
      expect(
        userWithoutDisplayName.displayNameOrUsername,
        equals('another_user'),
      );
    });
  });

  group('Community Model', () {
    test('should create Community from map', () {
      final map = {
        'name': 'Test Community',
        'description': 'A test community',
        'imageUrl': 'https://example.com/community.jpg',
        'theme': 'Technology',
        'isPrivate': false,
        'memberCount': 100,
        'created_at': '2024-01-01T12:00:00.000Z',
      };

      final community = Community.fromMap('community-123', map);

      expect(community.id, equals('community-123'));
      expect(community.name, equals('Test Community'));
      expect(community.description, equals('A test community'));
      expect(community.isPrivate, equals(false));
      expect(community.memberCount, equals(100));
    });

    test('should handle private community', () {
      final map = {
        'name': 'Private Community',
        'description': 'A private community',
        'theme': 'General',
        'isPrivate': true,
        'memberCount': 10,
        'created_at': '2024-01-01T12:00:00.000Z',
      };

      final community = Community.fromMap('community-123', map);

      expect(community.isPrivate, equals(true));
    });

    test('should use default count when missing', () {
      final map = {
        'name': 'Test Community',
        'description': 'A test community',
        'theme': 'General',
        'created_at': '2024-01-01T12:00:00.000Z',
      };

      final community = Community.fromMap('community-123', map);

      expect(community.memberCount, equals(0));
    });

    test('should convert to map', () {
      final community = Community(
        id: 'community-123',
        name: 'Test Community',
        description: 'A test community',
        theme: 'Technology',
        createdAt: DateTime(2024, 1, 1),
      );

      final map = community.toMap();

      expect(map['name'], equals('Test Community'));
      expect(map['description'], equals('A test community'));
      expect(map['theme'], equals('Technology'));
    });
  });
}
