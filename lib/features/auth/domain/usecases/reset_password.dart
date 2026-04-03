import 'package:oasis_v2/features/auth/domain/repositories/auth_repository.dart';

class ResetPassword {
  final AuthRepository _repository;
  ResetPassword(this._repository);
  Future<void> call(String email) => _repository.resetPassword(email);
}
