import 'package:universal_io/io.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:oasis_v2/providers/canvas_provider.dart';
import 'package:oasis_v2/providers/profile_provider.dart';
import 'package:oasis_v2/models/canvas_item.dart';
import 'package:oasis_v2/widgets/canvas/starry_night_background.dart';
import 'package:oasis_v2/widgets/canvas/glowing_note.dart';
import 'package:oasis_v2/widgets/canvas/infinite_card_stack.dart';
import 'package:oasis_v2/widgets/canvas/timeline_scrubber.dart';
import 'package:oasis_v2/widgets/canvas/pulse_ripple.dart';
import 'package:oasis_v2/widgets/canvas/voice_memo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oasis_v2/services/supabase_service.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oasis_v2/services/canvas_service.dart';
import 'package:oasis_v2/widgets/share_sheet.dart';
import 'package:oasis_v2/services/canvas_audio_service.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:oasis_v2/services/notification_service.dart';

class _PulseData {
  final String id;
  final Offset position;
  _PulseData({required this.id, required this.position});
}

class TimelineCanvasScreen extends StatefulWidget {
  final String canvasId;
  const TimelineCanvasScreen({super.key, required this.canvasId});

  @override
  State<TimelineCanvasScreen> createState() => _TimelineCanvasScreenState();
}

