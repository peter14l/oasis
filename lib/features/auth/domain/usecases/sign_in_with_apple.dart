import 'package:oasis/features/auth/domain/repositories/auth_repository.dart';

class SignInWithApple {
  final AuthRepository _repository;
  SignInWithApple(this._repository);
  Future<void> call() => _repository.signInWithApple();
}
