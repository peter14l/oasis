/// Predefined cozy modes with their emojis and default texts
enum CozyMode {
  cocoon('cocoon', '🏠', 'In my cocoon'),
  reading('reading', '📖', 'Reading mode'),
  recharge('recharge', '🔋', 'Offline recharge'),
  movieNight('movie_night', '🎬', 'Movie night'),
  deepThought('deep_thought', '💭', 'Deep thought'),
  sleepy('sleepy', '🌙', 'Sleepy'),
  custom('custom', '✨', 'Custom');

  final String id;
  final String emoji;
  final String defaultText;

  const CozyMode(this.id, this.emoji, this.defaultText);

  String getDisplayText(String? customText) {
    if (this == CozyMode.custom && customText != null) {
      return customText;
    }
    return '$emoji $defaultText';
  }
}

class CozyModeState {
  final CozyMode? activeMode;
  final String? customText;
  final DateTime? until;
  final bool isLoading;
  final String? error;

  const CozyModeState({
    this.activeMode,
    this.customText,
    this.until,
    this.isLoading = false,
    this.error,
  });

  bool get hasActiveCozyStatus =>
      activeMode != null &&
      (until == null || until!.isAfter(DateTime.now()));

  String get displayText {
    if (activeMode == null) return '';
    if (this.customText != null && this.customText!.isNotEmpty) {
      return '${activeMode!.emoji} $customText';
    }
    return activeMode!.getDisplayText(null);
  }

  CozyModeState copyWith({
    CozyMode? activeMode,
    String? customText,
    DateTime? until,
    bool? isLoading,
    String? error,
    bool clearMode = false,
  }) {
    return CozyModeState(
      activeMode: clearMode ? null : (activeMode ?? this.activeMode),
      customText: clearMode ? null : (customText ?? this.customText),
      until: clearMode ? null : (until ?? this.until),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}