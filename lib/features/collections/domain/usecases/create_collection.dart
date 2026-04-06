import 'package:oasis/core/result/result.dart';
import 'package:oasis/features/collections/domain/models/collection_entity.dart';
import 'package:oasis/features/collections/domain/repositories/collection_repository.dart';

class CreateCollectionUseCase {
  final CollectionRepository _repository;

  CreateCollectionUseCase(this._repository);

  Future<Result<CollectionEntity>> call({
    required String name,
    String? description,
    bool isPrivate = true,
  }) {
    return _repository.createCollection(
      name: name,
      description: description,
      isPrivate: isPrivate,
    );
  }
}
