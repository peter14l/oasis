import 'package:oasis/core/result/result.dart';
import 'package:oasis/features/collections/domain/repositories/collection_repository.dart';

class CheckPostInCollectionUseCase {
  final CollectionRepository _repository;

  CheckPostInCollectionUseCase(this._repository);

  Future<Result<bool>> call(String collectionId, String postId) {
    return _repository.isPostInCollection(collectionId, postId);
  }
}
