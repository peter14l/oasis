import 'package:oasis/core/result/result.dart';
import 'package:oasis/features/collections/domain/repositories/collection_repository.dart';

class UpdateCollectionUseCase {
  final CollectionRepository _repository;

  UpdateCollectionUseCase(this._repository);

  Future<Result<bool>> call({
    required String collectionId,
    String? name,
    String? description,
    bool? isPrivate,
  }) {
    return _repository.updateCollection(
      collectionId: collectionId,
      name: name,
      description: description,
      isPrivate: isPrivate,
    );
  }
}
