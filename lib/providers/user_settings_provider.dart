import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserSettingsProvider with ChangeNotifier {
  static const String _dataSaverKey = 'data_saver';
  static const String _fontSizeFactorKey = 'font_size_factor';
  static const String _highContrastKey = 'high_contrast';
  static const String _meshEnabledKey = 'mesh_enabled';

  bool _dataSaver = false;
  double _fontSizeFactor = 1.0;
  bool _highContrast = false;
  bool _meshEnabled = true;

  bool get dataSaver => _dataSaver;
  double get fontSizeFactor => _fontSizeFactor;
  bool get highContrast => _highContrast;
  bool get meshEnabled => _meshEnabled;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _dataSaver = prefs.getBool(_dataSaverKey) ?? false;
    _fontSizeFactor = prefs.getDouble(_fontSizeFactorKey) ?? 1.0;
    _highContrast = prefs.getBool(_highContrastKey) ?? false;
    _meshEnabled = prefs.getBool(_meshEnabledKey) ?? true;
    notifyListeners();
  }

  Future<void> setMeshEnabled(bool value) async {
    _meshEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_meshEnabledKey, value);
    notifyListeners();
  }

  Future<void> setDataSaver(bool value) async {
    _dataSaver = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dataSaverKey, value);
    notifyListeners();
  }

  Future<void> setFontSizeFactor(double value) async {
    _fontSizeFactor = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeFactorKey, value);
    notifyListeners();
  }

  Future<void> setHighContrast(bool value) async {
    _highContrast = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_highContrastKey, value);
    notifyListeners();
  }
}
