import 'dart:ui' as ui;
import 'package:flutter/material.dart' hide IconButton, Icon, Row, Column, Container, Padding, Center, Stack, Align, Positioned, SizedBox, Expanded, Spacer, GestureDetector;
import 'package:flutter/material.dart' as material;
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:oasis/widgets/dotted_border_painter.dart';
import 'package:oasis/widgets/custom_text_field.dart';
import 'package:oasis/features/messages/presentation/widgets/shared/recording_dot.dart';

/// Chat input area with text field, attachment button, and send/record toggle.
/// Matches the legacy chat_screen.dart input section exactly.
class ChatInputArea extends StatefulWidget {
  const ChatInputArea({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onAttachment,
    required this.onSticker,
    required this.isRecording,
    required this.recordDuration,
    required this.isSending,
    required this.isWhisperMode,
    required this.onToggleRecording,
    this.textNotifier,
    this.backgroundUrl,
    this.textColor,
    this.hintText,
    this.hasAttachment = false,
    this.isDesktop = false,
    this.onPickImage,
    this.onPickVideo,
    this.onPickFile,
    this.onPickAudio,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback onAttachment;
  final VoidCallback onSticker;
  final bool isRecording;
  final int recordDuration;
  final bool isSending;
  final int isWhisperMode;
  final VoidCallback onToggleRecording;
  final ValueListenable<String>? textNotifier;
  final String? backgroundUrl;
  final Color? textColor;
  final String? hintText;
  final bool hasAttachment;
  final bool isDesktop;

  final VoidCallback? onPickImage;
  final VoidCallback? onPickVideo;
  final VoidCallback? onPickFile;
  final VoidCallback? onPickAudio;

  @override
  State<ChatInputArea> createState() => _ChatInputAreaState();
}

class _ChatInputAreaState extends State<ChatInputArea> {
  final fluent.FlyoutController _flyoutController = fluent.FlyoutController();

  @override
  void dispose() {
    _flyoutController.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = material.Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderRadius = material.BorderRadius.circular(32);

    final decoration = material.BoxDecoration(
      color: widget.isDesktop 
          ? material.Colors.black.withValues(alpha: 0.85)
          : colorScheme.surface.withValues(alpha: 0.5),
      borderRadius: borderRadius,
      border: material.Border.all(
        color: material.Colors.white.withValues(alpha: 0.1),
        width: 1.0,
      ),
    );

    // Common recording view
    final Widget recordingView = material.Row(
      children: [
        const material.SizedBox(width: 12),
        const RecordingDot(),
        const material.SizedBox(width: 8),
        material.Text(
          'Recording...',
          style: material.TextStyle(
            color: widget.backgroundUrl != null ? material.Colors.white : material.Colors.red[700],
            fontWeight: material.FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const material.Spacer(),
        material.ValueListenableBuilder<String>(
          valueListenable: widget.textNotifier ?? ValueNotifier(widget.controller.text),
          builder: (context, text, child) {
            final durationText =
                widget.controller.text.isEmpty ? _formatDuration(widget.recordDuration) : '';
            return material.Text(
              durationText,
              style: material.TextStyle(
                color: widget.backgroundUrl != null ? material.Colors.white70 : material.Colors.red[700],
                fontFeatures: [ui.FontFeature.tabularFigures()],
                fontWeight: material.FontWeight.w500,
              ),
            );
          },
        ),
        const material.SizedBox(width: 12),
      ],
    );

    // Send/Mic button builder
    Widget buildActionButton() {
      return material.ValueListenableBuilder<String>(
        valueListenable: widget.textNotifier ?? ValueNotifier(widget.controller.text),
        builder: (context, text, child) {
          final bool isEmptyText = text.trim().isEmpty;
          final bool showMic = isEmptyText && !widget.hasAttachment;

          return material.Container(
            margin: widget.isDesktop ? const material.EdgeInsets.only(right: 4) : null,
            decoration: material.BoxDecoration(
              color:
                  widget.isSending
                      ? colorScheme.onSurface.withValues(alpha: 0.12)
                      : (showMic
                          ? (widget.isRecording ? material.Colors.red : colorScheme.primary)
                          : colorScheme.secondary),
              shape: material.BoxShape.circle,
            ),
            child: material.IconButton(
              onPressed:
                  widget.isSending ? null : (showMic ? widget.onToggleRecording : widget.onSend),
              padding: widget.isDesktop ? const material.EdgeInsets.all(8) : null,
              constraints: widget.isDesktop ? const material.BoxConstraints() : null,
              icon:
                  widget.isSending
                      ? const material.SizedBox(
                        width: 20,
                        height: 20,
                        child: material.CircularProgressIndicator(
                          strokeWidth: 2,
                          color: material.Colors.white,
                        ),
                      )
                      : material.Icon(
                        showMic
                            ? (widget.isRecording ? material.Icons.stop_rounded : material.Icons.mic)
                            : material.Icons.send_rounded,
                        color: material.Colors.white,
                        size: widget.isDesktop ? 22 : null,
                      ),
            ),
          );
        },
      );
    }

    final Widget inputArea = material.Container(
      padding: material.EdgeInsets.symmetric(
        horizontal: widget.isDesktop ? 8 : 4,
        vertical: widget.isDesktop ? 4 : 4,
      ),
      decoration: decoration,
      child: material.Row(
        crossAxisAlignment: widget.isDesktop ? material.CrossAxisAlignment.center : material.CrossAxisAlignment.end,
        children: [
          widget.isDesktop ? 
          fluent.FlyoutTarget(
            controller: _flyoutController,
            child: material.IconButton(
              onPressed: () {
                _flyoutController.showFlyout(
                  autoModeConfiguration: fluent.FlyoutAutoConfiguration(
                    preferredMode: fluent.FlyoutPlacementMode.topCenter,
                  ),
                  barrierDismissible: true,
                  dismissWithEsc: true,
                  builder: (context) {
                    return fluent.MenuFlyout(
                      items: [
                        fluent.MenuFlyoutItem(
                          leading: const material.Icon(material.Icons.image_rounded, size: 20, color: material.Color(0xFF3D8BFF)),
                          text: const material.Text('Photo'),
                          onPressed: () {
                            _flyoutController.close();
                            widget.onPickImage?.call();
                          },
                        ),
                        fluent.MenuFlyoutItem(
                          leading: const material.Icon(material.Icons.videocam_rounded, size: 20, color: material.Color(0xFFFF6B6B)),
                          text: const material.Text('Video'),
                          onPressed: () {
                            _flyoutController.close();
                            widget.onPickVideo?.call();
                          },
                        ),
                        fluent.MenuFlyoutItem(
                          leading: const material.Icon(material.Icons.insert_drive_file_rounded, size: 20, color: material.Color(0xFF51CF66)),
                          text: const material.Text('File'),
                          onPressed: () {
                            _flyoutController.close();
                            widget.onPickFile?.call();
                          },
                        ),
                        fluent.MenuFlyoutItem(
                          leading: const material.Icon(material.Icons.audio_file_rounded, size: 20, color: material.Color(0xFFFFD43B)),
                          text: const material.Text('Audio'),
                          onPressed: () {
                            _flyoutController.close();
                            widget.onPickAudio?.call();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              icon: material.Icon(
                material.Icons.add_circle_outline,
                color: material.Colors.white70,
                size: 24,
              ),
              constraints: const material.BoxConstraints(),
              padding: const material.EdgeInsets.all(8),
            ),
          ) :
          material.IconButton(
            onPressed: widget.onAttachment,
            icon: material.Icon(
              material.Icons.add_circle_outline,
              color: colorScheme.primary,
            ),
          ),
          material.IconButton(
            onPressed: widget.onSticker,
            icon: material.Icon(
              material.Icons.sticky_note_2_outlined,
              color: widget.isDesktop ? material.Colors.white38 : colorScheme.primary.withValues(alpha: 0.6),
              size: widget.isDesktop ? 24 : null,
            ),
            constraints: widget.isDesktop ? const material.BoxConstraints() : null,
            padding: widget.isDesktop ? const material.EdgeInsets.all(8) : null,
            tooltip: 'Stickers & GIFs',
          ),
          const material.SizedBox(width: 4),
          material.Expanded(
            child:
                widget.isRecording
                    ? recordingView
                    : material.CallbackShortcuts(
                      bindings: {
                        const material.SingleActivator(
                          LogicalKeyboardKey.enter,
                          includeRepeats: false,
                        ): () {
                          final keys =
                              HardwareKeyboard.instance.logicalKeysPressed;
                          if (keys.contains(LogicalKeyboardKey.shiftLeft) ||
                              keys.contains(LogicalKeyboardKey.shiftRight)) {
                            return;
                          }
                          if (widget.controller.text.trim().isNotEmpty ||
                              widget.hasAttachment) {
                            widget.onSend();
                          }
                        },
                      },
                      child: CustomTextField(
                        controller: widget.controller,
                        focusNode: widget.focusNode,
                        hint: widget.hintText ?? 'Type a message...',
                        fillColor: material.Colors.transparent,
                        textColor: widget.isDesktop ? material.Colors.white : null,
                        hintColor: widget.isDesktop ? material.Colors.white38 : null,
                        maxLines: widget.isDesktop ? 3 : 2,
                        textCapitalization: material.TextCapitalization.sentences,
                        isDense: true,
                        contentPadding: material.EdgeInsets.symmetric(
                          horizontal: widget.isDesktop ? 4 : 10,
                          vertical: widget.isDesktop ? 8 : 6,
                        ),
                        margin: material.EdgeInsets.zero,
                        border: material.InputBorder.none,
                        enabledBorder: material.InputBorder.none,
                        focusedBorder: material.InputBorder.none,
                      ),
                    ),
          ),
          const material.SizedBox(width: 4),
          material.Padding(
            padding: material.EdgeInsets.only(bottom: widget.isDesktop ? 0 : 2),
            child: buildActionButton(),
          ),
        ],
      ),
    );

    if (widget.isWhisperMode > 0) {
      return material.CustomPaint(
        painter: DottedBorderPainter(
          color: material.Colors.white.withValues(alpha: 0.4),
          strokeWidth: 1.5,
          gap: 4,
          dash: 4,
          borderRadius: borderRadius,
        ),
        child: material.Padding(padding: const material.EdgeInsets.all(4), child: inputArea),
      );
    }

    return inputArea;
  }
}
