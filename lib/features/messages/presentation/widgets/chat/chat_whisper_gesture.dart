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
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragStart: (_) {
        setState(() {
          _dragProgress = 0.0;
          _dragOffset = 0.0;
          _triggered = false;
        });
      },
      onVerticalDragUpdate: (details) {
        final rawDelta = -details.delta.dy;
        if (rawDelta <= 0 && _dragOffset == 0) return;
        
        setState(() {
          _dragOffset = (_dragOffset + rawDelta).clamp(0.0, widget.dragThreshold);
          _dragProgress = _dragOffset / widget.dragThreshold;
        });

        if (_dragProgress >= 1.0 && !_triggered) {
          _triggered = true;
          HapticUtils.heavyImpact();
          widget.onWhisperToggle();
        }
      },
      onVerticalDragEnd: (_) {
        setState(() {
          _dragProgress = 0.0;
          _dragOffset = 0.0;
          _triggered = false;
        });
      },
      onVerticalDragCancel: () {
        setState(() {
          _dragProgress = 0.0;
          _dragOffset = 0.0;
          _triggered = false;
        });
      },
      child: widget.builder(context, _dragProgress, _dragOffset),
    );
  }
}