class _TimelineCanvasScreenState extends State<TimelineCanvasScreen> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;
  final List<_PulseData> _pulses = [];
  RealtimeChannel? _pulseChannel;
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isMapMode = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    CanvasAudioService().start();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final currentUserId = context.read<ProfileProvider>().currentProfile?.id;
      if (currentUserId != null) {
        // Auto-join to ensure the user is in canvas_members for RLS and sync
        await context.read<CanvasProvider>().joinCanvas(widget.canvasId, currentUserId);
      }
      if (mounted) {
        final canvasProvider = context.read<CanvasProvider>();
        canvasProvider.openCanvas(widget.canvasId);
        _setupPulseChannel();
        
        // Send Pulse Notification to other members
        final canvas = canvasProvider.activeCanvas;
        if (canvas != null && currentUserId != null) {
          NotificationService().sendPulseNotification(
            canvasId: canvas.id,
            canvasTitle: canvas.title,
            actorId: currentUserId,
            memberIds: canvas.memberIds,
          );
        }
      }
    });
  }

  Future<void> _deleteCanvas() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Canvas'),
        content: const Text('Are you sure you want to permanently delete this canvas and all its memories? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<CanvasProvider>().deleteCanvas(widget.canvasId);
      if (success && mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Canvas deleted')));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete canvas')));
      }
    }
  }

  void _leaveCanvas() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Canvas?'),
        content: const Text('You will no longer be able to see or contribute to this canvas unless invited back.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<CanvasProvider>().leaveCanvas(widget.canvasId);
      if (success && mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You left the canvas')));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to leave canvas')));
      }
    }
  }

  void _setupPulseChannel() {
    final supabase = SupabaseService().client;
    _pulseChannel = supabase.channel('canvas_pulses:${widget.canvasId}');
    
    _pulseChannel!.onBroadcast(
      event: 'pulse',
      callback: (payload) {
        if (mounted) {
          final x = (payload['x'] as num).toDouble();
          final y = (payload['y'] as num).toDouble();
          _triggerLocalPulse(Offset(x, y));
        }
      },
    ).subscribe();
  }

  void _triggerLocalPulse(Offset position) {
    final pulse = _PulseData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      position: position,
    );
    setState(() => _pulses.add(pulse));
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _pulses.remove(pulse));
    });
  }

  void _sendPulse(Offset globalPosition) {
    _triggerLocalPulse(globalPosition);
    if (_pulseChannel != null) {
      _pulseChannel!.sendBroadcastMessage(
        event: 'pulse',
        payload: {'x': globalPosition.dx, 'y': globalPosition.dy},
      );
    }
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _audioRecorder.dispose();
    CanvasAudioService().stop();
    if (_pulseChannel != null) {
      SupabaseService().client.removeChannel(_pulseChannel!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CanvasProvider>();
    final canvas = provider.activeCanvas;
    final currentUserId = context.read<ProfileProvider>().currentProfile?.id;
    final isOwner = canvas?.createdBy == currentUserId;

    return Scaffold(
      body: StarryNightBackground(
        scrollOffset: _scrollOffset,
        child: GestureDetector(
          onLongPressStart: (details) => _sendPulse(details.localPosition),
          child: Stack(
            children: [
              if (_isMapMode)
                _buildMapMode(provider)
              else
                CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverAppBar(
                      floating: true,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      leading: IconButton(
                        icon: const Icon(FluentIcons.chevron_left_24_regular, color: Colors.white),
                        onPressed: () => context.pop(),
                      ),
                      title: Text(
                        canvas?.title ?? 'Our Canvas',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      centerTitle: true,
                      actions: [
                        IconButton(
                          icon: Icon(
                            _isMapMode ? FluentIcons.list_24_regular : FluentIcons.glance_24_regular, 
                            color: Colors.white,
                          ),
                          onPressed: () => setState(() => _isMapMode = !_isMapMode),
                          tooltip: _isMapMode ? 'Switch to Timeline' : 'Switch to Spatial Map',
                        ),
                        IconButton(
                          icon: const Icon(FluentIcons.people_add_24_regular, color: Colors.white),
                          onPressed: () {
                            if (canvas != null) {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => ShareSheet(
                                  title: 'Share Canvas',
                                  payload: '[INVITE:canvas:${canvas.id}:${canvas.title}]',
                                ),
                              );
                            }
                          },
                          tooltip: 'Invite Member',
                        ),
                        if (isOwner)
                          IconButton(
                            icon: const Icon(FluentIcons.delete_24_regular, color: Colors.redAccent),
                            onPressed: _deleteCanvas,
                            tooltip: 'Delete Canvas',
                          )
                        else
                          IconButton(
                            icon: const Icon(FluentIcons.arrow_exit_20_regular, color: Colors.redAccent),
                            onPressed: _leaveCanvas,
                            tooltip: 'Leave Canvas',
                          ),
                      ],
                    ),

                    if (provider.isLoading)
                      const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator(color: Colors.white)),
                      )
                    else if (provider.activeItems.isEmpty)
                      SliverFillRemaining(
                        child: _buildEmptyState(),
                      )
                    else
                      ..._buildTimelineSlivers(provider.activeItems),
                      
                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  ],
                ),

              if (provider.activeItems.isNotEmpty && !_isMapMode)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: TimelineScrubber(
                      items: provider.activeItems,
                      scrollController: _scrollController,
                    ),
                  ),
                ),

              ..._pulses.map((p) => PulseRipple(
                    key: ValueKey(p.id),
                    position: p.position,
                    color: Colors.white,
                  )),

              ..._buildPresenceAvatars(provider),
            ],
          ),
        ),
      ),
      floatingActionButton: _TimelineAddItemTray(
        onAddText: () => _showAddNote(context),
        onAddPhoto: () => _pickAndUploadPhoto(),
        onAddVoice: () => _showVoiceRecorder(context),
        onAddSticker: () => _showStickerPicker(context),
        onAddMilestone: () => _showAddMilestone(context),
      ),
    );
  }

  List<Widget> _buildTimelineSlivers(List<CanvasItem> items) {
    final sortedItems = List<CanvasItem>.from(items)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final List<dynamic> timelineGroups = [];
    for (int i = 0; i < sortedItems.length; i++) {
      final item = sortedItems[i];
      if (item.type == CanvasItemType.photo) {
        final List<CanvasItem> stack = [item];
        while (i + 1 < sortedItems.length && 
               sortedItems[i+1].type == CanvasItemType.photo &&
               item.createdAt.difference(sortedItems[i+1].createdAt).inHours.abs() < 1) {
          stack.add(sortedItems[++i]);
        }
        timelineGroups.add(stack);
      } else {
        timelineGroups.add(item);
      }
    }

    final List<Widget> slivers = [];
    String? currentMonth;

    for (var group in timelineGroups) {
      final firstItem = group is List ? group.first as CanvasItem : group as CanvasItem;
      final monthStr = DateFormat('MMMM yyyy').format(firstItem.createdAt);
      final monthInt = firstItem.createdAt.month;

      if (monthStr != currentMonth) {
        currentMonth = monthStr;
        slivers.add(
          SliverToBoxAdapter(
            child: VisibilityDetector(
              key: Key('month_$monthStr'),
              onVisibilityChanged: (info) {
                // Legacy ambient sound trigger removed
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                child: Column(
                  children: [
                    Container(
                      width: 2, height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: 0.2)],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      monthStr.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        letterSpacing: 4,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: 2, height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.white.withValues(alpha: 0.2), Colors.white.withValues(alpha: 0)],
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

      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: _buildTimelineItem(group),
          ),
        ),
      );
    }

    return slivers;
  }

  Widget _buildTimelineItem(dynamic group) {
    final currentUserId = context.read<ProfileProvider>().currentProfile?.id;

    if (group is List<CanvasItem>) {
      final isLocked = group.any((item) => item.unlockAt != null && item.unlockAt!.isAfter(DateTime.now()));
      if (isLocked) return _buildTimeCapsuleWidget(group.first);
      return RepaintBoundary(
        child: VisibilityDetector(
          key: Key('group_${group.first.id}'),
          onVisibilityChanged: (info) {
            if (info.visibleFraction > 0.1 && currentUserId != null) {
              context.read<CanvasProvider>().updatePresence(
                currentUserId, 
                0.5, 
                _scrollController.hasClients ? (_scrollController.offset / _scrollController.position.maxScrollExtent) : 0.0,
                activeItemId: group.first.id,
              );
            }
          },
          child: InfiniteCardStack(items: group),
        ),
      );
    }

    final item = group as CanvasItem;
    final isLocked = item.unlockAt != null && item.unlockAt!.isAfter(DateTime.now());
    if (isLocked) return _buildTimeCapsuleWidget(item);

    return RepaintBoundary(
      child: DragTarget<String>(
        onAcceptWithDetails: (details) {
          final sticker = details.data;
          context.read<CanvasProvider>().addItem(
            authorId: currentUserId ?? '',
            type: CanvasItemType.sticker,
            content: sticker,
            xPos: details.offset.dx / MediaQuery.of(context).size.width,
            yPos: details.offset.dy / MediaQuery.of(context).size.height,
          );
        },
        builder: (context, candidateData, rejectedData) {
          Widget child;
          switch (item.type) {
            case CanvasItemType.voice:
              child = VoiceMemoWidget(content: item.content, createdAt: item.createdAt);
              break;
            case CanvasItemType.sticker:
              child = Center(child: Text(item.content, style: const TextStyle(fontSize: 64)));
              break;
            case CanvasItemType.milestone:
              child = _buildMilestoneWidget(item);
              break;
            default:
              child = GlowingNote(content: item.content, colorHex: item.color, createdAt: item.createdAt);
          }

          return VisibilityDetector(
            key: Key('item_${item.id}'),
            onVisibilityChanged: (info) {
              if (info.visibleFraction > 0.5 && currentUserId != null) {
                context.read<CanvasProvider>().updatePresence(
                  currentUserId, 
                  item.xPos, 
                  _scrollController.hasClients ? (_scrollController.offset / _scrollController.position.maxScrollExtent) : 0.0,
                  activeItemId: item.id,
                );
              }
            },
            child: child,
          );
        },
      ),
    );
  }

  List<Widget> _buildPresenceAvatars(CanvasProvider provider) {
    final List<Widget> avatars = [];
    final currentUserId = context.read<ProfileProvider>().currentProfile?.id;

    provider.presenceState.forEach((userId, stateList) {
      if (userId == currentUserId) return;
      
      final state = (stateList as List).first;
      final x = (state['x'] as num?)?.toDouble() ?? 0.5;
      final y = (state['y'] as num?)?.toDouble() ?? 0.5;

      avatars.add(
        AnimatedPositioned(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          left: x * MediaQuery.of(context).size.width,
          top: y * MediaQuery.of(context).size.height,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.white30,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
            ),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: const Icon(FluentIcons.person_12_filled, size: 14, color: Colors.white),
            ),
          ),
        ),
      );
    });

    return avatars;
  }

  Widget _buildTimeCapsuleWidget(CanvasItem item) {
    final timeLeft = item.unlockAt!.difference(DateTime.now());
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          const Icon(FluentIcons.lock_closed_24_regular, color: Colors.amber, size: 32),
          const SizedBox(height: 16),
          const Text('TIME CAPSULE', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 8),
          Text('Unlocks in ${timeLeft.inDays}d ${timeLeft.inHours % 24}h', style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildMapMode(CanvasProvider provider) {
    return InteractiveViewer(
      boundaryMargin: const EdgeInsets.all(1000),
      minScale: 0.1,
      maxScale: 2.0,
      child: SizedBox(
        width: 3000,
        height: 3000,
        child: Stack(
          children: provider.activeItems.map((item) {
            return Positioned(
              left: item.xPos * 3000,
              top: item.yPos * 3000,
              child: Transform.rotate(
                angle: item.rotation,
                child: SizedBox(
                  width: 250,
                  child: _buildTimelineItem(item),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMilestoneWidget(CanvasItem milestone) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(int.parse('FF${milestone.color.replaceAll('#', '')}', radix: 16)),
            Color(int.parse('FF${milestone.color.replaceAll('#', '')}', radix: 16)).withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(int.parse('FF${milestone.color.replaceAll('#', '')}', radix: 16)).withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(FluentIcons.star_24_filled, color: Colors.white, size: 32),
          const SizedBox(height: 16),
          Text(
            milestone.content.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'CHAPTER MILESTONE',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            FluentIcons.star_24_regular,
            size: 64,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          const Text(
            'Your timeline is waiting for memories',
            style: TextStyle(color: Colors.white38, fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _showAddNote(BuildContext context) {
    final controller = TextEditingController();
    final profile = context.read<ProfileProvider>().currentProfile;
    final colors = ['#3B82F6', '#10B981', '#F59E0B', '#EF4444', '#8B5CF6'];
    String selectedColor = colors[0];
    DateTime? unlockAt;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1F26),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Create Core Memory', 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  maxLines: 4,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'What happened?',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: colors.map((c) => GestureDetector(
                    onTap: () => setModalState(() => selectedColor = c),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: Color(int.parse('FF${c.replaceAll('#', '')}', radix: 16)),
                        shape: BoxShape.circle,
                        border: Border.all(color: selectedColor == c ? Colors.white : Colors.transparent, width: 2),
                      ),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(FluentIcons.lock_closed_24_regular, color: Colors.amber),
                  title: Text(
                    unlockAt == null 
                        ? 'Set Unlock Date (Optional)' 
                        : 'Unlocks: ${DateFormat('yMMMd').format(unlockAt!)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  trailing: unlockAt != null 
                      ? IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54), 
                          onPressed: () => setModalState(() => unlockAt = null),
                        )
                      : const Icon(Icons.chevron_right, color: Colors.white54),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                    );
                    if (date != null) {
                      setModalState(() => unlockAt = date);
                    }
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      if (controller.text.trim().isNotEmpty) {
                        context.read<CanvasProvider>().addItem(
                          authorId: profile?.id ?? '',
                          type: CanvasItemType.text,
                          content: controller.text.trim(),
                          color: selectedColor,
                          xPos: 0.1 + (0.8 * (DateTime.now().millisecond / 1000)),
                          yPos: 0.1 + (0.8 * (DateTime.now().microsecond / 1000000)),
                          unlockAt: unlockAt,
                        );
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Add to Timeline'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddMilestone(BuildContext context) {
    final controller = TextEditingController();
    final profile = context.read<ProfileProvider>().currentProfile;
    final colors = ['#F59E0B', '#8B5CF6', '#EC4899', '#10B981', '#3B82F6'];
    String selectedColor = colors[0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1F26),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('New Milestone', 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  maxLines: 1,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: 'Chapter Name (e.g. Summer Trip)',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 16),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: colors.map((c) => GestureDetector(
                    onTap: () => setModalState(() => selectedColor = c),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: Color(int.parse('FF${c.replaceAll('#', '')}', radix: 16)),
                        shape: BoxShape.circle,
                        border: Border.all(color: selectedColor == c ? Colors.white : Colors.transparent, width: 3),
                      ),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      if (controller.text.trim().isNotEmpty) {
                        context.read<CanvasProvider>().addItem(
                          authorId: profile?.id ?? '',
                          type: CanvasItemType.milestone,
                          content: controller.text.trim(),
                          color: selectedColor,
                          xPos: 0, yPos: 0,
                        );
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Pin Milestone'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    
    if (images.isNotEmpty) {
      if (!mounted) return;
      final profile = context.read<ProfileProvider>().currentProfile;
      final canvasService = CanvasService();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Uploading ${images.length} photos...')),
      );

      for (var img in images) {
        final url = await canvasService.uploadCanvasImage(widget.canvasId, img.path);
        if (mounted) {
          context.read<CanvasProvider>().addItem(
            authorId: profile?.id ?? '',
            type: CanvasItemType.photo,
            content: url,
            xPos: 0, yPos: 0,
          );
        }
      }
    }
  }

  void _showStickerPicker(BuildContext context) {
    final stickers = ['❤️', '🔥', '✨', '😂', '🎉', '🌟', '👍', '💡'];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1F26),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add Sticker', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: stickers.map((sticker) => Draggable<String>(
                data: sticker,
                feedback: Material(
                  color: Colors.transparent,
                  child: Text(sticker, style: const TextStyle(fontSize: 64)),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.5,
                  child: Text(sticker, style: const TextStyle(fontSize: 48)),
                ),
                onDragEnd: (details) {
                  if (details.wasAccepted) Navigator.pop(context);
                },
                child: GestureDetector(
                  onTap: () {
                    context.read<CanvasProvider>().addItem(
                      authorId: context.read<ProfileProvider>().currentProfile?.id ?? '',
                      type: CanvasItemType.sticker,
                      content: sticker,
                      xPos: 0.5, yPos: 0.5,
                    );
                    Navigator.pop(context);
                  },
                  child: Text(sticker, style: const TextStyle(fontSize: 48)),
                ),
              )).toList(),
            ),
            const SizedBox(height: 24),
            const Text('Drag & Drop onto memories to pin', style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _showVoiceRecorder(BuildContext context) {
    bool isRecording = false;
    String? recordPath;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => StatefulBuilder(
        builder: (innerModalCtx, setModalState) => Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F26),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isRecording ? 'Recording...' : 'Record Voice Memo',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () async {
                  if (isRecording) {
                    final path = await _audioRecorder.stop();
                    setModalState(() {
                      isRecording = false;
                      recordPath = path;
                    });
                    
                    if (recordPath != null && mounted) {
                      // Capture references BEFORE popping the modal context
                      final profile = context.read<ProfileProvider>().currentProfile;
                      final canvasProvider = context.read<CanvasProvider>();
                      final messenger = ScaffoldMessenger.of(context);
                      final canvasService = CanvasService();
                      
                      Navigator.pop(modalCtx);
                      messenger.showSnackBar(const SnackBar(content: Text('Uploading voice memo...')));
                      
                      try {
                        final url = await canvasService.uploadCanvasAudio(widget.canvasId, recordPath!);
                        if (mounted) {
                          canvasProvider.addItem(
                            authorId: profile?.id ?? '',
                            type: CanvasItemType.voice,
                            content: url,
                            xPos: 0.5, yPos: 0.5,
                          );
                        }
                      } catch (e) {
                        if (mounted) messenger.showSnackBar(SnackBar(content: Text('Failed to upload: $e')));
                      }
                    }
                  } else {
                    if (await _audioRecorder.hasPermission()) {
                      final tempDir = await getTemporaryDirectory();
                      final path = '${tempDir.path}/canvas_memo_${DateTime.now().millisecondsSinceEpoch}.m4a';
                      await _audioRecorder.start(const RecordConfig(), path: path);
                      setModalState(() => isRecording = true);
                    }
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isRecording ? Colors.red : Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: isRecording ? [BoxShadow(color: Colors.red.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 5)] : [],
                  ),
                  child: Icon(
                    isRecording ? FluentIcons.stop_24_filled : FluentIcons.mic_24_filled,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              if (!isRecording)
                TextButton(
                  onPressed: () => Navigator.pop(modalCtx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineAddItemTray extends StatefulWidget {
  final VoidCallback onAddText;
  final VoidCallback onAddPhoto;
  final VoidCallback onAddVoice;
  final VoidCallback onAddSticker;
  final VoidCallback onAddMilestone;

  const _TimelineAddItemTray({
    required this.onAddText, 
    required this.onAddPhoto,
    required this.onAddVoice,
    required this.onAddSticker,
    required this.onAddMilestone,
  });

  @override
  State<_TimelineAddItemTray> createState() => _TimelineAddItemTrayState();
}

class _TimelineAddItemTrayState extends State<_TimelineAddItemTray> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_expanded) ...[
          FloatingActionButton.small(
            heroTag: 'milestone',
            onPressed: () { setState(() => _expanded = false); widget.onAddMilestone(); },
            backgroundColor: Colors.white,
            child: const Icon(FluentIcons.star_24_regular, color: Colors.black),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.small(
            heroTag: 'sticker',
            onPressed: () { setState(() => _expanded = false); widget.onAddSticker(); },
            backgroundColor: Colors.white,
            child: const Icon(FluentIcons.sticker_24_regular, color: Colors.black),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.small(
            heroTag: 'voice',
            onPressed: () { setState(() => _expanded = false); widget.onAddVoice(); },
            backgroundColor: Colors.white,
            child: const Icon(FluentIcons.mic_24_regular, color: Colors.black),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.small(
            heroTag: 'note',
            onPressed: () { setState(() => _expanded = false); widget.onAddText(); },
            backgroundColor: Colors.white,
            child: const Icon(FluentIcons.note_24_regular, color: Colors.black),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.small(
            heroTag: 'photo',
            onPressed: () { setState(() => _expanded = false); widget.onAddPhoto(); },
            backgroundColor: Colors.white,
            child: const Icon(FluentIcons.image_24_regular, color: Colors.black),
          ),
          const SizedBox(height: 12),
        ],
        FloatingActionButton(
          onPressed: () => setState(() => _expanded = !_expanded),
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Icon(_expanded ? Icons.close : Icons.add, color: Colors.white),
        ),
      ],
    );
  }
}
