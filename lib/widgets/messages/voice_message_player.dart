import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class VoiceMessagePlayer extends StatefulWidget {
  final String audioUrl;
  final int? duration;
  final bool isMe;
  final Color color;

  const VoiceMessagePlayer({
    super.key,
    required this.audioUrl,
    this.duration,
    required this.isMe,
    required this.color,
  });

  @override
  VoiceMessagePlayerState createState() => VoiceMessagePlayerState();
}

class VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription? _playerStateSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _completeSub;

  bool _isPlaying = false;
  bool _isError = false;
  bool _isDragging = false;
  double _playbackSpeed = 1.0;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  final List<double> _speeds = [0.5, 1.0, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _duration = Duration(seconds: widget.duration ?? 0);
    _initAudioPlayer();
  }

  @override
  void didUpdateWidget(VoiceMessagePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioUrl != widget.audioUrl) {
      if (_isPlaying) {
        _audioPlayer.stop().catchError((_) {});
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
      if (_isError) {
        setState(() => _isError = false);
      }
    }
    if (oldWidget.duration != widget.duration &&
        widget.duration != null &&
        widget.duration! > 0) {
      setState(() {
        _duration = Duration(seconds: widget.duration!);
      });
    }
  }

  void _initAudioPlayer() {
    try {
      _playerStateSub = _audioPlayer.onPlayerStateChanged.listen(
        (state) {
          if (mounted) {
            setState(() {
              _isPlaying = state == PlayerState.playing;
            });
          }
        },
        onError: (e) {
          debugPrint('[VoiceMessagePlayer] Player state error: $e');
          if (mounted) {
            setState(() {
              _isPlaying = false;
              _isError = true;
            });
          }
        },
      );

      _durationSub = _audioPlayer.onDurationChanged.listen(
        (duration) {
          if (mounted && duration.inSeconds > 0) {
            setState(() {
              _duration = duration;
            });
          }
        },
        onError: (e) {
          debugPrint('[VoiceMessagePlayer] Duration error: $e');
        },
      );

      _positionSub = _audioPlayer.onPositionChanged.listen(
        (position) {
          if (mounted && !_isDragging) {
            setState(() {
              _position = position;
            });
          }
        },
        onError: (e) {
          debugPrint('[VoiceMessagePlayer] Position error: $e');
        },
      );

      _completeSub = _audioPlayer.onPlayerComplete.listen(
        (_) {
          if (mounted) {
            setState(() {
              _isPlaying = false;
              _position = Duration.zero; // Reset to start
            });
          }
        },
        onError: (e) {
          debugPrint('[VoiceMessagePlayer] Complete error: $e');
          if (mounted) {
            setState(() {
              _isPlaying = false;
            });
          }
        },
      );
    } catch (e) {
      debugPrint('[VoiceMessagePlayer] Error initializing audio player: $e');
      if (mounted) setState(() => _isError = true);
    }
  }

  Future<void> _togglePlayPause() async {
    if (_isError) {
      setState(() => _isError = false);
    }

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        final url = widget.audioUrl.trim();
        if (url.isEmpty) return;

        Source source;
        if (url.startsWith('http://') || url.startsWith('https://')) {
          source = UrlSource(url);
        } else {
          final file = File(url);
          if (!await file.exists() || (await file.length()) == 0) {
            debugPrint('[VoiceMessagePlayer] Audio file missing or empty: $url');
            if (mounted) setState(() => _isError = true);
            return;
          }
          source = DeviceFileSource(url);
        }

        // If we are at the end, restart
        if (_position >= _duration && _duration.inSeconds > 0) {
          await _audioPlayer.seek(Duration.zero);
        }
        await _audioPlayer.setPlaybackRate(_playbackSpeed);
        await _audioPlayer.play(source);
      }
    } catch (e) {
      debugPrint('[VoiceMessagePlayer] Error playing audio: $e');
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _isError = true;
        });
      }
    }
  }

  Future<void> _cycleSpeed() async {
    final currentIndex = _speeds.indexOf(_playbackSpeed);
    final nextIndex = (currentIndex + 1) % _speeds.length;
    final nextSpeed = _speeds[nextIndex];

    setState(() {
      _playbackSpeed = nextSpeed;
    });

    try {
      await _audioPlayer.setPlaybackRate(nextSpeed);
    } catch (e) {
      debugPrint('[VoiceMessagePlayer] Error setting playback rate: $e');
    }
  }

  void _onSeek(double value) {
    try {
      final targetPosition = Duration(seconds: value.toInt());
      _audioPlayer.seek(targetPosition);
    } catch (e) {
      debugPrint('[VoiceMessagePlayer] Error seeking: $e');
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
    _playerStateSub?.cancel();
    _durationSub?.cancel();
    _positionSub?.cancel();
    _completeSub?.cancel();
    _audioPlayer.stop().catchError((_) {});
    _audioPlayer.dispose().catchError((_) {});
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
      padding: const EdgeInsets.only(left: 4, right: 8, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: widget.isMe
            ? widget.color.withValues(alpha: 0.12)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              _isPlaying
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_filled_rounded,
              color: widget.color,
              size: 38,
            ),
            onPressed: _togglePlayPause,
          ),
          const SizedBox(width: 4),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 130, // Slightly reduced to fit speed button
                height: 20,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 12,
                    ),
                    activeTrackColor: widget.color,
                    inactiveTrackColor: widget.color.withValues(alpha: 0.2),
                    thumbColor: widget.color,
                    overlayColor: widget.color.withValues(alpha: 0.1),
                  ),
                  child: Slider(
                    value: _position.inSeconds.toDouble().clamp(
                      0,
                      _duration.inSeconds.toDouble(),
                    ),
                    min: 0,
                    max: _duration.inSeconds > 0
                        ? _duration.inSeconds.toDouble()
                        : 1.0,
                    onChangeStart: (_) => setState(() => _isDragging = true),
                    onChangeEnd: (val) {
                      _onSeek(val);
                      setState(() => _isDragging = false);
                    },
                    onChanged: (val) {
                      setState(() {
                        _position = Duration(seconds: val.toInt());
                      });
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                  style: TextStyle(
                    fontSize: 9,
                    color: widget.color.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          // Speed Control Button
          InkWell(
            onTap: _cycleSpeed,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_playbackSpeed.toString().replaceAll('.0', '')}x',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: widget.color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
