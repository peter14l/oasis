import 'package:oasis/features/auth/domain/models/auth_models.dart';
import 'package:oasis/features/auth/domain/repositories/auth_repository.dart';
import 'package:oasis/services/session_registry_service.dart';

class SignInWithEmail {
  final AuthRepository _repository;
  SignInWithEmail(this._repository);
  Future<RegisteredAccount> call(AuthCredentials credentials) {
    return _repository.signInWithEmail(credentials);
  }
}
