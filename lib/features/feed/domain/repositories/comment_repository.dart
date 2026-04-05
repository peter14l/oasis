import 'package:oasis/features/feed/domain/models/comment.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository contract for comment operations.
abstract class CommentRepository {
  /// Get top-level comments for a post.
  Future<List<Comment>> getPostComments({
    required String postId,
    required String currentUserId,
    int limit = 50,
    int offset = 0,
  });

  /// Get replies for a specific comment.
  Future<List<Comment>> getCommentReplies({
    required String commentId,
    required String currentUserId,
    int limit = 20,
    int offset = 0,
  });

  /// Create a comment (top-level or reply).
  Future<Comment> createComment({
    required String userId,
    required String postId,
    required String content,
    String? parentCommentId,
  });

  /// Update a comment (verifies ownership).
  Future<Comment> updateComment({
    required String commentId,
    required String userId,
    required String content,
  });

  /// Delete a comment (verifies ownership).
  Future<void> deleteComment({
    required String commentId,
    required String userId,
  });

  /// Like a comment.
  Future<void> likeComment({required String userId, required String commentId});

  /// Unlike a comment.
  Future<void> unlikeComment({
    required String userId,
    required String commentId,
  });

  /// Subscribe to real-time comment updates for a post.
  RealtimeChannel subscribeToPostComments({
    required String postId,
    required Function(Map<String, dynamic>) onCommentAdded,
    required Function(String) onCommentDeleted,
  });

  /// Unsubscribe from comment updates.
  Future<void> unsubscribeFromComments(RealtimeChannel channel);
}
