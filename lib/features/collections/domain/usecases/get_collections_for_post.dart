import 'package:oasis/core/result/result.dart';
import 'package:oasis/features/collections/domain/models/collection_entity.dart';
import 'package:oasis/features/collections/domain/repositories/collection_repository.dart';

class GetCollectionsForPostUseCase {
  final CollectionRepository _repository;

  GetCollectionsForPostUseCase(this._repository);

  Future<Result<List<CollectionEntity>>> call(String postId) {
    return _repository.getCollectionsForPost(postId);
  }
}
