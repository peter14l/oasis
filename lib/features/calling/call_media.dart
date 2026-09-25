import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';

enum AudioRoute { earpiece, speaker, bluetooth }

/// Transport port for call media. Production bridges to LiveKit; tests inject
/// fakes (their [connect] simply leaves [room] null — UI shows the waiting
/// state without a room).
///
/// [onChanged] fires when room/participant/track state changes (UI refresh),
/// [onRemoteLeft] fires when the last remote participant leaves.
abstract class CallMedia {
  Room? get room;
  bool get isMuted;
  bool get isVideoOn;
  bool get isScreenSharing;
  AudioRoute get audioRoute;

  VoidCallback? onChanged;
  VoidCallback? onRemoteLeft;

  /// Joins the LiveKit room (requests mic/camera permission, fetches a token).
  Future<void> connect({
    required String roomName,
    required String userId,
    required bool videoEnabled,
  });

  Future<void> disconnect();

  Future<void> setMuted(bool muted);

  Future<void> setVideoEnabled(bool enabled);

  Future<void> setScreenShareEnabled(bool enabled);

  Future<void> setAudioRoute(AudioRoute route);

  Future<void> cycleAudioRoute();

  void dispose();
}
