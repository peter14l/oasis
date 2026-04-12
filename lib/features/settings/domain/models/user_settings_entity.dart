import 'package:equatable/equatable.dart';

class UserSettingsEntity extends Equatable {
  final bool dataSaver;
  final double fontSizeFactor;
  final bool highContrast;
  final bool meshEnabled;
  final int dailyLimitMinutes;
  final bool windDownEnabled;
  final bool micaEnabled;
  final String windowEffect;
  final String fontFamily;

  const UserSettingsEntity({
    this.dataSaver = false,
    this.fontSizeFactor = 1.0,
    this.highContrast = false,
    this.meshEnabled = false,
    this.dailyLimitMinutes = 0,
    this.windDownEnabled = false,
    this.micaEnabled = false,
    this.windowEffect = 'mica',
    this.fontFamily = 'Outfit',
  });

  UserSettingsEntity copyWith({
    bool? dataSaver,
    double? fontSizeFactor,
    bool? highContrast,
    bool? meshEnabled,
    int? dailyLimitMinutes,
    bool? windDownEnabled,
    bool? micaEnabled,
    String? windowEffect,
    String? fontFamily,
  }) {
    return UserSettingsEntity(
      dataSaver: dataSaver ?? this.dataSaver,
      fontSizeFactor: fontSizeFactor ?? this.fontSizeFactor,
      highContrast: highContrast ?? this.highContrast,
      meshEnabled: meshEnabled ?? this.meshEnabled,
      dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
      windDownEnabled: windDownEnabled ?? this.windDownEnabled,
      micaEnabled: micaEnabled ?? this.micaEnabled,
      windowEffect: windowEffect ?? this.windowEffect,
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }

  @override
  List<Object?> get props => [
    dataSaver,
    fontSizeFactor,
    highContrast,
    meshEnabled,
    dailyLimitMinutes,
    windDownEnabled,
    micaEnabled,
    windowEffect,
    fontFamily,
  ];
}
