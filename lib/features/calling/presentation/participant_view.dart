import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:provider/provider.dart';
import 'package:oasis/features/calling/call.dart';
import 'package:oasis/features/calling/call_controller.dart';
import 'package:oasis/features/profile/domain/models/user_profile_entity.dart';
import 'package:oasis/features/profile/presentation/providers/profile_provider.dart';

/// Full-screen participant layout: waiting state, 1:1 tiles, grid, and
/// screen-share view. Reads room state from [CallController].
class ParticipantDisplay extends StatelessWidget {
  const ParticipantDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final room = context.select<CallController, Room?>((c) => c.state.room);

    if (room == null) return const WaitingScreen();

    final localParticipant = room.localParticipant;
    final List<RemoteParticipant> remoteParticipants =
        room.remoteParticipants.values.toList();

    remoteParticipants.sort((a, b) {
      if (a.isSpeaking && !b.isSpeaking) return -1;
      if (!a.isSpeaking && b.isSpeaking) return 1;
      return a.joinedAt.compareTo(b.joinedAt);
    });

    final List<Participant> allParticipants = [
      if (localParticipant != null) localParticipant,
      ...remoteParticipants,
    ];

    if (allParticipants.length <= 1) return const WaitingScreen();

    Participant? screenSharer;
    for (final p in allParticipants) {
      if (p.isScreenShareEnabled()) {
        screenSharer = p;
        break;
      }
    }

    if (screenSharer != null) {
      return ScreenShareLayout(
        screenSharer: screenSharer,
        otherParticipants:
            allParticipants.where((p) => p != screenSharer).toList(),
      );
    }

    if (allParticipants.length == 2) {
      return Column(
        children: [
          Expanded(
            child: ParticipantTile(
              participant: allParticipants[0],
              isLocal: allParticipants[0] is LocalParticipant,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ParticipantTile(
              participant: allParticipants[1],
              isLocal: allParticipants[1] is LocalParticipant,
            ),
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        final crossAxisCount = isLandscape
            ? (allParticipants.length <= 4 ? 2 : 3)
            : (allParticipants.length <= 2 ? 1 : 2);

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(8, 100, 8, 120),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: isLandscape ? 1.5 : 0.8,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: allParticipants.length,
          itemBuilder: (context, index) {
            final p = allParticipants[index];
            return ParticipantTile(
              key: ValueKey(p.sid),
              participant: p,
              isLocal: p is LocalParticipant,
            );
          },
        );
      },
    );
  }
}

/// Avatar + status shown before the other participant joins.
class WaitingScreen extends StatelessWidget {
  const WaitingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Call? call = context.select<CallController, Call?>(
      (c) => c.state.activeCall ?? c.state.incomingCall,
    );
    final currentUserId = _currentProfileId(context);
    final String? otherUserId = call == null
        ? null
        : (call.callerId == currentUserId ? call.receiverId : call.callerId);

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
            key: ValueKey('pulsating_$otherUserId'),
            userId: otherUserId,
            isLocal: false,
            size: 200,
          ),
          const SizedBox(height: 40),
          Text(
            statusText,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 18,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

String? _currentProfileId(BuildContext context) {
  try {
    return context.read<ProfileProvider>().currentProfile?.id;
  } catch (_) {
    return null;
  }
}

class ScreenShareLayout extends StatelessWidget {
  final Participant screenSharer;
  final List<Participant> otherParticipants;

  const ScreenShareLayout({
    super.key,
    required this.screenSharer,
    required this.otherParticipants,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ParticipantTile(
            participant: screenSharer,
            isLocal: screenSharer is LocalParticipant,
            useScreenShare: true,
          ),
        ),
        Positioned(
          top: 100,
          right: 16,
          bottom: 120,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: otherParticipants
                  .map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SizedBox(
                        width: 120,
                        height: 160,
                        child: ParticipantTile(
                          participant: p,
                          isLocal: p is LocalParticipant,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class ParticipantTile extends StatefulWidget {
  final Participant participant;
  final bool isLocal;
  final bool useScreenShare;

  const ParticipantTile({
    super.key,
    required this.participant,
    required this.isLocal,
    this.useScreenShare = false,
  });

  @override
  State<ParticipantTile> createState() => _ParticipantTileState();
}

class _ParticipantTileState extends State<ParticipantTile> {
  UserProfileEntity? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void didUpdateWidget(ParticipantTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.participant != widget.participant) _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final identity = widget.participant.identity;
      final profile =
          await context.read<ProfileProvider>().getProfile(identity);
      if (mounted) setState(() => _profile = profile);
    } catch (e) {
      debugPrint('[ParticipantTile] profile load failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _profile?.displayName ??
        _profile?.username ??
        (widget.isLocal ? 'You' : 'Remote User');

    TrackPublication? videoPub;
    if (widget.useScreenShare) {
      videoPub = widget.participant.videoTrackPublications
          .where((e) => e.isScreenShare)
          .firstOrNull;
    } else {
      videoPub = widget.participant.videoTrackPublications
          .where((e) => !e.isScreenShare)
          .firstOrNull;
    }

    final isVideoEnabled =
        (videoPub?.subscribed ?? false) && !(videoPub?.muted ?? false);
    final videoTrack = videoPub?.track;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: widget.participant.isSpeaking
            ? Border.all(color: Colors.blue, width: 2)
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (videoTrack != null &&
              videoTrack is VideoTrack &&
              isVideoEnabled)
            VideoTrackRenderer(videoTrack, fit: VideoViewFit.contain)
          else
            Positioned.fill(
              child: Container(
                color: Colors.grey[900],
                child: PulsatingParticipant(
                  userId: widget.participant.identity,
                  isLocal: widget.isLocal,
                  size: 80,
                ),
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.participant.isSpeaking)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(Icons.mic, color: Colors.blue, size: 12),
                    ),
                  Text(
                    name,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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

class _PulsatingParticipantState extends State<PulsatingParticipant>
    with SingleTickerProviderStateMixin {
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
    try {
      final provider = context.read<ProfileProvider>();
      if (widget.isLocal) {
        _profile = provider.currentProfile;
      } else if (widget.userId != null && widget.userId!.isNotEmpty) {
        final profile = await provider.getProfile(widget.userId!);
        if (mounted) setState(() => _profile = profile);
        return;
      }
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('[PulsatingParticipant] profile load failed: $e');
      if (mounted) setState(() {});
    }
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
                ? CachedNetworkImageProvider(_profile!.avatarUrl!)
                : null,
            child: _profile?.avatarUrl == null
                ? Icon(
                    Icons.person,
                    size: widget.size / 2,
                    color: Colors.white54,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
