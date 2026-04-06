import 'package:oasis/core/result/result.dart';
import 'package:oasis/features/settings/domain/models/user_settings_entity.dart';
import 'package:oasis/features/settings/domain/repositories/settings_repository.dart';

class GetSettingsUseCase {
  final SettingsRepository _repository;

  GetSettingsUseCase(this._repository);

  Future<Result<UserSettingsEntity>> call() {
    return _repository.getSettings();
  }
}

class SaveSettingsUseCase {
  final SettingsRepository _repository;

  SaveSettingsUseCase(this._repository);

  Future<Result<bool>> call(UserSettingsEntity settings) {
    return _repository.saveSettings(settings);
  }
}
