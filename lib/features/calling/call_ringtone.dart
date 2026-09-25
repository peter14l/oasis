import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Local ring/ringback audio port. Production plays the bundled asset;
/// tests inject fakes.
abstract class CallRingtone {
  /// Play on loop (incoming ring for callee, ringback for caller).
  Future<void> play();

  Future<void> stop();

  void dispose() {}
}

/// Plays the bundled ringtone on loop (incoming ring / outgoing ringback).
class AssetRingtone implements CallRingtone {
  AudioPlayer? _player;
  bool _playing = false;

  @override
  Future<void> play() async {
    if (kIsWeb || _playing) return;
    _playing = true;
    try {
      final player = _player ??= AudioPlayer();
      _configureAudioContext(player);
      await player.setReleaseMode(ReleaseMode.loop);
      await player.stop();
      await player.play(AssetSource('audio/standardringtone.mp3'));
    } catch (e) {
      debugPrint('[AssetRingtone] play failed: $e');
      _playing = false;
    }
  }

  @override
  Future<void> stop() async {
    _playing = false;
    try {
      await _player?.stop();
    } catch (_) {}
  }

  /// Route the ringtone through the voice-signalling path so it follows the
  /// active output device (Bluetooth headset etc.) instead of blasting on
  /// every output at once.
  void _configureAudioContext(AudioPlayer player) {
    if (kIsWeb) return;
    try {
      player.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            usageType: AndroidUsageType.voiceCommunicationSignalling,
            contentType: AndroidContentType.sonification,
            audioFocus: AndroidAudioFocus.gainTransientExclusive,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playAndRecord,
            options: const {
              AVAudioSessionOptions.allowBluetooth,
              AVAudioSessionOptions.allowBluetoothA2DP,
            },
          ),
        ),
      );
    } catch (e) {
      debugPrint('[AssetRingtone] setAudioContext unsupported: $e');
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    _player = null;
    _playing = false;
  }
}
