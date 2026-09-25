import 'package:audio_session/audio_session.dart' as audio_session;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:livekit_client/livekit_client.dart';
import 'package:oasis/core/config/app_config.dart';
import 'package:oasis/core/network/supabase_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:universal_io/io.dart';
import 'call_media.dart';

/// LiveKit-backed [CallMedia]: token fetch, room connect, track toggles,
/// audio route switching (earpiece/speaker/bluetooth) and proximity sensor.
class LiveKitCallMedia extends CallMedia {
  static const MethodChannel _callChannel = MethodChannel('oasis/call');

  final SupabaseClient? _clientOverride;

  LiveKitCallMedia({SupabaseClient? client}) : _clientOverride = client;

  SupabaseClient get _client => _clientOverride ?? SupabaseService().client;

  Room? _room;
  EventsListener<RoomEvent>? _listener;
  AudioRoute _audioRoute = AudioRoute.earpiece;
  bool _isMuted = false;
  bool _isVideoOn = true;
  bool _isScreenSharing = false;

  @override
  Room? get room => _room;

  @override
  bool get isMuted => _isMuted;

  @override
  bool get isVideoOn => _isVideoOn;

  @override
  bool get isScreenSharing => _isScreenSharing;

  @override
  AudioRoute get audioRoute => _audioRoute;

  @override
  Future<void> connect({
    required String roomName,
    required String userId,
    required bool videoEnabled,
  }) async {
    _isMuted = false;
    _isVideoOn = videoEnabled;
    _isScreenSharing = false;
    _audioRoute = AudioRoute.earpiece;

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final permissions = <Permission>[Permission.microphone];
      if (videoEnabled) permissions.add(Permission.camera);
      await permissions.request();
    }

    final token = await _fetchToken(roomName, userId);
    if (token == null) {
      throw StateError('Failed to obtain LiveKit token');
    }

    await _disconnectCurrent();

    final room = Room();
    _room = room;
    _listener = room.createListener()
      ..on<RoomDisconnectedEvent>((_) {
        _teardownRoom();
        onChanged?.call();
      })
      ..on<ParticipantConnectedEvent>((_) => onChanged?.call())
      ..on<ParticipantDisconnectedEvent>((_) {
        if (room.remoteParticipants.isEmpty) {
          onRemoteLeft?.call();
        } else {
          onChanged?.call();
        }
      })
      ..on<TrackSubscribedEvent>((_) => onChanged?.call())
      ..on<TrackUnsubscribedEvent>((_) => onChanged?.call())
      ..on<TrackMutedEvent>((_) => onChanged?.call())
      ..on<TrackUnmutedEvent>((_) => onChanged?.call())
      ..on<LocalTrackPublishedEvent>((_) => onChanged?.call())
      ..on<LocalTrackUnpublishedEvent>((event) {
        if (event.publication.isScreenShare) _isScreenSharing = false;
        onChanged?.call();
      });

    await _configureAudioRoute(_audioRoute);

    await room.connect(
      AppConfig.liveKitUrl,
      token,
      fastConnectOptions: FastConnectOptions(
        microphone: const TrackOption(enabled: true),
        camera: TrackOption(enabled: videoEnabled),
      ),
    );

