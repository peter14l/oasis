import 'package:flutter/material.dart';

/// Whisper mode gesture detector for pull-up to enable/disable.
/// TODO: Fully extract from chat_screen.dart whisper gesture logic.
/// This is a placeholder — the actual implementation is still in the legacy screen.
class ChatWhisperGesture extends StatelessWidget {
  const ChatWhisperGesture({
    super.key,
    required this.child,
    required this.isWhisperMode,
    required this.onWhisperToggle,
    this.dragProgress = 0.0,
    this.dragOffset = 0.0,
  });

  final Widget child;
  final int isWhisperMode;
  final VoidCallback onWhisperToggle;
  final double dragProgress;
  final double dragOffset;

  @override
  Widget build(BuildContext context) {
    // TODO: Extract full GestureDetector with PanUpdate logic from chat_screen.dart
    // For now, pass through the child
    return child;
  }
}
