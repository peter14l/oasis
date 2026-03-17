import 'dart:math';
import 'package:oasis_v2/services/supabase_service.dart';

/// AI Content Companion service for caption and hashtag suggestions
class AIContentService {
  static final _random = Random();

  /// Generate caption suggestions based on image analysis keywords
  static List<String> generateCaptionSuggestions({
    List<String>? detectedObjects,
    String? location,
    String? timeOfDay,
    String? mood,
  }) {
    final suggestions = <String>[];

    // Time-based suggestions
    if (timeOfDay != null) {
      switch (timeOfDay.toLowerCase()) {
        case 'morning':
          suggestions.addAll([
            'Rise and grind ☀️',
            'Morning vibes ✨',
            'New day, new possibilities',
            'Coffee first, adulting later ☕',
          ]);
          break;
        case 'afternoon':
          suggestions.addAll([
            'Making the most of today',
            'Afternoon adventures 🌤️',
            'Living in the moment',
          ]);
          break;
        case 'evening':
          suggestions.addAll([
            'Golden hour magic 🌅',
            'Evening reflections',
            'Chasing the sunset',
          ]);
          break;
        case 'night':
          suggestions.addAll([
            'Night owl mode 🦉',
            'City lights ✨',
            'Under the stars',
          ]);
          break;
      }
    }

    // Location-based suggestions
    if (location != null && location.isNotEmpty) {
      suggestions.addAll([
        'Exploring $location 📍',
        '$location, you have my heart ❤️',
        'Adventures in $location',
      ]);
    }

    // Mood-based suggestions
    if (mood != null) {
      switch (mood.toLowerCase()) {
        case 'happy':
          suggestions.addAll([
            'Happiness looks good on me 😊',
            'Living my best life',
            'Grateful for moments like these',
          ]);
          break;
        case 'chill':
          suggestions.addAll([
            'Just vibing ✌️',
            'Peace and quiet',
            'Slow living',
          ]);
          break;
        case 'excited':
          suggestions.addAll([
            "Can't contain the excitement! 🎉",
            'Big things coming!',
            'Here for the adventure',
          ]);
          break;
        case 'inspired':
          suggestions.addAll([
            'Creating is healing ✨',
            'Finding inspiration everywhere',
            'Dream it. Do it.',
          ]);
          break;
      }
    }

    // Object-based suggestions (simulated image analysis)
    if (detectedObjects != null) {
      for (final obj in detectedObjects) {
        switch (obj.toLowerCase()) {
          case 'food':
            suggestions.addAll([
              'Eat well, travel often 🍕',
              'Food is love made visible',
              "Can't talk, I'm eating",
            ]);
            break;
          case 'beach':
            suggestions.addAll([
              'Sandy toes, sun-kissed nose 🏖️',
              'Life is better at the beach',
              'Ocean breeze, salty hair',
            ]);
            break;
          case 'mountain':
            suggestions.addAll([
              'The mountains are calling ⛰️',
              'Peak experiences only',
              'On top of the world',
            ]);
            break;
          case 'city':
            suggestions.addAll([
              'City slicker 🏙️',
              'Urban jungle adventures',
              'Getting lost in the city',
            ]);
            break;
          case 'pet':
            suggestions.addAll([
              'Pawsitively adorable 🐾',
              'My favorite co-pilot',
              'Unconditional love',
            ]);
            break;
          case 'friend':
          case 'people':
            suggestions.addAll([
              'Making memories with my people 👯',
              'Good times, great company',
              'Friends who slay together, stay together',
            ]);
            break;
        }
      }
    }

    // Generic fallbacks
    if (suggestions.isEmpty) {
      suggestions.addAll([
        'Living my story one photo at a time 📸',
        'Moments worth remembering',
        'Creating memories ✨',
        "Here's to the good times",
        'Plot twist: life is beautiful',
      ]);
    }

    // Shuffle and return based on tier
    suggestions.shuffle(_random);
    final user = SupabaseService().client.auth.currentUser;
    final isPro = user?.userMetadata?['is_pro'] == true;
    final limit = isPro ? 10 : 2;
    return suggestions.take(limit).toList();
  }

