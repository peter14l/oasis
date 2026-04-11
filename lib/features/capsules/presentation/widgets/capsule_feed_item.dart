import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:oasis/features/capsules/domain/models/time_capsule_entity.dart';
import 'package:timeago/timeago.dart' as timeago;

class CapsuleFeedItem extends StatelessWidget {
  final TimeCapsule capsule;

  const CapsuleFeedItem({super.key, required this.capsule});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLocked = capsule.isLocked;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: capsule.userAvatar.isNotEmpty
                          ? NetworkImage(capsule.userAvatar)
                          : null,
                      child: capsule.userAvatar.isEmpty
                          ? Text(capsule.username.isNotEmpty ? capsule.username[0] : '?')
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            capsule.username,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Sealed ${timeago.format(capsule.createdAt)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      isLocked ? Icons.lock : Icons.lock_open,
                      color: isLocked ? colorScheme.tertiary : colorScheme.primary,
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Content Area
                Stack(
                  children: [
                    // Actual Content (Blurred if locked)
                    ImageFiltered(
                      imageFilter: ImageFilter.blur(
                        sigmaX: isLocked ? 10 : 0, 
                        sigmaY: isLocked ? 10 : 0
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          // If locked, maybe show dummy text length or random chars? 
                          // Or just the real text blurred (privacy risk if blur isn't perfect, but okay for MVP)
                          // Better: Show "Locked Content" text if locked to be safe.
                          isLocked 
                            ? 'This is a secret message that is quite long and hidden...' 
                            : capsule.content,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                    ),
                    
                    // Lock Overlay
                    if (isLocked)
                      Positioned.fill(
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24, 
                              vertical: 12
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.hourglass_empty, 
                                  size: 20,
                                  color: colorScheme.onTertiaryContainer
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatDuration(capsule.timeRemaining),
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: colorScheme.onTertiaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inDays > 365) {
      return 'Unlocks in ${(d.inDays / 365).toStringAsFixed(1)} years';
    } else if (d.inDays > 0) {
      return 'Unlocks in ${d.inDays} days';
    } else if (d.inHours > 0) {
      return 'Unlocks in ${d.inHours} hours';
    } else {
      return 'Unlocks soon';
    }
  }
}

