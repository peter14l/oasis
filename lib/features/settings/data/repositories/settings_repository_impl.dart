import 'package:oasis/core/result/result.dart';
import 'package:oasis/features/settings/domain/models/user_settings_entity.dart';
import 'package:oasis/features/settings/domain/repositories/settings_repository.dart';
import 'package:oasis/features/settings/data/datasources/settings_local_datasource.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDatasource _localDatasource;

  SettingsRepositoryImpl({SettingsLocalDatasource? localDatasource})
      : _localDatasource = localDatasource ?? SettingsLocalDatasource();

  @override
  Future<Result<UserSettingsEntity>> getSettings() async {
    try {
      final settings = await _localDatasource.getSettings();
      return Result.success(settings);
    } catch (e, stackTrace) {
      return Result.failure(
        message: e.toString(),
        exception: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<Result<bool>> saveSettings(UserSettingsEntity settings) async {
    try {
      final success = await _localDatasource.saveSettings(settings);
      return Result.success(success);
    } catch (e, stackTrace) {
      return Result.failure(
        message: e.toString(),
        exception: e,
        stackTrace: stackTrace,
      );
    }
  }
}
