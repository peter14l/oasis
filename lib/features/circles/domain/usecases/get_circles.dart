import 'package:oasis_v2/features/circles/domain/models/circles_models.dart';
import 'package:oasis_v2/features/circles/domain/repositories/circle_repository.dart';

class GetCircles {
  final CircleRepository _repository;
  GetCircles(this._repository);
  Future<List<CircleEntity>> call(String userId) =>
      _repository.getCircles(userId);
}
