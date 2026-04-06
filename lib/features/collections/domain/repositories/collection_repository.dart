import 'package:oasis/core/result/result.dart';
import 'package:oasis/features/collections/domain/models/collection_entity.dart';
import 'package:oasis/features/feed/domain/models/post.dart';

abstract class CollectionRepository {
  /// Get all collections for current user
  Future<Result<List<CollectionEntity>>> getUserCollections();

  /// Create a new collection
  Future<Result<CollectionEntity>> createCollection({
    required String name,
    String? description,
    bool isPrivate = true,
  });

  /// Update a collection
  Future<Result<bool>> updateCollection({
    required String collectionId,
    String? name,
    String? description,
    bool? isPrivate,
  });

  /// Delete a collection
  Future<Result<bool>> deleteCollection(String collectionId);

  /// Add post to collection (also bookmarks it)
  Future<Result<bool>> addToCollection(String collectionId, String postId);

  /// Remove post from collection
  Future<Result<bool>> removeFromCollection(String collectionId, String postId);

  /// Get items in a collection
  Future<Result<List<Post>>> getCollectionItems(String collectionId);

  /// Check if post is in a specific collection
  Future<Result<bool>> isPostInCollection(String collectionId, String postId);

  /// Get collections containing a specific post
  Future<Result<List<CollectionEntity>>> getCollectionsForPost(String postId);
}
