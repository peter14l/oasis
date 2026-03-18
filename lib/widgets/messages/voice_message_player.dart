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
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _duration = Duration(seconds: widget.duration ?? 0);
    _initAudioPlayer();
  }

  Future<void> _initAudioPlayer() async {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
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
          _position = _duration;
        });
      }
    });
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      if (_position >= _duration) {
        // If at the end, restart from beginning
        await _audioPlayer.seek(Duration.zero);
      }
      await _audioPlayer.play(UrlSource(widget.audioUrl));
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isMe 
          ? widget.color.withValues(alpha: 0.2)
          : Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: widget.color,
            ),
            onPressed: _togglePlayPause,
          ),
          const SizedBox(width: 8),
          Text(
            _formatDuration(_position),
            style: TextStyle(
              fontSize: 12,
              color: widget.color,
            ),
          ),
          const Text(' / '),
          Text(
            _formatDuration(_duration),
            style: TextStyle(
              fontSize: 12,
              color: widget.color.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            height: 4,
            child: LinearProgressIndicator(
              value: _duration.inSeconds > 0
                  ? (_position.inSeconds / _duration.inSeconds).clamp(0.0, 1.0)
                  : 0,
              backgroundColor: widget.color.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(widget.color),
            ),
          ),
        ],
      ),
    );
  }
}
