import 'package:oasis/core/result/result.dart';
import 'package:oasis/features/collections/domain/repositories/collection_repository.dart';

class RemoveFromCollectionUseCase {
  final CollectionRepository _repository;

  RemoveFromCollectionUseCase(this._repository);

  Future<Result<bool>> call(String collectionId, String postId) {
    return _repository.removeFromCollection(collectionId, postId);
  }
}
