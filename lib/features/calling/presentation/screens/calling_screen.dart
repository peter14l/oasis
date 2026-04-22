import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import 'package:oasis/features/calling/presentation/providers/call_provider.dart';
import 'package:oasis/features/calling/domain/models/call_entity.dart';
import 'package:oasis/features/profile/presentation/providers/profile_provider.dart';
import 'package:oasis/features/profile/domain/models/user_profile_entity.dart';
import 'package:oasis/themes/app_theme.dart';
import 'package:oasis/core/utils/responsive_layout.dart';

class CallingScreen extends StatefulWidget {
  final String? callId;
  final bool isIncoming;

  const CallingScreen({
    super.key,
    this.callId,
    this.isIncoming = false,
  });

  @override
  State<CallingScreen> createState() => _CallingScreenState();
}

class _CallingScreenState extends State<CallingScreen> {
  bool _isCallDataTimeout = false;

  @override
  void initState() {
    super.initState();

    if (widget.isIncoming) {
      // Wait for up to 10 seconds for the call data to arrive via Realtime
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted && !context.read<CallProvider>().hasIncomingCall && !context.read<CallProvider>().hasActiveCall) {
          setState(() {
            _isCallDataTimeout = true;
          });
        }
      });
    }

    // Listen for errors from the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CallProvider>().addListener(_handleProviderUpdate);
    });
  }

  void _handleProviderUpdate() {
    if (!mounted) return;
    final error = context.read<CallProvider>().state.error;
    if (error != null) {
      _showError(error);
      context.read<CallProvider>().clearError();
    }
  }

  @override
  void dispose() {
    // Note: Provider listeners don't always need manual removal if the provider
    // is scoped to the screen, but since this might be a global provider, we remove it.
    try {
      context.read<CallProvider>().removeListener(_handleProviderUpdate);
    } catch (_) {}
    super.dispose();
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final callProvider = context.watch<CallProvider>();
    final state = callProvider.state;

    // Automatically pop when the call ends or if we timed out waiting for call data
    final isWaitingForIncomingCall = widget.isIncoming && !callProvider.hasActiveCall && !callProvider.hasIncomingCall && !_isCallDataTimeout;
    
    if (!isWaitingForIncomingCall && !callProvider.hasActiveCall && !callProvider.hasIncomingCall) {
      debugPrint('[CallingScreen] No active or incoming call, popping screen');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Call ended',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    }
    
    // Determine if we should show the waiting screen
    final isWaiting = state.remoteStreams.isEmpty;

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
    final call = state.activeCall ?? state.incomingCall;
    
    final otherUserId = call?.callerId == currentUserId ? call?.receiverId : call?.callerId;
    
    String statusText;
    if (call?.status == CallStatus.ringing) {
      statusText = call?.callerId == currentUserId ? 'Calling...' : 'Incoming...';
    } else {
      statusText = 'Connecting...';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PulsatingParticipant(
            userId: otherUserId,
            isLocal: false,
            size: 200,
          ),
          const SizedBox(height: 40),
          Text(
            statusText,
            style: const TextStyle(color: Colors.white70, fontSize: 18, letterSpacing: 1.2),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantGrid(CallProvider provider) {
    final state = provider.state;
    final remoteIds = state.remoteStreams.keys.toList();
    final totalCount = remoteIds.length + 1;

    if (totalCount == 1) {
      return _buildVideoTile('You', state.localRenderer, isLocal: true, isVideoOn: provider.isVideoOn);
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
          return _buildVideoTile('You', state.localRenderer, isLocal: true, isVideoOn: provider.isVideoOn);
        }
        final userId = remoteIds[index - 1];
        final renderer = state.remoteRenderers[userId];
        
        return _buildVideoTile('Remote User', renderer, 
            userId: userId, isVideoOn: true); // In V2 we can refine video state per user if needed
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
                userId: userId,
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
    if (widget.isIncoming && !provider.hasIncomingCall && !provider.hasActiveCall) {
      return const SizedBox.shrink();
    }

    if (provider.hasIncomingCall && !provider.hasActiveCall) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildControlButton(
            onPressed: () {
              final call = provider.incomingCall;
              final userId = context.read<ProfileProvider>().currentProfile?.id;
              if (call != null && userId != null) {
                provider.declineCall(call.id, userId);
              }
            },
            icon: Icons.call_end,
            color: Colors.red,
            isLarge: true,
          ),
          const SizedBox(width: 60),
          _buildControlButton(
            onPressed: () {
              final call = provider.incomingCall;
              if (call != null) {
                provider.acceptCall(call);
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
          onPressed: () {
            provider.toggleMinimize(value: true);
            Navigator.pop(context);
          },
          icon: Icons.close_fullscreen_rounded,
          color: Colors.white24,
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
