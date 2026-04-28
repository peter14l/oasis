import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oasis/features/feed/domain/models/post_mood.dart';
import 'package:oasis/features/profile/presentation/providers/profile_provider.dart';
import 'package:oasis/core/utils/haptic_utils.dart';

class MoodOrbitWidget extends StatefulWidget {
  final String userId;
  final String? currentMood;
  final String? currentEmoji;
  final bool isOwner;

  const MoodOrbitWidget({
    super.key,
    required this.userId,
    this.currentMood,
    this.currentEmoji,
    this.isOwner = false,
  });

  @override
  State<MoodOrbitWidget> createState() => _MoodOrbitWidgetState();
}

class _MoodOrbitWidgetState extends State<MoodOrbitWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (widget.currentEmoji == null && !widget.isOwner) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: widget.isOwner ? () => _showMoodPicker(context) : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Orbit rings
          if (widget.currentEmoji != null)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  width: 60 * _pulseAnimation.value,
                  height: 60 * _pulseAnimation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                );
              },
            ),
          if (widget.currentEmoji != null)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  width: 50 * (2 - _pulseAnimation.value),
                  height: 50 * (2 - _pulseAnimation.value),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.05),
                      width: 1,
                    ),
                  ),
                );
              },
            ),
          
          // Mood Emoji
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Text(
              widget.currentEmoji ?? '✨',
              style: TextStyle(
                fontSize: 24,
                color: widget.currentEmoji == null ? colorScheme.onSurface.withValues(alpha: 0.3) : null,
              ),
            ),
          ),
          
          // Label for owner if no mood set
          if (widget.isOwner && widget.currentEmoji == null)
            Positioned(
              bottom: -20,
              child: Text(
                'Set Vibe',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showMoodPicker(BuildContext context) {
    HapticUtils.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How\'s your vibe?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ...PostMood.values.map((mood) {
                    final isSelected = widget.currentMood == mood.name;
                    return GestureDetector(
                      onTap: () {
                        context.read<ProfileProvider>().setMood(
                          userId: widget.userId,
                          mood: mood.name,
                          emoji: mood.emoji,
                        );
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected 
                            ? Theme.of(context).colorScheme.primaryContainer 
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected 
                              ? Theme.of(context).colorScheme.primary 
                              : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(mood.emoji, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Text(mood.label),
                          ],
                        ),
                      ),
                    );
                  }),
                  // Clear option
                  GestureDetector(
                    onTap: () {
                      context.read<ProfileProvider>().setMood(
                        userId: widget.userId,
                        mood: null,
                        emoji: null,
                      );
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.close, size: 18),
                          SizedBox(width: 8),
                          Text('Clear'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
