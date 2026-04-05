import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:oasis/features/canvas/presentation/providers/canvas_provider.dart';
import 'package:oasis/features/profile/presentation/providers/profile_provider.dart';
import 'package:oasis/features/canvas/domain/models/canvas_models.dart';
import 'package:oasis/features/canvas/presentation/widgets/canvas/starry_night_background.dart';
import 'package:oasis/features/canvas/presentation/widgets/canvas/timeline_scrubber.dart';
import 'package:oasis/features/canvas/presentation/widgets/canvas/pulse_ripple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oasis/core/network/supabase_client.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oasis/services/canvas_service.dart';
import 'package:oasis/widgets/share_sheet.dart';
import 'package:oasis/services/canvas_audio_service.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:oasis/services/notification_service.dart';
import 'package:oasis/widgets/canvas/scattered_polaroid_spread.dart';
import 'package:oasis/widgets/canvas/canvas_item_widget.dart';
import 'package:google_fonts/google_fonts.dart';

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
        await context.read<CanvasProvider>().joinCanvas(
          widget.canvasId,
          currentUserId,
        );
      }
      if (mounted) {
        final canvasProvider = context.read<CanvasProvider>();
        canvasProvider.openCanvas(widget.canvasId);
        _setupPulseChannel();

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

  void _setupPulseChannel() {
    final supabase = SupabaseService().client;
    _pulseChannel = supabase.channel('canvas_pulses:${widget.canvasId}');

    _pulseChannel!
        .onBroadcast(
          event: 'pulse',
          callback: (payload) {
            if (mounted) {
              final x = (payload['x'] as num).toDouble();
              final y = (payload['y'] as num).toDouble();
              _triggerLocalPulse(Offset(x, y));
            }
          },
        )
        .subscribe((status, [error]) {
          if (status == RealtimeSubscribeStatus.channelError) {
            debugPrint(
              '[TimelineCanvasScreen] Pulse subscription error: $error',
            );
          }
        });
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

  void _updatePresence(PointerEvent event) {
    final currentUserId = context.read<ProfileProvider>().currentProfile?.id;
    if (currentUserId == null) return;

    final x = event.localPosition.dx / MediaQuery.of(context).size.width;
    final y = event.localPosition.dy / MediaQuery.of(context).size.height;

    // Throttling presence updates implicitly via the service if needed,
    // but here we just send it.
    context.read<CanvasProvider>().updatePresence(currentUserId, x, y);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CanvasProvider>();
    final canvas = provider.activeCanvas;
    final currentUserId = context.read<ProfileProvider>().currentProfile?.id;
    final isOwner = canvas?.createdBy == currentUserId;
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      body: StarryNightBackground(
        scrollOffset: _scrollOffset,
        child: MouseRegion(
          onHover: _updatePresence,
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
                      if (!isDesktop)
                        _buildMobileAppBar(canvas, isOwner)
                      else
                        SliverToBoxAdapter(
                          child: _buildDesktopHeader(canvas, provider),
                        ),

                      if (provider.isLoading)
                        const SliverFillRemaining(
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        )
                      else if (provider.activeItems.isEmpty)
                        SliverFillRemaining(child: _buildEmptyState())
                      else
                        ..._buildTimelineSlivers(provider.activeItems),

                      const SliverToBoxAdapter(child: SizedBox(height: 120)),
                    ],
                  ),

                // Collaborative Cursors (Visible only on Map Mode or Desktop)
                if (_isMapMode || isDesktop) ..._buildPresenceCursors(provider),

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

                ..._pulses.map(
                  (p) => PulseRipple(
                    key: ValueKey(p.id),
                    position: p.position,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton:
          isDesktop
              ? null
              : _TimelineAddItemTray(
                onAddText: () => _showAddNote(context),
                onAddPhoto: () => _pickAndUploadPhoto(),
                onAddVoice: () => _showVoiceRecorder(context),
                onAddSticker: () => _showStickerPicker(context),
                onAddMilestone: () => _showAddMilestone(context),
                onAddJournal: () => _showAddJournal(context),
              ),
    );
  }

  Widget _buildMobileAppBar(OasisCanvasEntity? canvas, bool isOwner) {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          FluentIcons.chevron_left_24_regular,
          color: Colors.white,
        ),
        onPressed: () => context.pop(),
      ),
      title: Text(
        canvas?.title ?? 'Our Canvas',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(
            _isMapMode
                ? FluentIcons.list_24_regular
                : FluentIcons.glance_24_regular,
            color: Colors.white,
          ),
          onPressed: () => setState(() => _isMapMode = !_isMapMode),
        ),
        IconButton(
          icon: const Icon(
            FluentIcons.people_add_24_regular,
            color: Colors.white,
          ),
          onPressed: () => _showInviteSheet(canvas),
        ),
      ],
    );
  }

  Widget _buildDesktopHeader(
    OasisCanvasEntity? canvas,
    CanvasProvider provider,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              FluentIcons.chevron_left_24_regular,
              color: Colors.white,
            ),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                canvas?.title ?? 'Our Canvas',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              _buildActiveUsersRow(provider),
            ],
          ),
          const Spacer(),
          _DesktopCanvasToolbar(
            onAddText: () => _showAddNote(context),
            onAddPhoto: () => _pickAndUploadPhoto(),
            onAddVoice: () => _showVoiceRecorder(context),
            onAddSticker: () => _showStickerPicker(context),
            onAddMilestone: () => _showAddMilestone(context),
            onToggleView: () => setState(() => _isMapMode = !_isMapMode),
            isMapMode: _isMapMode,
          ),
          const SizedBox(width: 16),
          FilledButton.icon(
            onPressed: () => _showInviteSheet(canvas),
            icon: const Icon(FluentIcons.people_add_20_regular, size: 18),
            label: const Text('Invite'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white10,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveUsersRow(CanvasProvider provider) {
    final currentUserId = context.read<ProfileProvider>().currentProfile?.id;
    final othersCount =
        provider.presenceState.length -
        (provider.presenceState.containsKey(currentUserId) ? 1 : 0);

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${othersCount + 1} online',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPresenceCursors(CanvasProvider provider) {
    final List<Widget> cursors = [];
    final currentUserId = context.read<ProfileProvider>().currentProfile?.id;

    provider.presenceState.forEach((userId, stateList) {
      if (userId == currentUserId) return;

      final state = (stateList as List).first;
      final x = (state['x'] as num?)?.toDouble() ?? 0.5;
      final y = (state['y'] as num?)?.toDouble() ?? 0.5;

      cursors.add(
        AnimatedPositioned(
          duration: const Duration(milliseconds: 150),
          curve: Curves.linear,
          left: x * MediaQuery.of(context).size.width,
          top: y * MediaQuery.of(context).size.height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                FluentIcons.cursor_24_filled,
                size: 20,
                color: Colors.blueAccent,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Friend',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });

    return cursors;
  }

  void _showInviteSheet(OasisCanvasEntity? canvas) {
    if (canvas == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => ShareSheet(
            title: 'Share Canvas',
            payload: '[INVITE:canvas:${canvas.id}:${canvas.title}]',
          ),
    );
  }

  void _showAddJournal(BuildContext context) {
    final controller = TextEditingController();
    final profile = context.read<ProfileProvider>().currentProfile;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(32),
              decoration: const BoxDecoration(
                color: Color(0xFFFDFCF0),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'NEW JOURNAL ENTRY',
                        style: GoogleFonts.montserrat(
                          color: Colors.brown[300],
                          letterSpacing: 2,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.brown),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      maxLines: null,
                      autofocus: true,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        color: Colors.black87,
                        height: 1.6,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Pour your thoughts here...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        if (controller.text.trim().isNotEmpty) {
                          context.read<CanvasProvider>().addItem(
                            authorId: profile?.id ?? '',
                            type: CanvasItemType.journal,
                            content: controller.text.trim(),
                            xPos: 0,
                            yPos: 0,
                          );
                          Navigator.pop(context);
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.brown[700],
                      ),
                      child: const Text('Seal Entry'),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  List<Widget> _buildTimelineSlivers(List<CanvasItemEntity> items) {
    final sortedItems = List<CanvasItemEntity>.from(items)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final List<dynamic> timelineGroups = [];
    for (int i = 0; i < sortedItems.length; i++) {
      final item = sortedItems[i];
      if (item.type == CanvasItemType.photo) {
        final List<CanvasItemEntity> stack = [item];
        while (i + 1 < sortedItems.length &&
            sortedItems[i + 1].type == CanvasItemType.photo &&
            item.createdAt
                    .difference(sortedItems[i + 1].createdAt)
                    .inHours
                    .abs() <
                1) {
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
      final firstItem =
          group is List
              ? group.first as CanvasItemEntity
              : group as CanvasItemEntity;
      final monthStr = DateFormat('MMMM yyyy').format(firstItem.createdAt);

      if (monthStr != currentMonth) {
        currentMonth = monthStr;
        slivers.add(
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
              child: Column(
                children: [
                  Container(
                    width: 2,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0),
                          Colors.white.withValues(alpha: 0.2),
                        ],
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
                    width: 2,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.2),
                          Colors.white.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ],
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

    if (group is List<CanvasItemEntity>) {
      final isLocked = group.any(
        (item) =>
            item.unlockAt != null && item.unlockAt!.isAfter(DateTime.now()),
      );
      if (isLocked) return _buildTimeCapsuleWidget(group.first);
      return ScatteredPolaroidSpread(items: group);
    }

    final item = group as CanvasItemEntity;
    final isLocked =
        item.unlockAt != null && item.unlockAt!.isAfter(DateTime.now());
    if (isLocked) return _buildTimeCapsuleWidget(item);

    return Align(
      alignment: Alignment.center,
      child: CanvasItemWidget(
        item: item,
        onMoved: (dx, dy, rotation) {
          context.read<CanvasProvider>().moveItem(
            itemId: item.id,
            xPos: dx,
            yPos: dy,
            rotation: rotation,
            lastModifiedBy: currentUserId,
          );
        },
        onDelete: () => context.read<CanvasProvider>().deleteItem(item.id),
        onReact:
            (emoji) => context.read<CanvasProvider>().toggleReaction(
              item.id,
              currentUserId!,
              emoji,
            ),
        onLock:
            (lock) => context.read<CanvasProvider>().setItemLock(item.id, lock),
      ),
    );
  }

  Widget _buildTimeCapsuleWidget(CanvasItemEntity item) {
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
          const Icon(
            FluentIcons.lock_closed_24_regular,
            color: Colors.amber,
            size: 32,
          ),
          const SizedBox(height: 16),
          const Text(
            'TIME CAPSULE',
            style: TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Unlocks in ${timeLeft.inDays}d ${timeLeft.inHours % 24}h',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildMapMode(CanvasProvider provider) {
    final currentUserId = context.read<ProfileProvider>().currentProfile?.id;
    return InteractiveViewer(
      boundaryMargin: const EdgeInsets.all(1000),
      minScale: 0.1,
      maxScale: 2.0,
      child: SizedBox(
        width: 3000,
        height: 3000,
        child: Stack(
          children:
              provider.activeItems.map((item) {
                return Positioned(
                  left: item.xPos,
                  top: item.yPos,
                  child: CanvasItemWidget(
                    item: item,
                    onMoved: (dx, dy, rotation) {
                      context.read<CanvasProvider>().moveItem(
                        itemId: item.id,
                        xPos: dx / 3000,
                        yPos: dy / 3000,
                        rotation: rotation,
                        lastModifiedBy: currentUserId,
                      );
                    },
                    onDelete:
                        () =>
                            context.read<CanvasProvider>().deleteItem(item.id),
                    onReact:
                        (emoji) => context
                            .read<CanvasProvider>()
                            .toggleReaction(item.id, currentUserId!, emoji),
                    onLock:
                        (lock) => context.read<CanvasProvider>().setItemLock(
                          item.id,
                          lock,
                        ),
                  ),
                );
              }).toList(),
        ),
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
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (context, setModalState) => Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1A1F26),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Create Core Memory',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: controller,
                          maxLines: 4,
                          autofocus: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'What happened?',
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children:
                              colors
                                  .map(
                                    (c) => GestureDetector(
                                      onTap:
                                          () => setModalState(
                                            () => selectedColor = c,
                                          ),
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: Color(
                                            int.parse(
                                              'FF${c.replaceAll('#', '')}',
                                              radix: 16,
                                            ),
                                          ),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color:
                                                selectedColor == c
                                                    ? Colors.white
                                                    : Colors.transparent,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                        const SizedBox(height: 20),
                        ListTile(
                          leading: const Icon(
                            FluentIcons.lock_closed_24_regular,
                            color: Colors.amber,
                          ),
                          title: Text(
                            unlockAt == null
                                ? 'Set Unlock Date (Optional)'
                                : 'Unlocks: ${DateFormat('yMMMd').format(unlockAt!)}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          trailing:
                              unlockAt != null
                                  ? IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white54,
                                    ),
                                    onPressed:
                                        () => setModalState(
                                          () => unlockAt = null,
                                        ),
                                  )
                                  : const Icon(
                                    Icons.chevron_right,
                                    color: Colors.white54,
                                  ),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(
                                const Duration(days: 1),
                              ),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365 * 10),
                              ),
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
                                  xPos: 0.5,
                                  yPos: 0.5,
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
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (context, setModalState) => Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1A1F26),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'New Milestone',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: controller,
                          maxLines: 1,
                          autofocus: true,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: 'Chapter Name (e.g. Summer Trip)',
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 16,
                            ),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children:
                              colors
                                  .map(
                                    (c) => GestureDetector(
                                      onTap:
                                          () => setModalState(
                                            () => selectedColor = c,
                                          ),
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: Color(
                                            int.parse(
                                              'FF${c.replaceAll('#', '')}',
                                              radix: 16,
                                            ),
                                          ),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color:
                                                selectedColor == c
                                                    ? Colors.white
                                                    : Colors.transparent,
                                            width: 3,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
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
                                  xPos: 0,
                                  yPos: 0,
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
        final url = await canvasService.uploadCanvasImage(
          widget.canvasId,
          img.path,
        );
        if (mounted) {
          context.read<CanvasProvider>().addItem(
            authorId: profile?.id ?? '',
            type: CanvasItemType.photo,
            content: url,
            xPos: 0,
            yPos: 0,
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
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1F26),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Add Sticker',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children:
                      stickers
                          .map(
                            (sticker) => GestureDetector(
                              onTap: () {
                                context.read<CanvasProvider>().addItem(
                                  authorId:
                                      context
                                          .read<ProfileProvider>()
                                          .currentProfile
                                          ?.id ??
                                      '',
                                  type: CanvasItemType.sticker,
                                  content: sticker,
                                  xPos: 0.5,
                                  yPos: 0.5,
                                );
                                Navigator.pop(context);
                              },
                              child: Text(
                                sticker,
                                style: const TextStyle(fontSize: 48),
                              ),
                            ),
                          )
                          .toList(),
                ),
                const SizedBox(height: 24),
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
      builder:
          (modalCtx) => StatefulBuilder(
            builder:
                (innerModalCtx, setModalState) => Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1F26),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isRecording ? 'Recording...' : 'Record Voice Memo',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
                              final profile =
                                  context
                                      .read<ProfileProvider>()
                                      .currentProfile;
                              final canvasProvider =
                                  context.read<CanvasProvider>();
                              final messenger = ScaffoldMessenger.of(context);
                              final canvasService = CanvasService();

                              Navigator.pop(modalCtx);
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Uploading voice memo...'),
                                ),
                              );

                              try {
                                final url = await canvasService
                                    .uploadCanvasAudio(
                                      widget.canvasId,
                                      recordPath!,
                                    );
                                if (mounted) {
                                  canvasProvider.addItem(
                                    authorId: profile?.id ?? '',
                                    type: CanvasItemType.voice,
                                    content: url,
                                    xPos: 0.5,
                                    yPos: 0.5,
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to upload: $e'),
                                    ),
                                  );
                                }
                              }
                            }
                          } else {
                            if (await _audioRecorder.hasPermission()) {
                              final tempDir = await getTemporaryDirectory();
                              final path =
                                  '${tempDir.path}/canvas_memo_${DateTime.now().millisecondsSinceEpoch}.m4a';
                              await _audioRecorder.start(
                                const RecordConfig(),
                                path: path,
                              );
                              setModalState(() => isRecording = true);
                            }
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color:
                                isRecording
                                    ? Colors.red
                                    : Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                            boxShadow:
                                isRecording
                                    ? [
                                      BoxShadow(
                                        color: Colors.red.withValues(
                                          alpha: 0.5,
                                        ),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ]
                                    : [],
                          ),
                          child: Icon(
                            isRecording
                                ? FluentIcons.stop_24_filled
                                : FluentIcons.mic_24_filled,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (!isRecording)
                        TextButton(
                          onPressed: () => Navigator.pop(modalCtx),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                    ],
                  ),
                ),
          ),
    );
  }
}

class _DesktopCanvasToolbar extends StatelessWidget {
  final VoidCallback onAddText;
  final VoidCallback onAddPhoto;
  final VoidCallback onAddVoice;
  final VoidCallback onAddSticker;
  final VoidCallback onAddMilestone;
  final VoidCallback onToggleView;
  final bool isMapMode;

  const _DesktopCanvasToolbar({
    required this.onAddText,
    required this.onAddPhoto,
    required this.onAddVoice,
    required this.onAddSticker,
    required this.onAddMilestone,
    required this.onToggleView,
    required this.isMapMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToolbarAction(
            icon: FluentIcons.text_description_24_regular,
            label: 'Note',
            onTap: onAddText,
          ),
          _ToolbarAction(
            icon: FluentIcons.image_24_regular,
            label: 'Photo',
            onTap: onAddPhoto,
          ),
          _ToolbarAction(
            icon: FluentIcons.mic_24_regular,
            label: 'Voice',
            onTap: onAddVoice,
          ),
          _ToolbarAction(
            icon: FluentIcons.sticker_24_regular,
            label: 'Sticker',
            onTap: onAddSticker,
          ),
          _ToolbarAction(
            icon: FluentIcons.star_24_regular,
            label: 'Milestone',
            onTap: onAddMilestone,
          ),
          const VerticalDivider(
            width: 24,
            indent: 8,
            endIndent: 8,
            color: Colors.white10,
          ),
          _ToolbarAction(
            icon:
                isMapMode
                    ? FluentIcons.list_24_regular
                    : FluentIcons.glance_24_regular,
            label: isMapMode ? 'Timeline' : 'Spatial',
            onTap: onToggleView,
            isVibrant: true,
          ),
        ],
      ),
    );
  }
}

class _ToolbarAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isVibrant;

  const _ToolbarAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isVibrant = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            color: isVibrant ? Colors.blueAccent : Colors.white70,
            size: 20,
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
  final VoidCallback onAddJournal;

  const _TimelineAddItemTray({
    required this.onAddText,
    required this.onAddPhoto,
    required this.onAddVoice,
    required this.onAddSticker,
    required this.onAddMilestone,
    required this.onAddJournal,
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
            onPressed: () {
              setState(() => _expanded = false);
              widget.onAddMilestone();
            },
            backgroundColor: Colors.white,
            child: const Icon(FluentIcons.star_24_regular, color: Colors.black),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.small(
            heroTag: 'journal',
            onPressed: () {
              setState(() => _expanded = false);
              widget.onAddJournal();
            },
            backgroundColor: const Color(0xFFFDFCF0),
            child: const Icon(FluentIcons.book_24_regular, color: Colors.brown),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.small(
            heroTag: 'sticker',
            onPressed: () {
              setState(() => _expanded = false);
              widget.onAddSticker();
            },
            backgroundColor: Colors.white,
            child: const Icon(
              FluentIcons.sticker_24_regular,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.small(
            heroTag: 'voice',
            onPressed: () {
              setState(() => _expanded = false);
              widget.onAddVoice();
            },
            backgroundColor: Colors.white,
            child: const Icon(FluentIcons.mic_24_regular, color: Colors.black),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.small(
            heroTag: 'note',
            onPressed: () {
              setState(() => _expanded = false);
              widget.onAddText();
            },
            backgroundColor: Colors.white,
            child: const Icon(FluentIcons.note_24_regular, color: Colors.black),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.small(
            heroTag: 'photo',
            onPressed: () {
              setState(() => _expanded = false);
              widget.onAddPhoto();
            },
            backgroundColor: Colors.white,
            child: const Icon(
              FluentIcons.image_24_regular,
              color: Colors.black,
            ),
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
