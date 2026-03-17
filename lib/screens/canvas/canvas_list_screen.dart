import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:oasis_v2/providers/canvas_provider.dart';
import 'package:oasis_v2/providers/profile_provider.dart';
import 'package:oasis_v2/widgets/canvas/canvas_list_tile.dart';

class CanvasListScreen extends StatefulWidget {
  const CanvasListScreen({super.key});

  @override
  State<CanvasListScreen> createState() => _CanvasListScreenState();
}

class _CanvasListScreenState extends State<CanvasListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final userId = context.read<ProfileProvider>().currentProfile?.id;
    if (userId != null) {
      await context.read<CanvasProvider>().loadCanvases(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<CanvasProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Canvas',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Shared visual memory boards',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => context.pushNamed('create_canvas'),
                      icon: const Icon(FluentIcons.add_circle_24_regular,
                          size: 18),
                      label: const Text('New Canvas'),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            if (provider.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (provider.canvases.isEmpty)
              SliverFillRemaining(
                child: _EmptyCanvasState(
                  onCreateTap: () => context.pushNamed('create_canvas'),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid.builder(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: provider.canvases.length,
                  itemBuilder: (context, i) {
                    final canvas = provider.canvases[i];
                    return CanvasListTile(
                      canvas: canvas,
                      onTap: () => context.pushNamed(
                        'canvas_detail',
                        pathParameters: {'canvasId': canvas.id},
                      ),
                    );
                  },
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

class _EmptyCanvasState extends StatelessWidget {
  final VoidCallback onCreateTap;
  const _EmptyCanvasState({required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
            ),
            child: Icon(
              FluentIcons.whiteboard_24_regular,
              size: 44,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No canvases yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a canvas with close friends\nand start building shared memories.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onCreateTap,
            icon: const Icon(FluentIcons.add_circle_24_regular, size: 18),
            label: const Text('Create a Canvas'),
          ),
        ],
      ),
    );
  }
}