    _updateProximitySensor();
    onChanged?.call();
  }

  Future<String?> _fetchToken(String roomName, String identity) async {
    try {
      final response = await _client.functions.invoke(
        'generate-livekit-token',
        body: {'roomName': roomName, 'identity': identity},
      );
      if (response.status == 200) {
        return response.data['token'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('[LiveKitCallMedia] token fetch failed: $e');
      return null;
    }
  }

  @override
  Future<void> disconnect() async {
    await _disconnectCurrent();
    _isMuted = false;
    _isScreenSharing = false;
    onChanged?.call();
  }

  Future<void> _disconnectCurrent() async {
    await _teardownRoom();
    _updateProximitySensor();
  }

  Future<void> _teardownRoom() async {
    final room = _room;
    final listener = _listener;
    _room = null;
    _listener = null;
    await listener?.cancelAll();
    if (room != null) {
      await room.disconnect();
      await room.dispose();
    }
    _setProximitySensor(false);
  }

  @override
  Future<void> setMuted(bool muted) async {
    try {
      await _room?.localParticipant?.setMicrophoneEnabled(!muted);
      _isMuted = muted;
    } catch (e) {
      debugPrint('[LiveKitCallMedia] setMuted error: $e');
    }
    onChanged?.call();
  }

  @override
  Future<void> setVideoEnabled(bool enabled) async {
    try {
      await _room?.localParticipant?.setCameraEnabled(enabled);
      _isVideoOn = enabled;
    } catch (e) {
      debugPrint('[LiveKitCallMedia] setVideoEnabled error: $e');
    }
    onChanged?.call();
  }

  @override
  Future<void> setScreenShareEnabled(bool enabled) async {
    try {
      await _room?.localParticipant?.setScreenShareEnabled(enabled);
      _isScreenSharing = enabled;
    } catch (e) {
      debugPrint('[LiveKitCallMedia] setScreenShareEnabled error: $e');
      _isScreenSharing = false;
    }
    onChanged?.call();
  }

  @override
  Future<void> setAudioRoute(AudioRoute route) async {
    await _configureAudioRoute(route);
    _updateProximitySensor();
    onChanged?.call();
  }

  Future<void> _configureAudioRoute(AudioRoute route) async {
    _audioRoute = route;
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;
    try {
      final session = await audio_session.AudioSession.instance;
      switch (route) {
        case AudioRoute.speaker:
          await session.configure(const audio_session.AudioSessionConfiguration(
            avAudioSessionCategory:
                audio_session.AVAudioSessionCategory.playAndRecord,
            avAudioSessionCategoryOptions:
                audio_session.AVAudioSessionCategoryOptions.defaultToSpeaker,
            avAudioSessionMode: audio_session.AVAudioSessionMode.voiceChat,
            androidAudioAttributes:
                const audio_session.AndroidAudioAttributes(
              contentType: audio_session.AndroidAudioContentType.speech,
              usage: audio_session.AndroidAudioUsage.voiceCommunication,
            ),
            androidAudioFocusGainType:
                audio_session.AndroidAudioFocusGainType.gainTransientExclusive,
          ));
          await session.setActive(true);
          await rtc.Helper.setSpeakerphoneOn(true);
          break;
        case AudioRoute.bluetooth:
          await session.configure(audio_session.AudioSessionConfiguration(
            avAudioSessionCategory:
                audio_session.AVAudioSessionCategory.playAndRecord,
            avAudioSessionCategoryOptions: audio_session
                    .AVAudioSessionCategoryOptions.allowBluetooth |
                audio_session.AVAudioSessionCategoryOptions.allowBluetoothA2dp,
            avAudioSessionMode: audio_session.AVAudioSessionMode.voiceChat,
            androidAudioAttributes:
                const audio_session.AndroidAudioAttributes(
              contentType: audio_session.AndroidAudioContentType.speech,
              usage: audio_session.AndroidAudioUsage.voiceCommunication,
            ),
            androidAudioFocusGainType:
                audio_session.AndroidAudioFocusGainType.gainTransientExclusive,
          ));
          await session.setActive(true);
          await rtc.Helper.setSpeakerphoneOnButPreferBluetooth();
          break;
        case AudioRoute.earpiece:
          await session.configure(const audio_session.AudioSessionConfiguration(
            avAudioSessionCategory:
                audio_session.AVAudioSessionCategory.playAndRecord,
            avAudioSessionCategoryOptions:
                audio_session.AVAudioSessionCategoryOptions.none,
            avAudioSessionMode: audio_session.AVAudioSessionMode.voiceChat,
            androidAudioAttributes: audio_session.AndroidAudioAttributes(
              contentType: audio_session.AndroidAudioContentType.speech,
              usage: audio_session.AndroidAudioUsage.voiceCommunication,
            ),
            androidAudioFocusGainType:
                audio_session.AndroidAudioFocusGainType.gainTransientExclusive,
          ));
          await session.setActive(true);
          await rtc.Helper.setSpeakerphoneOn(false);
          break;
      }
    } catch (e) {
      debugPrint('[LiveKitCallMedia] audio route $route failed: $e');
    }
  }

  @override
  Future<void> cycleAudioRoute() async {
    switch (_audioRoute) {
      case AudioRoute.earpiece:
        await setAudioRoute(AudioRoute.speaker);
      case AudioRoute.speaker:
        await setAudioRoute(AudioRoute.bluetooth);
      case AudioRoute.bluetooth:
        await setAudioRoute(AudioRoute.earpiece);
    }
  }

  Future<void> _setProximitySensor(bool enable) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;
    try {
      await _callChannel.invokeMethod('setProximitySensor', {'enable': enable});
    } catch (e) {
      debugPrint('[LiveKitCallMedia] setProximitySensor error: $e');
    }
  }

  void _updateProximitySensor() {
    final enable = _room != null && _audioRoute == AudioRoute.earpiece;
    _setProximitySensor(enable);
  }

  @override
  void dispose() {
    _teardownRoom();
  }
}
