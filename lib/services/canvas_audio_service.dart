import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class CanvasAudioService {
  static final CanvasAudioService _instance = CanvasAudioService._internal();
  factory CanvasAudioService() => _instance;
  CanvasAudioService._internal();

  final List<String> _playlist = [
    'audio/hasin2004-nature-sound-near-river-or-waterfall-247409.mp3',
    'audio/richardmultimedia-birds-and-waterfall-250309.mp3',
    'audio/richardmultimedia-birds-near-waterfall-324855.mp3',
  ];

  final AudioPlayer _player1 = AudioPlayer();
  final AudioPlayer _player2 = AudioPlayer();
  
  int _currentIndex = 0;
  bool _isPlaying = false;
  Timer? _crossfadeTimer;

  Future<void> start() async {
    if (_isPlaying) return;
    _isPlaying = true;
    _currentIndex = 0;
    
    debugPrint('CanvasAudioService: Starting ambient loop');
    await _playNext(isFirst: true);
  }

  Future<void> _playNext({bool isFirst = false}) async {
    if (!_isPlaying) return;

    final currentAsset = _playlist[_currentIndex];
    final nextIndex = (_currentIndex + 1) % _playlist.length;
    final nextAsset = _playlist[nextIndex];

    final activePlayer = _currentIndex % 2 == 0 ? _player1 : _player2;
    final idlePlayer = _currentIndex % 2 == 0 ? _player2 : _player1;

    try {
      // 1. Start current track
      await activePlayer.setSource(AssetSource(currentAsset));
      await activePlayer.setVolume(isFirst ? 1.0 : 1.0);
      await activePlayer.resume();

      // 2. Schedule crossfade
      // We need to know the duration. Since these are assets, we can get it after loading.
      final duration = await activePlayer.getDuration();
      if (duration != null) {
        // Start crossfade 5 seconds before the end
        final crossfadeStart = duration.inMilliseconds - 5000;
        
        _crossfadeTimer?.cancel();
        _crossfadeTimer = Timer(Duration(milliseconds: crossfadeStart), () async {
          if (!_isPlaying) return;
          
          debugPrint('CanvasAudioService: Starting crossfade to next track');
          
          // Fade in idle player with next track
          await idlePlayer.setSource(AssetSource(nextAsset));
          await idlePlayer.setVolume(0.0);
          await idlePlayer.resume();

          // Smooth volume transition (10 steps over 5 seconds)
          for (int i = 1; i <= 10; i++) {
            if (!_isPlaying) break;
            await activePlayer.setVolume(1.0 - (i / 10));
            await idlePlayer.setVolume(i / 10);
            await Future.delayed(const Duration(milliseconds: 500));
          }

          await activePlayer.stop();
          _currentIndex = nextIndex;
          _playNext(); // Recursively loop
        });
      } else {
        // Fallback if duration is unknown: just wait and loop
        activePlayer.onPlayerComplete.listen((_) {
          if (_isPlaying) {
            _currentIndex = nextIndex;
            _playNext();
          }
        });
      }
    } catch (e) {
      debugPrint('CanvasAudioService error: $e');
      // Fallback loop
      Future.delayed(const Duration(seconds: 10), () => _playNext());
    }
  }

  void stop() {
    _isPlaying = false;
    _crossfadeTimer?.cancel();
    _player1.stop();
    _player2.stop();
    debugPrint('CanvasAudioService: Stopped ambient loop');
  }

  void dispose() {
    stop();
    _player1.dispose();
    _player2.dispose();
  }
}
