import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oasis_v2/models/commitment.dart';
import 'package:oasis_v2/providers/circle_provider.dart';
import 'package:oasis_v2/providers/profile_provider.dart';
import 'package:oasis_v2/widgets/circles/streak_banner.dart';
import 'package:oasis_v2/widgets/circles/commitment_card.dart';
import 'package:oasis_v2/widgets/share_sheet.dart';
import 'package:oasis_v2/widgets/circles/shattering_glass_animation.dart';
import 'package:oasis_v2/widgets/fluid_mesh_background.dart';

import 'package:oasis_v2/services/circle_service.dart';

class CircleDetailScreen extends StatefulWidget {
  final String circleId;
  const CircleDetailScreen({super.key, required this.circleId});

  @override
  State<CircleDetailScreen> createState() => _CircleDetailScreenState();
}

class _CircleDetailScreenState extends State<CircleDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final CircleService _circleService = CircleService();
  bool _showShatterAnimation = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await context.read<CircleProvider>().openCircle(widget.circleId);
    _checkStreak();
  }

  Future<void> _checkStreak() async {
    final provider = context.read<CircleProvider>();
    final circle = provider.activeCircle;
    if (circle == null) return;

    final prefs = await SharedPreferences.getInstance();
    final lastStreak = prefs.getInt('circle_streak_${circle.id}') ?? 0;
    
    // If streak was > 0 and is now 0, show shatter animation
    if (lastStreak > 0 && circle.streakCount == 0) {
      setState(() => _showShatterAnimation = true);
    }
    
    // Update stored streak
    await prefs.setInt('circle_streak_${circle.id}', circle.streakCount);
  }

  Future<void> _confirmDeleteCircle() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Circle?'),
        content: const Text(
          'This action cannot be undone. All commitments and history for this circle will be permanently lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _circleService.deleteCircle(widget.circleId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Circle deleted successfully')),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting circle: $e')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    context.read<CircleProvider>().closeCircle();
    _tabController.dispose();
    super.dispose();
  }

  String get _currentUserId =>
      context.read<ProfileProvider>().currentProfile?.id ?? '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<CircleProvider>();
    final circle = provider.activeCircle;
    final commitments = provider.todaysCommitments;
    final isCreator = circle?.createdBy == _currentUserId;

    if (circle == null && provider.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxScrolled) => [
              // ── Header ────────────────────────────────────────────────────
              SliverAppBar(
                pinned: true,
                expandedHeight: 140, // Reduced from 180 to shift upwards
                backgroundColor: Colors.black.withValues(alpha: 0.2),
                leading: IconButton(
                  icon: const Icon(FluentIcons.chevron_left_24_regular),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(FluentIcons.people_add_24_regular),
                    onPressed: () {
                      if (circle != null) {
                        final userName = context.read<ProfileProvider>().currentProfile?.fullName ?? 'Someone';
                        final commitment = commitments.isNotEmpty ? commitments.first.title : 'their commitments';
                        
                        ShareSheet.show(
                          context,
                          title: 'Invite Accountability Partner',
                          payload: '[INVITE:circle:${circle.id}:${circle.name}]',
                          externalMessage: '$userName committed to "$commitment". They invited you to be their judge. Download Oasis to verify their streak: https://oasis-app.com/circle/join/${circle.id}',
                        );
                      }
                    },
                    tooltip: 'Invite Partner',
                  ),
                  if (isCreator)
                    PopupMenuButton<String>(
                      icon: const Icon(FluentIcons.more_vertical_24_regular),
                      onSelected: (value) {
                        if (value == 'delete') {
                          _confirmDeleteCircle();
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(FluentIcons.delete_24_regular,
                                  color: theme.colorScheme.error, size: 20),
                              const SizedBox(width: 12),
                              Text('Delete Circle',
                                  style: TextStyle(color: theme.colorScheme.error)),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  centerTitle: false,
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        circle?.emoji ?? '🌊',
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          circle?.name ?? '',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  background: Stack(
                    children: [
                      Positioned.fill(
                        child: FluidMeshBackground(streakCount: circle?.streakCount ?? 0),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.4),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 60, right: 20),
                        child: Align(
                          alignment: Alignment.topRight,
                          child: circle != null
                              ? StreakBanner(streakCount: circle.streakCount)
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ),
                ),
                bottom: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: "Today's Commitments"),
                    Tab(text: 'History'),
                  ],
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                // ── Today's Commitments Tab ────────────────────────────────
                _TodayTab(
                  commitments: commitments,
                  isLoading: provider.isLoading,
                  currentUserId: _currentUserId,
                  onMarkComplete: (commitmentId, note) {
                    context.read<CircleProvider>().markComplete(
                          commitmentId: commitmentId,
                          userId: _currentUserId,
                          note: note,
                        );
                  },
                  onSetIntent: (commitmentId, intent) {
                    context.read<CircleProvider>().setIntent(
                          commitmentId: commitmentId,
                          userId: _currentUserId,
                          intent: intent,
                        );
                  },
                  onAddCommitment: circle != null
                      ? () => context.pushNamed(
                            'create_commitment',
                            pathParameters: {'circleId': circle.id},
                          )
                      : null,
                ),

                // ── History Tab (placeholder) ──────────────────────────────
                const _HistoryTab(),
              ],
            ),
          ),
          if (_showShatterAnimation)
            ShatteringGlassAnimation(
              onComplete: () => setState(() => _showShatterAnimation = false),
            ),
        ],
      ),
    );
  }
}

// ─── Today Tab ───────────────────────────────────────────────────────────────

class _TodayTab extends StatelessWidget {
  final List<Commitment> commitments;
  final bool isLoading;
  final String currentUserId;
  final void Function(String commitmentId, String? note) onMarkComplete;
  final void Function(String commitmentId, MemberIntent intent) onSetIntent;
  final VoidCallback? onAddCommitment;

  const _TodayTab({
    required this.commitments,
    required this.isLoading,
    required this.currentUserId,
    required this.onMarkComplete,
    required this.onSetIntent,
    this.onAddCommitment,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'What will you do today?',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                if (onAddCommitment != null)
                  FilledButton.icon(
                    onPressed: onAddCommitment,
                    icon: const Icon(FluentIcons.add_24_regular, size: 16),
                    label: const Text('Add'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (commitments.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    FluentIcons.checkbox_checked_24_regular,
                    size: 48,
                    color: theme.colorScheme.primary.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No commitments yet today',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add one for your circle to take on!',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.builder(
              itemCount: commitments.length,
              itemBuilder: (context, i) {
                final commitment = commitments[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CommitmentCard(
                    commitment: commitment,
                    currentUserId: currentUserId,
                    onMarkComplete: () => _showCompleteSheet(
                      context,
                      commitment.id,
                    ),
                    onSetIntent: (intent) =>
                        onSetIntent(commitment.id, intent),
                  ),
                );
              },
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  void _showCompleteSheet(BuildContext context, String commitmentId) {
    final noteController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🎉 Mark it done!',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Add a short note or reaction (optional)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                maxLength: 80,
                decoration: const InputDecoration(
                  hintText: 'How did it go? 🌊',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onMarkComplete(
                      commitmentId,
                      noteController.text.isEmpty
                          ? null
                          : noteController.text,
                    );
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Mark Complete ✅'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── History Tab (placeholder) ────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            FluentIcons.calendar_ltr_24_regular,
            size: 56,
            color: theme.colorScheme.primary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text('History coming soon', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Your circle\'s streak calendar\nwill live here.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
