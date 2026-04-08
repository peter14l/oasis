import 'package:oasis/features/auth/domain/repositories/auth_repository.dart';

class ResetPassword {
  final AuthRepository _repository;
  ResetPassword(this._repository);
  Future<void> call(String identifier) => _repository.resetPassword(identifier);
}
