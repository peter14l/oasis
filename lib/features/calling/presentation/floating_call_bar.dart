import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:provider/provider.dart';
import 'package:oasis/features/calling/call_controller.dart';
import 'participant_view.dart';

/// Draggable minimized-call pill. Only visible while minimized + a call
/// exists; tapping it restores the call route.
class FloatingCallBar extends StatefulWidget {
  const FloatingCallBar({super.key});

  @override
  State<FloatingCallBar> createState() => _FloatingCallBarState();
}

class _FloatingCallBarState extends State<FloatingCallBar> {
  Offset _position = const Offset(20, 100);

  @override
  Widget build(BuildContext context) {
    final isMinimized =
        context.select<CallController, bool>((c) => c.state.isMinimized);
    final hasActiveCall =
        context.select<CallController, bool>((c) => c.hasActiveCall);
    final hasIncomingCall =
        context.select<CallController, bool>((c) => c.hasIncomingCall);

    if (!isMinimized || (!hasActiveCall && !hasIncomingCall)) {
      return const SizedBox.shrink();
    }

    final controller = context.read<CallController>();
    final size = MediaQuery.of(context).size;

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _position += details.delta;
            _position = Offset(
              _position.dx.clamp(16.0, size.width - 136.0),
              _position.dy.clamp(40.0, size.height - 200.0),
            );
          });
        },
        onPanEnd: (details) {
          // Magnetic snap to nearest edge (iOS style)
          final snapLeft = _position.dx < (size.width / 2);
          setState(() {
            _position = Offset(
              snapLeft ? 16.0 : (size.width - 136.0),
              _position.dy.clamp(40.0, size.height - 200.0),
            );
          });
        },
        onTap: () {
          final call = controller.activeCall ?? controller.incomingCall;
          if (call == null) return;
          controller.toggleMinimize(value: false);
          context.pushNamed(
            'active_call',
            pathParameters: {'callId': call.id},
          );
        },
        child: Material(
          elevation: 8,
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Container(
            width: 120,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(
                color: Colors.blue.withValues(alpha: 0.5),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                _buildMiniContent(controller),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: Icon(
                            controller.state.isMuted
                                ? Icons.mic_off
                                : Icons.mic,
                            size: 16,
                            color: Colors.white,
                          ),
                          onPressed: controller.toggleMute,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.call_end,
                            size: 16,
                            color: Colors.red,
                          ),
                          onPressed: controller.hangUp,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniContent(CallController controller) {
    final room = controller.room;
    if (room == null) {
      return _buildPlaceholder(controller);
    }

    final remoteParticipant = room.remoteParticipants.values.firstOrNull;
    if (remoteParticipant != null) {
      final videoTrack =
          remoteParticipant.videoTrackPublications.firstOrNull?.track;
      if (videoTrack != null && !videoTrack.muted) {
        return VideoTrackRenderer(videoTrack, fit: VideoViewFit.cover);
      }
    }

    if (controller.state.isVideoOn) {
      final localVideoTrack = room.localParticipant?.videoTrackPublications
          .firstOrNull
          ?.track;
      if (localVideoTrack != null && !localVideoTrack.muted) {
        return VideoTrackRenderer(localVideoTrack, fit: VideoViewFit.cover);
      }
    }

    return _buildPlaceholder(controller);
  }

  Widget _buildPlaceholder(CallController controller) {
    final call = controller.activeCall ?? controller.incomingCall;
    return Container(
      color: Colors.grey[900],
      child: Center(
        child: PulsatingParticipant(
          userId: call?.callerId,
          isLocal: false,
          size: 60,
        ),
      ),
    );
  }
}
