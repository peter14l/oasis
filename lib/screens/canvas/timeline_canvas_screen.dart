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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CanvasProvider>().openCanvas(widget.canvasId);
      _setupPulseChannel();
    });
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
    if (_pulseChannel != null) {
      SupabaseService().client.removeChannel(_pulseChannel!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CanvasProvider>();
    final canvas = provider.activeCanvas;

    return Scaffold(
      body: StarryNightBackground(
        scrollOffset: _scrollOffset,
        child: GestureDetector(
          onLongPressStart: (details) => _sendPulse(details.localPosition),
          child: Stack(
            children: [
              CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // ── Transparent App Bar ───────────────────────────────────
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
                    ],
                  ),

                  // ── Timeline Items ────────────────────────────────────────
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
                    
                  // Extra padding at bottom for FAB
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),

              // ── Fast Scrubber ─────────────────────────────────────────
              if (provider.activeItems.isNotEmpty)
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

              // ── Real-time Pulses ──────────────────────────────────────
              ..._pulses.map((p) => PulseRipple(
                    key: ValueKey(p.id),
                    position: p.position,
                    color: Colors.white,
                  )),
            ],
          ),
        ),
      ),
      floatingActionButton: _TimelineAddItemTray(
        onAddText: () => _showAddNote(context),
        onAddPhoto: () => _pickAndUploadPhoto(),
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

      if (monthStr != currentMonth) {
        currentMonth = monthStr;
        slivers.add(
          SliverToBoxAdapter(
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
        );
      }

      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: group is List<CanvasItem>
                ? InfiniteCardStack(items: group)
                : (group as CanvasItem).type == CanvasItemType.voice
                    ? VoiceMemoWidget(
                        content: group.content,
                        createdAt: group.createdAt,
                      )
                    : GlowingNote(
                        content: group.content,
                        colorHex: group.color,
                        createdAt: group.createdAt,
                      ),
          ),
        ),
      );
    }

    return slivers;
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
                          xPos: 0, yPos: 0,
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
}

class _TimelineAddItemTray extends StatefulWidget {
  final VoidCallback onAddText;
  final VoidCallback onAddPhoto;

  const _TimelineAddItemTray({required this.onAddText, required this.onAddPhoto});

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
