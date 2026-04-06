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

  const UserSettingsEntity({
    this.dataSaver = false,
    this.fontSizeFactor = 1.0,
    this.highContrast = false,
    this.meshEnabled = true,
    this.dailyLimitMinutes = 0,
    this.windDownEnabled = false,
    this.micaEnabled = false,
    this.windowEffect = 'mica',
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
      ];
}
