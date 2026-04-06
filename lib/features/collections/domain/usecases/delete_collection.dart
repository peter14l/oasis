import 'package:oasis/core/result/result.dart';
import 'package:oasis/features/collections/domain/repositories/collection_repository.dart';

class DeleteCollectionUseCase {
  final CollectionRepository _repository;

  DeleteCollectionUseCase(this._repository);

  Future<Result<bool>> call(String collectionId) {
    return _repository.deleteCollection(collectionId);
  }
}
