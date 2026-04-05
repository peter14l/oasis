import 'package:oasis/features/auth/domain/repositories/auth_repository.dart';
import 'package:oasis/services/session_registry_service.dart';

class SignUp {
  final AuthRepository _repository;
  SignUp(this._repository);
  Future<RegisteredAccount> call({
    required String email,
    required String password,
    String? username,
    String? fullName,
  }) {
    return _repository.signUp(
      email: email,
      password: password,
      username: username,
      fullName: fullName,
    );
  }
}