  /// Generate hashtag recommendations
  static List<String> generateHashtagSuggestions({
    List<String>? detectedObjects,
    String? category,
    String? mood,
    String? location,
  }) {
    final hashtags = <String>{};

    // Always include some trending general hashtags
    hashtags.addAll(['#instagood', '#photooftheday', '#Oasis']);

    // Mood hashtags
    if (mood != null) {
      switch (mood.toLowerCase()) {
        case 'happy':
          hashtags.addAll(['#happy', '#smile', '#positivevibes', '#goodvibes']);
          break;
        case 'chill':
          hashtags.addAll(['#chill', '#relax', '#peaceful', '#slowdown']);
          break;
        case 'excited':
          hashtags.addAll([
            '#excited',
            '#letsgoo',
            '#adventure',
            '#livingmybestlife',
          ]);
          break;
        case 'inspired':
          hashtags.addAll([
            '#inspired',
            '#creative',
            '#motivation',
            '#dreambig',
          ]);
          break;
        case 'grateful':
          hashtags.addAll(['#grateful', '#blessed', '#thankful', '#gratitude']);
          break;
      }
    }

    // Category hashtags
    if (category != null) {
      switch (category.toLowerCase()) {
        case 'travel':
          hashtags.addAll([
            '#travel',
            '#wanderlust',
            '#explore',
            '#adventure',
            '#travelgram',
          ]);
          break;
        case 'food':
          hashtags.addAll([
            '#food',
            '#foodie',
            '#yummy',
            '#delicious',
            '#foodporn',
          ]);
          break;
        case 'fitness':
          hashtags.addAll([
            '#fitness',
            '#workout',
            '#gym',
            '#fitfam',
            '#health',
          ]);
          break;
        case 'fashion':
          hashtags.addAll([
            '#fashion',
            '#style',
            '#ootd',
            '#fashionista',
            '#outfit',
          ]);
          break;
        case 'nature':
          hashtags.addAll([
            '#nature',
            '#naturephotography',
            '#outdoors',
            '#landscape',
          ]);
          break;
        case 'art':
          hashtags.addAll([
            '#art',
            '#artist',
            '#creative',
            '#artwork',
            '#design',
          ]);
          break;
      }
    }

    // Object-based hashtags
    if (detectedObjects != null) {
      for (final obj in detectedObjects) {
        switch (obj.toLowerCase()) {
          case 'beach':
            hashtags.addAll([
              '#beach',
              '#beachlife',
              '#ocean',
              '#summer',
              '#waves',
            ]);
            break;
          case 'mountain':
            hashtags.addAll([
              '#mountains',
              '#hiking',
              '#nature',
              '#mountainlife',
            ]);
            break;
          case 'pet':
          case 'dog':
          case 'cat':
            hashtags.addAll([
              '#pets',
              '#petsofinstagram',
              '#cute',
              '#animals',
              '#love',
            ]);
            break;
          case 'sunset':
            hashtags.addAll([
              '#sunset',
              '#sunsetlovers',
              '#goldenhour',
              '#sky',
            ]);
            break;
          case 'city':
            hashtags.addAll(['#city', '#urban', '#citylife', '#architecture']);
            break;
        }
      }
    }

    // Location hashtag
    if (location != null && location.isNotEmpty) {
      final locationTag = '#${location.replaceAll(' ', '').toLowerCase()}';
      hashtags.add(locationTag);
    }

    final hashtagList = hashtags.toList();
    hashtagList.shuffle(_random);
    final user = SupabaseService().client.auth.currentUser;
    final isPro = user?.userMetadata?['is_pro'] == true;
    final limit = isPro ? 30 : 5;
    return hashtagList.take(limit).toList();
  }

  /// Get optimal posting time suggestions based on day of week
  static Map<String, String> getOptimalPostingTimes() {
    return {
      'Monday': '11:00 AM - 1:00 PM',
      'Tuesday': '9:00 AM - 11:00 AM',
      'Wednesday': '11:00 AM - 1:00 PM',
      'Thursday': '12:00 PM - 2:00 PM',
      'Friday': '10:00 AM - 12:00 PM',
      'Saturday': '9:00 AM - 11:00 AM',
      'Sunday': '10:00 AM - 2:00 PM',
    };
  }

  /// Get current optimal posting time
  static String getCurrentOptimalTime() {
    final now = DateTime.now();
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final dayName = days[now.weekday - 1];
    return getOptimalPostingTimes()[dayName] ?? '12:00 PM';
  }

  /// Grammar and tone check (simplified)
  static Map<String, dynamic> checkCaptionQuality(String caption) {
    final user = SupabaseService().client.auth.currentUser;
    final isPro = user?.userMetadata?['is_pro'] == true;
    if (!isPro) {
      throw Exception(
        'Upgrade to Oasis Pro to access live caption quality scoring.',
      );
    }
    final issues = <String>[];
    final suggestions = <String>[];

    // Check length
    if (caption.length < 10) {
      issues.add('Caption might be too short');
      suggestions.add('Consider adding more context or a call to action');
    }

    if (caption.length > 2200) {
      issues.add('Caption exceeds maximum length');
      suggestions.add('Trim down to 2200 characters');
    }

    // Check for excessive caps
    final upperCount = caption.replaceAll(RegExp(r'[^A-Z]'), '').length;
    final letterCount = caption.replaceAll(RegExp(r'[^a-zA-Z]'), '').length;
    if (letterCount > 0 && upperCount / letterCount > 0.5) {
      issues.add('Excessive use of caps');
      suggestions.add(
        'Consider using normal capitalization for better readability',
      );
    }

    // Check for excessive punctuation
    if (RegExp(r'[!?]{3,}').hasMatch(caption)) {
      issues.add('Excessive punctuation');
      suggestions.add('Consider reducing punctuation marks');
    }

    // Check for hashtags count
    final hashtagCount = '#'.allMatches(caption).length;
    if (hashtagCount > 30) {
      issues.add('Too many hashtags (${hashtagCount})');
      suggestions.add('Keep hashtags under 30 for best engagement');
    }

    // Calculate quality score
    int score = 100;
    score -= issues.length * 15;
    score = score.clamp(0, 100);

    return {
      'score': score,
      'issues': issues,
      'suggestions': suggestions,
      'quality':
          score >= 80
              ? 'Excellent'
              : score >= 60
              ? 'Good'
              : score >= 40
              ? 'Fair'
              : 'Needs Work',
    };
  }
}
