import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import 'package:oasis/features/calling/presentation/providers/call_provider.dart';
import 'package:oasis/features/calling/domain/models/call_entity.dart';
import 'package:oasis/themes/app_theme.dart';

class CallingScreen extends StatefulWidget {
  const CallingScreen({super.key});

  @override
  State<CallingScreen> createState() => _CallingScreenState();
}

class _CallingScreenState extends State<CallingScreen> {
  bool _isInitialized = false;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final Map<String, RTCVideoRenderer> _remoteRenderers = {};

  @override
  void initState() {
    super.initState();
    _initRenderers();
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    for (var renderer in _remoteRenderers.values) {
      renderer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final callProvider = context.watch<CallProvider>();
    final state = callProvider.state;

    // Automatically pop when the call ends
    if (!callProvider.hasActiveCall && !callProvider.hasIncomingCall) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });
      return const Scaffold(backgroundColor: Colors.black);
    }
    if (_isInitialized && state.localStream != null && _localRenderer.srcObject != state.localStream) {
      _localRenderer.srcObject = state.localStream;
    }

    state.remoteStreams.forEach((userId, stream) {
      if (!_remoteRenderers.containsKey(userId)) {
        final renderer = RTCVideoRenderer();
        renderer.initialize().then((_) {
          renderer.srcObject = stream;
          setState(() {
            _remoteRenderers[userId] = renderer;
          });
        });
      } else if (_remoteRenderers[userId]!.srcObject != stream) {
        _remoteRenderers[userId]!.srcObject = stream;
      }
    });

    // Remove stale renderers
    _remoteRenderers.removeWhere((userId, renderer) {
      if (!state.remoteStreams.containsKey(userId)) {
        renderer.dispose();
        return true;
      }
      return false;
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Participant Grid
          _buildParticipantGrid(state),

          // Control Bar
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: _buildControlBar(callProvider),
          ),

          // Call Info
          Positioned(
            top: 60,
            left: 20,
            child: _buildCallHeader(state),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantGrid(CallState state) {
    final participants = _remoteRenderers.entries.toList();
    final totalCount = participants.length + 1; // +1 for local

    if (totalCount == 1) {
      return RTCVideoView(_localRenderer, mirror: true, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover);
    }

    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: totalCount <= 2 ? 1 : 2,
        childAspectRatio: totalCount <= 2 ? 0.7 : 1,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildVideoTile('You', _localRenderer, isLocal: true);
        }
        final peer = participants[index - 1];
        return _buildVideoTile('User ${peer.key.substring(0, 4)}', peer.value);
      },
    );
  }

  Widget _buildVideoTile(String name, RTCVideoRenderer renderer, {bool isLocal = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          RTCVideoView(
            renderer,
            mirror: isLocal,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          ),
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                name,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlBar(CallProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildControlButton(
          onPressed: provider.toggleMute,
          icon: provider.isMuted ? Icons.mic_off : Icons.mic,
          color: provider.isMuted ? Colors.red : Colors.white24,
        ),
        const SizedBox(width: 20),
        _buildControlButton(
          onPressed: provider.toggleVideo,
          icon: provider.isVideoOn ? Icons.videocam : Icons.videocam_off,
          color: provider.isVideoOn ? Colors.white24 : Colors.red,
        ),
        const SizedBox(width: 20),
        _buildControlButton(
          onPressed: provider.toggleScreenShare,
          icon: provider.isScreenSharing ? Icons.screen_share : Icons.stop_screen_share,
          color: provider.isScreenSharing ? Colors.green : Colors.white24,
        ),
        const SizedBox(width: 20),
        _buildControlButton(
          onPressed: provider.endCall,
          icon: Icons.call_end,
          color: Colors.red,
          isLarge: true,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required VoidCallback onPressed,
    required IconData icon,
    required Color color,
    bool isLarge = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        iconSize: isLarge ? 32 : 24,
        padding: EdgeInsets.all(isLarge ? 16 : 12),
      ),
    );
  }

  Widget _buildCallHeader(CallState state) {
    final call = state.activeCall ?? state.incomingCall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          call?.type == CallType.video ? 'Video Call' : 'Voice Call',
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Row(
          children: [
            Icon(Icons.lock, color: Colors.green, size: 14),
            SizedBox(width: 4),
            Text(
              'End-to-end encrypted',
              style: TextStyle(color: Colors.green, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}
