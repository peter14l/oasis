import 'package:oasis/core/result/result.dart';
import 'package:oasis/features/collections/domain/models/collection_entity.dart';
import 'package:oasis/features/collections/domain/repositories/collection_repository.dart';

class GetCollectionsUseCase {
  final CollectionRepository _repository;

  GetCollectionsUseCase(this._repository);

  Future<Result<List<CollectionEntity>>> call() {
    return _repository.getUserCollections();
  }
}
