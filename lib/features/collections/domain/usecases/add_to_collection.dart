import 'package:oasis/core/result/result.dart';
import 'package:oasis/features/collections/domain/repositories/collection_repository.dart';

class AddToCollectionUseCase {
  final CollectionRepository _repository;

  AddToCollectionUseCase(this._repository);

  Future<Result<bool>> call(String collectionId, String postId) {
    return _repository.addToCollection(collectionId, postId);
  }
}
