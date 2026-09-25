import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oasis/features/calling/call.dart';
import 'package:oasis/features/calling/call_controller.dart';
import 'package:oasis/features/calling/call_media.dart';
import 'package:oasis/features/profile/domain/models/user_profile_entity.dart';
import 'package:oasis/features/profile/presentation/providers/profile_provider.dart';
import 'add_participant_sheet.dart';
import 'participant_view.dart';

/// Single route for every call state: incoming, active, and unanswered.
///
/// Never auto-accepts (the v2 root bug); accept/decline are explicit taps.
/// Never pushes — CallRouter owns navigation; this screen pops itself when
/// the controller has no call left to show.
class CallScreen extends StatefulWidget {
  const CallScreen({super.key, this.callId});

  /// Route param — kept for deep links; state comes from CallController.
  final String? callId;

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  CallController? _controller;
  bool _hasPopped = false;
  bool _errorShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = context.read<CallController>();
    if (!identical(_controller, controller)) {
      _controller?.removeListener(_onControllerChanged);
      _controller = controller;
      _controller!.addListener(_onControllerChanged);
      _onControllerChanged();
    }
  }

  void _onControllerChanged() {
    if (!mounted || _controller == null) return;
    final state = _controller!.state;
    if (state.error != null && !_errorShown) {
      _errorShown = true;
      final error = state.error!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
        _controller?.clearError();
        _errorShown = false;
      });
    }
    _checkAndAutoPop();
  }

  /// Pops only when there is truly nothing to show and no transition is in
  /// flight (isLoading guards the accept window; isUnanswered keeps the
  /// retry screen up until the user acts).
  void _checkAndAutoPop() {
    if (_hasPopped || _controller == null || !mounted) return;
    final state = _controller!.state;
    if (state.hasCall || state.isLoading || state.isUnanswered) return;
    _hasPopped = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Selector<CallController, ({bool incoming, bool active, bool unanswered, bool loading})>(
          selector: (_, c) => (
            incoming: c.hasIncomingCall && !c.hasActiveCall,
            active: c.hasActiveCall,
            unanswered: c.state.isUnanswered && !c.hasActiveCall,
            loading: c.state.isLoading,
          ),
          builder: (_, s, __) {
            if (s.active) return const _ActiveCallView();
            if (s.incoming) return const _IncomingCallView();
            if (s.unanswered) return const _UnansweredView();
            return const Center(
              child: CircularProgressIndicator(color: Colors.blue),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Incoming: explicit accept / decline (no auto-accept, ever)
// ---------------------------------------------------------------------------

class _IncomingCallView extends StatefulWidget {
  const _IncomingCallView();

  @override
  State<_IncomingCallView> createState() => _IncomingCallViewState();
}

class _IncomingCallViewState extends State<_IncomingCallView> {
  UserProfileEntity? _caller;
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadCaller();
  }

  Future<void> _loadCaller() async {
    try {
      final controller = context.read<CallController>();
      final call = controller.incomingCall;
      if (call != null) {
        final profile =
            await context.read<ProfileProvider>().getProfile(call.callerId);
        if (mounted) setState(() => _caller = profile);
      }
    } catch (_) {
      // Tests run without ProfileProvider; show fallback labels.
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CallController>();
    final call = controller.incomingCall;
    if (call == null) return const SizedBox.shrink();

    final isLoading = controller.state.isLoading;
    final isVideo = call.type == CallType.video;
    final name = _caller?.displayName ??
        _caller?.username ??
        (_loadingProfile ? '...' : 'Unknown');

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        PulsatingParticipant(userId: call.callerId, size: 160),
        const SizedBox(height: 32),
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isVideo ? 'Incoming video call' : 'Incoming voice call',
          style: const TextStyle(color: Colors.white54, fontSize: 16),
        ),
        const SizedBox(height: 64),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _CallActionButton(
              icon: Icons.call_end,
              color: Colors.red,
              label: 'Decline',
              onTap: isLoading ? null : controller.declineCall,
            ),
            _CallActionButton(
              icon: Icons.call,
              color: Colors.green,
              label: 'Accept',
              onTap: isLoading ? null : controller.acceptCall,
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Active call: header + participant view + control bar
// ---------------------------------------------------------------------------

class _ActiveCallView extends StatelessWidget {
  const _ActiveCallView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CallController>();
    final call = controller.activeCall;
    if (call == null) return const SizedBox.shrink();

    return Stack(
      children: [
        const Positioned.fill(child: ParticipantDisplay()),
        Positioned(
          top: 8,
          left: 8,
          right: 8,
          child: _CallHeader(controller: controller),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: _CallControlBar(controller: controller, call: call),
        ),
        if (controller.state.isMinimized)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => controller.toggleMinimize(value: false),
              child: Container(
                color: Colors.black.withValues(alpha: 0.6),
                alignment: Alignment.center,
                child: const Text(
                  'Tap to return to call',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CallHeader extends StatelessWidget {
  const _CallHeader({required this.controller});

  final CallController controller;

  @override
  Widget build(BuildContext context) {
    final call = controller.activeCall;
    if (call == null) return const SizedBox.shrink();
    final connected = call.status == CallStatus.active;

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          onPressed: () => controller.toggleMinimize(),
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              call.type == CallType.video ? 'Video call' : 'Voice call',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              connected
                  ? 'Connected'
                  : (call.status == CallStatus.ringing
                      ? 'Ringing...'
                      : 'Connecting...'),
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        const Spacer(),
        // Deliberately no "end-to-end encrypted" label — PQ-Aura is not
        // implemented; transport is LiveKit DTLS-SRTP only.
        const Padding(
          padding: EdgeInsets.only(right: 8),
          child: Text(
            'LiveKit',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ),
      ],
    );
  }
}

class _CallControlBar extends StatelessWidget {
  const _CallControlBar({required this.controller, required this.call});

  final CallController controller;
  final Call call;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _CallActionButton(
          icon: controller.state.isMuted ? Icons.mic_off : Icons.mic,
          color: controller.state.isMuted ? Colors.red : Colors.white,
          onTap: controller.toggleMute,
        ),
        if (call.type == CallType.video)
          _CallActionButton(
            icon: controller.state.isVideoOn
                ? Icons.videocam
                : Icons.videocam_off,
            color:
                controller.state.isVideoOn ? Colors.white : Colors.red,
            onTap: controller.toggleVideo,
          ),
        _CallActionButton(
          icon: switch (controller.state.audioRoute) {
            AudioRoute.earpiece => Icons.phone_in_talk,
            AudioRoute.speaker => Icons.volume_up,
            AudioRoute.bluetooth => Icons.bluetooth_audio,
          },
          color: Colors.white,
          onTap: controller.cycleAudioRoute,
        ),
        _CallActionButton(
          icon: Icons.person_add,
          color: Colors.white,
          onTap: () => showAddParticipantSheet(context),
        ),
        _CallActionButton(
          icon: Icons.call_end,
          color: Colors.red,
          onTap: controller.hangUp,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Unanswered (caller-side): retry / cancel
// ---------------------------------------------------------------------------

class _UnansweredView extends StatelessWidget {
  const _UnansweredView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CallController>();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.call_missed, color: Colors.red, size: 80),
        const SizedBox(height: 24),
        const Text(
          'No answer',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'The call was not picked up.',
          style: TextStyle(color: Colors.white54, fontSize: 15),
        ),
        const SizedBox(height: 48),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _CallActionButton(
              icon: Icons.close,
              color: Colors.white,
              label: 'Cancel',
              onTap: () {
                controller.clearUnanswered();
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
            ),
            _CallActionButton(
              icon: Icons.refresh,
              color: Colors.green,
              label: 'Try again',
              onTap: controller.retryLastCall,
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared bits
// ---------------------------------------------------------------------------

class _CallActionButton extends StatelessWidget {
  const _CallActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.label,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.white.withValues(alpha: 0.12),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 64,
              height: 64,
              child: Icon(icon, color: color, size: 30),
            ),
          ),
        ),
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              label!,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
      ],
    );
  }
}
