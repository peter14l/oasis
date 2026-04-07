import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:oasis/widgets/dotted_border_painter.dart';
import 'package:oasis/features/messages/presentation/widgets/shared/recording_dot.dart';

/// Chat input area with text field, attachment button, and send/record toggle.
/// Matches the legacy chat_screen.dart input section exactly.
class ChatInputArea extends StatelessWidget {
  const ChatInputArea({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onAttachment,
    required this.isRecording,
    required this.recordDuration,
    required this.isSending,
    required this.isWhisperMode,
    required this.onToggleRecording,
    this.textNotifier,
    this.backgroundUrl,
    this.textColor,
    this.hintText,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback onAttachment;
  final bool isRecording;
  final int recordDuration;
  final bool isSending;
  final int isWhisperMode;
  final VoidCallback onToggleRecording;
  final ValueListenable<String>? textNotifier;
  final String? backgroundUrl;
  final Color? textColor;
  final String? hintText;

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderRadius = BorderRadius.circular(32);

    final inputTextColor =
        textColor ??
        (backgroundUrl != null ? Colors.white : colorScheme.onSurface);
    final inputHintColor = (textColor ??
            (backgroundUrl != null ? Colors.white : colorScheme.onSurface))
        .withValues(alpha: 0.5);

    final decoration = BoxDecoration(
      color: colorScheme.surface.withValues(alpha: 0.5),
      borderRadius: borderRadius,
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.2),
        width: 1.0,
      ),
    );

    final Widget inputContainer = Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: decoration,
      child: Row(
        children: [
          IconButton(
            onPressed: onAttachment,
            icon: Icon(Icons.add_circle_outline, color: colorScheme.primary),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Custom Stickers are coming soon to Oasis Pro!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: Icon(Icons.sticky_note_2_outlined, color: colorScheme.primary.withValues(alpha: 0.6)),
            tooltip: 'Stickers (Coming Soon)',
          ),
          const SizedBox(width: 4),
          Expanded(
            child:
                isRecording
                    ? Row(
                      children: [
                        const SizedBox(width: 12),
                        const RecordingDot(),
                        const SizedBox(width: 8),
                        Text(
                          'Recording...',
                          style: TextStyle(
                            color:
                                backgroundUrl != null
                                    ? Colors.white
                                    : Colors.red[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        ValueListenableBuilder<String>(
                          valueListenable:
                              textNotifier ?? ValueNotifier(controller.text),
                          builder: (context, text, child) {
                            final durationText =
                                controller.text.isEmpty ? _formatDuration(recordDuration) : '';
                            return Text(
                              durationText,
                              style: TextStyle(
                                color:
                                    backgroundUrl != null
                                        ? Colors.white70
                                        : Colors.red[700],
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                      ],
                    )
                    : CallbackShortcuts(
                      bindings: {
                        const SingleActivator(
                          LogicalKeyboardKey.enter,
                          includeRepeats: false,
                        ): () {
                          final keys =
                              ServicesBinding
                                  .instance
                                  .keyboard
                                  .logicalKeysPressed;
                          if (keys.contains(LogicalKeyboardKey.shiftLeft) ||
                              keys.contains(LogicalKeyboardKey.shiftRight)) {
                            return;
                          }
                          if (controller.text.trim().isNotEmpty) {
                            onSend();
                          }
                        },
                      },
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        style: TextStyle(color: inputTextColor),
                        decoration: InputDecoration(
                          hintText: hintText ?? 'Type a message...',
                          hintStyle: TextStyle(color: inputHintColor),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                        ),
                        minLines: 1,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) {
                          if (controller.text.trim().isNotEmpty) {
                            onSend();
                          }
                        },
                      ),
                    ),
          ),
          const SizedBox(width: 8),
          ValueListenableBuilder<String>(
            valueListenable: textNotifier ?? ValueNotifier(controller.text),
            builder: (context, text, child) {
              final bool isEmpty = text.trim().isEmpty;
              return Container(
                decoration: BoxDecoration(
                  color:
                      isSending
                          ? colorScheme.onSurface.withValues(alpha: 0.12)
                          : (isRecording ? Colors.red : colorScheme.primary),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed:
                      isSending ? null : (isEmpty ? onToggleRecording : onSend),
                  icon:
                      isSending
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : Icon(
                            isEmpty
                                ? (isRecording ? Icons.stop_rounded : Icons.mic)
                                : Icons.send_rounded,
                            color: Colors.white,
                          ),
                ),
              );
            },
          ),
        ],
      ),
    );

    if (isWhisperMode > 0) {
      return CustomPaint(
        painter: DottedBorderPainter(
          color: Colors.white.withValues(alpha: 0.4),
          strokeWidth: 1.5,
          gap: 4,
          dash: 4,
          borderRadius: borderRadius,
        ),
        child: Padding(padding: const EdgeInsets.all(4), child: inputContainer),
      );
    }

    return inputContainer;
  }
}
