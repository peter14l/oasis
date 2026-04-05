import 'package:oasis/features/auth/domain/repositories/auth_repository.dart';
import 'package:oasis/services/session_registry_service.dart';

class RestoreSession {
  final AuthRepository _repository;
  RestoreSession(this._repository);
  Future<RegisteredAccount?> call() => _repository.restoreSession();
}
