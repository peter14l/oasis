import 'package:flutter/foundation.dart';
import 'package:oasis/features/settings/domain/models/user_settings_entity.dart';
import 'package:oasis/features/settings/domain/usecases/settings_usecases.dart';

class UserSettingsProvider with ChangeNotifier {
  final GetSettingsUseCase _getSettingsUseCase;
  final SaveSettingsUseCase _saveSettingsUseCase;

  UserSettingsEntity _settings = const UserSettingsEntity();

  UserSettingsProvider({
    required GetSettingsUseCase getSettingsUseCase,
    required SaveSettingsUseCase saveSettingsUseCase,
  })  : _getSettingsUseCase = getSettingsUseCase,
        _saveSettingsUseCase = saveSettingsUseCase;

  bool get dataSaver => _settings.dataSaver;
  double get fontSizeFactor => _settings.fontSizeFactor;
  bool get highContrast => _settings.highContrast;
  bool get meshEnabled => _settings.meshEnabled;
  int get dailyLimitMinutes => _settings.dailyLimitMinutes;
  bool get windDownEnabled => _settings.windDownEnabled;
  bool get micaEnabled => _settings.micaEnabled;
  String get windowEffect => _settings.windowEffect;

  Future<void> loadSettings() async {
    final result = await _getSettingsUseCase();
    result.fold(
      onSuccess: (settings) {
        _settings = settings;
        notifyListeners();
      },
      onFailure: (error) {
        debugPrint('Failed to load settings: $error');
      },
    );
  }

  Future<void> _updateAndSave(UserSettingsEntity newSettings) async {
    // Optimistic update
    _settings = newSettings;
    notifyListeners();

    final result = await _saveSettingsUseCase(_settings);
    result.fold(
      onSuccess: (_) {}, // Already updated
      onFailure: (error) {
        debugPrint('Failed to save settings: $error');
        // We could revert here, but for simple settings we might just notify error via some mechanism
        // For now, load from disk again
        loadSettings();
      },
    );
  }

  Future<void> setMicaEnabled(bool value) async {
    await _updateAndSave(_settings.copyWith(micaEnabled: value));
  }

  Future<void> setWindowEffect(String value) async {
    await _updateAndSave(_settings.copyWith(windowEffect: value));
  }

  Future<void> setDailyLimit(int minutes) async {
    await _updateAndSave(_settings.copyWith(dailyLimitMinutes: minutes));
  }

  Future<void> setWindDownEnabled(bool value) async {
    await _updateAndSave(_settings.copyWith(windDownEnabled: value));
  }

  Future<void> setMeshEnabled(bool value) async {
    await _updateAndSave(_settings.copyWith(meshEnabled: value));
  }

  Future<void> setDataSaver(bool value) async {
    await _updateAndSave(_settings.copyWith(dataSaver: value));
  }

  Future<void> setFontSizeFactor(double value) async {
    await _updateAndSave(_settings.copyWith(fontSizeFactor: value));
  }

  Future<void> setHighContrast(bool value) async {
    await _updateAndSave(_settings.copyWith(highContrast: value));
  }
}
