import 'package:flutter/material.dart';
import 'package:oasis_v2/widgets/messages/voice_message_player.dart';

/// Voice/audio message bubble.
/// Extracted from the voice branch of _buildMessageBubble() in chat_screen.dart.
class VoiceBubble extends StatelessWidget {
  const VoiceBubble({
    super.key,
    required this.audioUrl,
    required this.duration,
    required this.isMe,
    this.textColor,
  });

  final String audioUrl;
  final int? duration;
  final bool isMe;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final color =
        textColor ??
        (isMe
            ? Theme.of(context).colorScheme.onPrimaryContainer
            : Theme.of(context).colorScheme.onSurface);

    return VoiceMessagePlayer(
      audioUrl: audioUrl,
      duration: duration,
      isMe: isMe,
      color: color,
    );
  }
}
