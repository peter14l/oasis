import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oasis/providers/typing_indicator_provider.dart';
import 'package:oasis/widgets/messages/typing_indicator_widget.dart';

/// Typing indicator widget.
/// Extracted from the Consumer<TypingIndicatorProvider> block in chat_screen.dart.
class ChatTypingIndicator extends StatelessWidget {
  const ChatTypingIndicator({
    super.key,
    required this.conversationId,
    this.currentUserId,
  });

  final String conversationId;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    return Consumer<TypingIndicatorProvider>(
      builder: (context, typingProvider, child) {
        final isTyping = typingProvider.isUserTyping(conversationId);
        if (!isTyping) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TypingIndicatorWidget(username: 'Someone'),
        );
      },
    );
  }
}
