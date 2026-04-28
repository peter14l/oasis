import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oasis/features/wellbeing/presentation/providers/digital_garden_provider.dart';
import 'package:oasis/features/wellbeing/presentation/widgets/garden_canvas_painter.dart';
import 'package:oasis/services/auth_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

class DigitalGardenScreen extends StatefulWidget {
  const DigitalGardenScreen({super.key});

  @override
  State<DigitalGardenScreen> createState() => _DigitalGardenScreenState();
}

class _DigitalGardenScreenState extends State<DigitalGardenScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthService>().currentUser?.id;
      if (userId != null) {
        context.read<DigitalGardenProvider>().loadGarden(userId);
      }
    });
  }

  void _handleTap(BuildContext context, TapUpDetails details) {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    
    // Normalized coordinates
    final x = details.localPosition.dx / size.width;
    final y = details.localPosition.dy / size.height;
    
    final provider = context.read<DigitalGardenProvider>();
    final userId = context.read<AuthService>().currentUser?.id;
    if (userId == null) return;

    // Check if we tapped on an existing plot
    for (final plot in provider.plots) {
      final plotX = plot.xPos * size.width;
      final plotY = plot.yPos * size.height;
      
      // Calculate distance
      final distance = (Offset(plotX, plotY) - details.localPosition).distance;
      if (distance < 30) {
        // Tapped on a plot, show its details or tend it
        _showPlotDetails(context, plot.id, plot.seedText, plot.stage);
        return;
      }
    }

    // Otherwise, plant a new seed
    _showPlantSeedDialog(context, userId, x, y);
  }

  void _showPlantSeedDialog(BuildContext context, String userId, double x, double y) {
    final textController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Plant a Thought'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            hintText: 'What\'s on your mind?',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (textController.text.trim().isNotEmpty) {
                context.read<DigitalGardenProvider>().plantSeed(
                  userId, 
                  textController.text.trim(), 
                  x, 
                  y
                );
              }
              Navigator.pop(context);
            },
            child: const Text('Plant'),
          ),
        ],
      ),
    );
  }

  void _showPlotDetails(BuildContext context, String plotId, String text, int stage) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Planted Thought',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                text,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      context.read<DigitalGardenProvider>().removePlot(plotId);
                      Navigator.pop(context);
                    },
                    icon: const Icon(FluentIcons.delete_24_regular, size: 18),
                    label: const Text('Uproot'),
                  ),
                  FilledButton.icon(
                    onPressed: stage < 3 ? () {
                      context.read<DigitalGardenProvider>().tendPlot(plotId);
                      Navigator.pop(context);
                    } : null,
                    icon: const Icon(Icons.water_drop_outlined, size: 18),
                    label: Text(stage < 3 ? 'Tend Plant' : 'Fully Bloomed'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Digital Garden'),
        centerTitle: true,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: colorScheme.surface.withValues(alpha: 0.5)),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.surface,
              colorScheme.primaryContainer.withValues(alpha: 0.3),
              colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Consumer<DigitalGardenProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.plots.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return GestureDetector(
              onTapUp: (details) => _handleTap(context, details),
              child: CustomPaint(
                painter: GardenCanvasPainter(
                  plots: provider.plots,
                  colorScheme: colorScheme,
                ),
                size: Size.infinite,
                child: provider.plots.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.yard_outlined,
                              size: 64,
                              color: colorScheme.primary.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tap anywhere to plant a thought',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }
}
