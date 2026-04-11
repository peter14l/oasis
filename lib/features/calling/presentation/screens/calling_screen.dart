import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import 'package:oasis/features/calling/presentation/providers/call_provider.dart';
import 'package:oasis/features/calling/domain/models/call_entity.dart';
import 'package:oasis/features/calling/domain/models/call_participant_entity.dart';
import 'package:oasis/features/profile/presentation/providers/profile_provider.dart';
import 'package:oasis/features/profile/domain/models/user_profile_entity.dart';
import 'package:oasis/themes/app_theme.dart';
import 'package:oasis/core/utils/responsive_layout.dart';

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
          if (mounted) {
            setState(() {
              _remoteRenderers[userId] = renderer;
            });
          }
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

    // Determine if we should show the waiting screen
    final isWaiting = state.remoteStreams.isEmpty && 
                     (state.activeCall?.status == CallStatus.pinging || 
                      !state.participants.any((p) => p.userId != (state.localStream?.id ?? '') && p.isJoined));

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Colors.blueGrey.withValues(alpha: 0.2),
              Colors.black,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Participant Grid or Waiting Screen
            if (isWaiting)
              _buildWaitingScreen(callProvider)
            else
              _buildParticipantGrid(callProvider),

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
      ),
    );
  }

  Widget _buildWaitingScreen(CallProvider provider) {
    final state = provider.state;
    final currentUserId = Provider.of<ProfileProvider>(context, listen: false).currentProfile?.id;
    final otherParticipant = state.participants.firstWhere(
      (p) => p.userId != currentUserId,
      orElse: () => state.participants.isNotEmpty ? state.participants.first : CallParticipantEntity(
        id: '', callId: '', userId: '', createdAt: DateTime.now())
    );

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PulsatingParticipant(
            userId: otherParticipant.userId,
            isLocal: false,
            size: 200,
          ),
          const SizedBox(height: 40),
          Text(
            state.activeCall?.status == CallStatus.pinging ? 'Calling...' : 'Waiting for others to join...',
            style: const TextStyle(color: Colors.white70, fontSize: 18, letterSpacing: 1.2),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantGrid(CallProvider provider) {
    final state = provider.state;
    final currentUserId = Provider.of<ProfileProvider>(context, listen: false).currentProfile?.id;
    
    // Remote IDs that have streams
    final remoteIds = state.remoteStreams.keys.toList();
    
    // Total count: 1 local + all remote streams
    final totalCount = remoteIds.length + 1;

    if (totalCount == 1) {
      return _buildVideoTile('You', _localRenderer, isLocal: true, isVideoOn: provider.isVideoOn);
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(4, 100, 4, 120),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: totalCount <= 2 ? 1 : 2,
        childAspectRatio: totalCount <= 2 ? 0.8 : 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildVideoTile('You', _localRenderer, isLocal: true, isVideoOn: provider.isVideoOn);
        }
        final userId = remoteIds[index - 1];
        final renderer = _remoteRenderers[userId];
        final participant = state.participants.firstWhere((p) => p.userId == userId, 
            orElse: () => CallParticipantEntity(
              id: '', callId: '', userId: userId, createdAt: DateTime.now(), isVideoOn: true));
        
        return _buildVideoTile('User ${userId.substring(0, 4)}', renderer, 
            userId: userId, isVideoOn: participant.isVideoOn);
      },
    );
  }

  Widget _buildVideoTile(String name, RTCVideoRenderer? renderer, {
    bool isLocal = false, 
    String? userId, 
    required bool isVideoOn
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (isVideoOn && renderer != null)
            RTCVideoView(
              renderer,
              mirror: isLocal,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            )
          else
            Positioned.fill(
              child: PulsatingParticipant(
                userId: userId, // null for local
                isLocal: isLocal,
              ),
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
    // Show Accept/Decline if it's an incoming call that hasn't been joined
    if (provider.hasIncomingCall && !provider.hasActiveCall) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildControlButton(
            onPressed: provider.endCall, // This will decline as per our update
            icon: Icons.call_end,
            color: Colors.red,
            isLarge: true,
          ),
          const SizedBox(width: 60),
          _buildControlButton(
            onPressed: () {
              final call = provider.incomingCall;
              if (call != null) {
                provider.joinCall(call);
              }
            },
            icon: Icons.call,
            color: Colors.green,
            isLarge: true,
          ),
        ],
      );
    }

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

class PulsatingParticipant extends StatefulWidget {
  final String? userId;
  final bool isLocal;
  final double size;

  const PulsatingParticipant({
    super.key,
    this.userId,
    this.isLocal = false,
    this.size = 100,
  });

  @override
  State<PulsatingParticipant> createState() => _PulsatingParticipantState();
}

class _PulsatingParticipantState extends State<PulsatingParticipant> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  UserProfileEntity? _profile;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profileProvider = context.read<ProfileProvider>();
    if (widget.isLocal) {
      _profile = profileProvider.currentProfile;
    } else if (widget.userId != null && widget.userId!.isNotEmpty) {
      try {
        final profile = await profileProvider.getProfile(widget.userId!);
        if (mounted) {
          setState(() {
            _profile = profile;
          });
        }
      } catch (e) {
        debugPrint('Error loading participant profile: $e');
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: _animation,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.2),
                blurRadius: widget.size / 4,
                spreadRadius: widget.size / 20,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: widget.size / 2,
            backgroundColor: Colors.grey[800],
            backgroundImage: _profile?.avatarUrl != null 
              ? NetworkImage(_profile!.avatarUrl!) 
              : null,
            child: _profile?.avatarUrl == null 
              ? Icon(Icons.person, size: widget.size / 2, color: Colors.white54)
              : null,
          ),
        ),
      ),
    );
  }
}
