import 'package:oasis_v2/features/auth/domain/repositories/auth_repository.dart';

class SignInWithApple {
  final AuthRepository _repository;
  SignInWithApple(this._repository);
  Future<void> call() => _repository.signInWithApple();
}
