/// Mood types for posts and feed filtering
enum PostMood {
  happy('😊', 'Happy', 'Uplifting and joyful content'),
  chill('😌', 'Chill', 'Relaxed and calm vibes'),
  inspired('✨', 'Inspired', 'Motivational and creative'),
  excited('🎉', 'Excited', 'High energy celebrations'),
  thoughtful('🤔', 'Thoughtful', 'Reflective and deep'),
  grateful('🙏', 'Grateful', 'Appreciation and thankfulness'),
  adventurous('🌍', 'Adventurous', 'Exploring and discovering'),
  cozy('☕', 'Cozy', 'Warm and comfortable moments');

  final String emoji;
  final String label;
  final String description;

  const PostMood(this.emoji, this.label, this.description);

  static PostMood? fromString(String? value) {
    if (value == null) return null;
    for (final mood in PostMood.values) {
      if (mood.name == value ||
          mood.label.toLowerCase() == value.toLowerCase()) {
        return mood;
      }
    }
    return null;
  }

  String get displayText => '$emoji $label';
}

/// Model for mood-aware feed preferences
class MoodFeedPreferences {
  final bool matchMyMood;
  final PostMood? currentMood;
  final List<PostMood> allowedMoods;

  MoodFeedPreferences({
    this.matchMyMood = false,
    this.currentMood,
    this.allowedMoods = const [],
  });

  MoodFeedPreferences copyWith({
    bool? matchMyMood,
    PostMood? currentMood,
    List<PostMood>? allowedMoods,
  }) {
    return MoodFeedPreferences(
      matchMyMood: matchMyMood ?? this.matchMyMood,
      currentMood: currentMood ?? this.currentMood,
      allowedMoods: allowedMoods ?? this.allowedMoods,
    );
  }
}
