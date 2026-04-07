import 'package:shared_preferences/shared_preferences.dart';
import 'package:oasis/features/settings/domain/models/user_settings_entity.dart';
import 'package:oasis/core/errors/app_exception.dart';

class SettingsLocalDatasource {
  static const String _dataSaverKey = 'data_saver';
  static const String _fontSizeFactorKey = 'font_size_factor';
  static const String _highContrastKey = 'high_contrast';
  static const String _meshEnabledKey = 'mesh_enabled';
  static const String _dailyLimitKey = 'daily_limit';
  static const String _windDownKey = 'wind_down_enabled';
  static const String _micaEnabledKey = 'mica_enabled';
  static const String _windowEffectKey = 'window_effect';
  static const String _fontFamilyKey = 'font_family';

  Future<UserSettingsEntity> getSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return UserSettingsEntity(
        dataSaver: prefs.getBool(_dataSaverKey) ?? false,
        fontSizeFactor: prefs.getDouble(_fontSizeFactorKey) ?? 1.0,
        highContrast: prefs.getBool(_highContrastKey) ?? false,
        meshEnabled: prefs.getBool(_meshEnabledKey) ?? true,
        dailyLimitMinutes: prefs.getInt(_dailyLimitKey) ?? 0,
        windDownEnabled: prefs.getBool(_windDownKey) ?? false,
        micaEnabled: prefs.getBool(_micaEnabledKey) ?? false,
        windowEffect: prefs.getString(_windowEffectKey) ?? 'mica',
        fontFamily: prefs.getString(_fontFamilyKey) ?? 'Comfortaa',
      );
    } catch (e) {
      throw StorageException('Failed to load settings', code: e.toString());
    }
  }

  Future<bool> saveSettings(UserSettingsEntity settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await Future.wait([
        prefs.setBool(_dataSaverKey, settings.dataSaver),
        prefs.setDouble(_fontSizeFactorKey, settings.fontSizeFactor),
        prefs.setBool(_highContrastKey, settings.highContrast),
        prefs.setBool(_meshEnabledKey, settings.meshEnabled),
        prefs.setInt(_dailyLimitKey, settings.dailyLimitMinutes),
        prefs.setBool(_windDownKey, settings.windDownEnabled),
        prefs.setBool(_micaEnabledKey, settings.micaEnabled),
        prefs.setString(_windowEffectKey, settings.windowEffect),
        prefs.setString(_fontFamilyKey, settings.fontFamily),
      ]);
      
      return true;
    } catch (e) {
      throw StorageException('Failed to save settings', code: e.toString());
    }
  }
}
