import 'package:oasis_v2/features/auth/domain/repositories/auth_repository.dart';

class SignInWithGoogle {
  final AuthRepository _repository;
  SignInWithGoogle(this._repository);
  Future<void> call() => _repository.signInWithGoogle();
}
