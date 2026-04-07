import 'package:flutter/material.dart';
import 'package:oasis/core/utils/haptic_utils.dart';

typedef WhisperDragBuilder = Widget Function(
  BuildContext context,
  double dragProgress,
  double dragOffset,
);

/// Whisper mode gesture detector for pull-up to enable/disable.
class ChatWhisperGesture extends StatefulWidget {
  const ChatWhisperGesture({
    super.key,
    required this.builder,
    required this.isWhisperMode,
    required this.onWhisperToggle,
    this.dragThreshold = 80.0,
  });

  final WhisperDragBuilder builder;
  final int isWhisperMode;
  final VoidCallback onWhisperToggle;
  final double dragThreshold;

  @override
  State<ChatWhisperGesture> createState() => _ChatWhisperGestureState();
}

class _ChatWhisperGestureState extends State<ChatWhisperGesture> {
  double _dragProgress = 0.0;
  double _dragOffset = 0.0;
  bool _triggered = false;

  @override
  Widget build(BuildContext context) {
    // Whisper mode dragging disabled as requested
    return widget.builder(context, 0.0, 0.0);
  }
}
