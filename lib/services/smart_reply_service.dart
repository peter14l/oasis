import 'package:flutter/material.dart';
import 'package:oasis_v2/utils/haptic_utils.dart';

/// Smart reply suggestions based on message context
class SmartReplyService {
  /// Generate smart reply suggestions based on the last message
  static List<String> getSuggestions(String lastMessage) {
    final lowerMessage = lastMessage.toLowerCase().trim();

    // Question responses
    if (lowerMessage.contains('?')) {
      if (_containsAny(lowerMessage, [
        'how are you',
        'how r u',
        "how's it going",
        'whats up',
        "what's up",
      ])) {
        return [
          "I'm doing great! 😊",
          "Pretty good, thanks!",
          "Can't complain!",
          "Living the dream 🌟",
        ];
      }
      if (_containsAny(lowerMessage, ['want to', 'wanna', 'do you want'])) {
        return [
          "Sure, sounds good!",
          "I'd love to!",
          "Maybe later?",
          "Count me in! 🎉",
        ];
      }
      if (_containsAny(lowerMessage, [
        'what do you think',
        'thoughts',
        'opinion',
      ])) {
        return [
          "I think it's great!",
          "Interesting idea 🤔",
          "Let me think about it",
          "I agree!",
        ];
      }
      if (_containsAny(lowerMessage, ['where', 'when', 'what time'])) {
        return [
          "Let me check",
          "I'll get back to you",
          "Not sure yet",
          "Give me a sec",
        ];
      }
      if (_containsAny(lowerMessage, ['can you', 'could you', 'would you'])) {
        return [
          "Sure thing!",
          "Of course!",
          "No problem 👍",
          "I'll try my best",
        ];
      }
      // Generic question
      return ["Yes!", "No, sorry", "Maybe 🤔", "Let me check"];
    }

    // Greeting responses
    if (_containsAny(lowerMessage, ['hi', 'hello', 'hey', 'hola', 'sup'])) {
      return ["Hey! 👋", "Hello!", "Hi there!", "What's up? 😊"];
    }

    // Gratitude responses
    if (_containsAny(lowerMessage, ['thank', 'thanks', 'thx', 'appreciate'])) {
      return [
        "You're welcome!",
        "No problem! 😊",
        "Anytime!",
        "Happy to help!",
      ];
    }

    // Positive sentiment
    if (_containsAny(lowerMessage, [
      'awesome',
      'great',
      'amazing',
      'love',
      'nice',
      'cool',
      'perfect',
    ])) {
      return ["🎉", "Glad you like it!", "Right?! 😄", "Absolutely!"];
    }

    // Sympathy
    if (_containsAny(lowerMessage, [
      'sad',
      'sorry',
      'bad day',
      'upset',
      'frustrated',
    ])) {
      return [
        "I'm here for you 💙",
        "That's tough, sorry",
        "Sending hugs 🤗",
        "Things will get better",
      ];
    }

    // Excitement
    if (_containsAny(lowerMessage, ['excited', 'can\'t wait', 'omg', '!!!'])) {
      return ["So exciting! 🎉", "I know right?!", "Me too!", "Can't wait! 🚀"];
    }

    // Affirmation
    if (_containsAny(lowerMessage, [
      'sounds good',
      'okay',
      'ok',
      'sure',
      'alright',
    ])) {
      return [
        "Perfect! 👍",
        "Great!",
        "See you then!",
        "Looking forward to it",
      ];
    }

    // Goodbye
    if (_containsAny(lowerMessage, [
      'bye',
      'goodbye',
      'see you',
      'later',
      'gtg',
      'gotta go',
    ])) {
      return ["Bye! 👋", "See you later!", "Take care!", "Talk soon! 😊"];
    }

    // Generic fallbacks
    return ["👍", "😊", "Sounds good!", "Got it!"];
  }

  static bool _containsAny(String text, List<String> patterns) {
    for (final pattern in patterns) {
      if (text.contains(pattern)) return true;
    }
    return false;
  }
}

/// Widget for displaying smart reply suggestions
class SmartReplyBar extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String> onSuggestionTap;

  const SmartReplyBar({
    super.key,
    required this.suggestions,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              HapticUtils.lightImpact();
              onSuggestionTap(suggestions[index]);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                suggestions[index],
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
