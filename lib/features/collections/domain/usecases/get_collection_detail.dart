import 'package:oasis/core/result/result.dart';
import 'package:oasis/features/feed/domain/models/post.dart';
import 'package:oasis/features/collections/domain/repositories/collection_repository.dart';

class GetCollectionDetailUseCase {
  final CollectionRepository _repository;

  GetCollectionDetailUseCase(this._repository);

  Future<Result<List<Post>>> call(String collectionId) {
    return _repository.getCollectionItems(collectionId);
  }
}
