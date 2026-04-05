import 'package:flutter_test/flutter_test.dart';
import 'package:oasis/features/feed/domain/models/post.dart';

void main() {
  group('Post.fromJson Parsing Tests', () {
    test('Parses comments_count correctly from integer', () {
      final json = {
        'id': 'post1',
        'user_id': 'user1',
        'username': 'testuser',
        'content': 'Hello',
        'comments_count': 5,
        'likes_count': 10,
        'created_at': DateTime.now().toIso8601String(),
      };

      final post = Post.fromJson(json);
      expect(post.comments, 5);
    });

    test('Parses comments correctly if comments_count is missing', () {
      final json = {
        'id': 'post1',
        'user_id': 'user1',
        'username': 'testuser',
        'content': 'Hello',
        'comments': 3,
        'likes': 10,
        'created_at': DateTime.now().toIso8601String(),
      };

      final post = Post.fromJson(json);
      expect(post.comments, 3);
    });

    test('Defaults to 0 if both comments and comments_count are missing', () {
      final json = {
        'id': 'post1',
        'user_id': 'user1',
        'username': 'testuser',
        'content': 'Hello',
        'created_at': DateTime.now().toIso8601String(),
      };

      final post = Post.fromJson(json);
      expect(post.comments, 0);
    });

    test('Handles null values gracefully', () {
      final json = {
        'id': 'post1',
        'user_id': 'user1',
        'username': 'testuser',
        'content': 'Hello',
        'comments_count': null,
        'comments': null,
        'created_at': DateTime.now().toIso8601String(),
      };

      final post = Post.fromJson(json);
      expect(post.comments, 0);
    });
  });
}
