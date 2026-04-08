import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oasis/widgets/messages/voice_message_player.dart';
import 'package:oasis/services/voice_transcript_service.dart';

/// Voice/audio message bubble with transcription support.
class VoiceBubble extends StatefulWidget {
  const VoiceBubble({
    super.key,
    required this.audioUrl,
    required this.duration,
    required this.isMe,
    required this.messageId,
    this.textColor,
  });

  final String audioUrl;
  final int? duration;
  final bool isMe;
  final String messageId;
  final Color? textColor;

  @override
  State<VoiceBubble> createState() => _VoiceBubbleState();
}

class _VoiceBubbleState extends State<VoiceBubble> {
  VoiceTranscript? _transcript;
  bool _isTranscribing = false;

  @override
  void initState() {
    super.initState();
    _loadTranscript();
  }

  Future<void> _loadTranscript() async {
    final service = context.read<VoiceTranscriptService>();
    final transcript = await service.getTranscript(widget.messageId);
    if (mounted) {
      setState(() {
        _transcript = transcript;
      });
    }
  }

  Future<void> _transcribe() async {
    setState(() => _isTranscribing = true);
    try {
      final service = context.read<VoiceTranscriptService>();
      final transcript = await service.transcribeVoiceMessage(
        widget.messageId,
        widget.audioUrl,
      );
      if (mounted) {
        setState(() {
          _transcript = transcript;
          _isTranscribing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTranscribing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transcription failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color =
        widget.textColor ??
        (widget.isMe
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurface);

    return Column(
      crossAxisAlignment:
          widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        VoiceMessagePlayer(
          audioUrl: widget.audioUrl,
          duration: widget.duration,
          isMe: widget.isMe,
          color: color,
        ),
        if (_transcript != null)
          Container(
            margin: const EdgeInsets.only(top: 8, left: 8, right: 8),
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(maxWidth: 250),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _transcript!.text,
                  textDirection: _transcript!.isRTL ? TextDirection.rtl : TextDirection.ltr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color.withValues(alpha: 0.8),
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      _transcript!.language.toUpperCase(),
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: color.withValues(alpha: 0.4),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 12, right: 12),
            child: InkWell(
              onTap: _isTranscribing ? null : _transcribe,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isTranscribing)
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                        ),
                      )
                    else
                      Icon(Icons.translate_rounded, size: 12, color: color.withValues(alpha: 0.5)),
                    const SizedBox(width: 6),
                    Text(
                      _isTranscribing ? 'Transcribing...' : 'Transcribe',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: color.withValues(alpha: 0.5),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
