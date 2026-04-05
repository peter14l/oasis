import 'package:oasis/features/auth/domain/repositories/auth_repository.dart';

class SignInWithGoogle {
  final AuthRepository _repository;
  SignInWithGoogle(this._repository);
  Future<void> call() => _repository.signInWithGoogle();
}
