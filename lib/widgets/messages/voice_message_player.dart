import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class VoiceMessagePlayer extends StatefulWidget {
  final String audioUrl;
  final int? duration;
  final bool isMe;
  final Color color;

  const VoiceMessagePlayer({
    Key? key,
    required this.audioUrl,
    this.duration,
    required this.isMe,
    required this.color,
  }) : super(key: key);

  @override
  _VoiceMessagePlayerState createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isError = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _duration = Duration(seconds: widget.duration ?? 0);
    _initAudioPlayer();
  }

  Future<void> _initAudioPlayer() async {
    try {
      _audioPlayer.onPlayerStateChanged.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state == PlayerState.playing;
          });
        }
      });

      _audioPlayer.onDurationChanged.listen((duration) {
        if (mounted && duration.inSeconds > 0) {
          setState(() {
            _duration = duration;
          });
        }
      });

      _audioPlayer.onPositionChanged.listen((position) {
        if (mounted) {
          setState(() {
            _position = position;
          });
        }
      });

      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _position = Duration.zero; // Reset to start
          });
        }
      });

      // Pre-load the source
      if (widget.audioUrl.isNotEmpty) {
        await _audioPlayer.setSourceUrl(widget.audioUrl);
      }
    } catch (e) {
      debugPrint('Error initializing audio: $e');
      if (mounted) setState(() => _isError = true);
    }
  }

  Future<void> _togglePlayPause() async {
    if (_isError) return;
    
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        if (widget.audioUrl.isEmpty) return;
        await _audioPlayer.play(UrlSource(widget.audioUrl));
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
      if (mounted) setState(() => _isError = true);
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isError) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Text(
              'Audio error',
              style: TextStyle(color: Colors.red[700], fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: widget.isMe 
          ? widget.color.withValues(alpha: 0.15)
          : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
              color: widget.color,
              size: 32,
            ),
            onPressed: _togglePlayPause,
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _formatDuration(_position),
                    style: TextStyle(
                      fontSize: 10,
                      color: widget.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    ' / ' + _formatDuration(_duration),
                    style: TextStyle(
                      fontSize: 10,
                      color: widget.color.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 120, // Slightly wider, fits within the bubble
                height: 3,
                child: LinearProgressIndicator(
                  value: _duration.inSeconds > 0
                      ? (_position.inSeconds / _duration.inSeconds).clamp(0.0, 1.0)
                      : 0,
                  backgroundColor: widget.color.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
