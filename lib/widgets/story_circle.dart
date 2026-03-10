import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:morrow_v2/models/story_model.dart';

class StoryCircle extends StatelessWidget {
  final StoryModel story;
  final VoidCallback onTap;

  const StoryCircle({super.key, required this.story, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient:
                  !story.hasViewed
                      ? LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                      : null,
              border:
                  story.hasViewed
                      ? Border.all(
                        color: theme.colorScheme.outlineVariant,
                        width: 2,
                      )
                      : null,
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.surface,
              ),
              child: CircleAvatar(
                radius: 32,
                backgroundImage: CachedNetworkImageProvider(story.userAvatar),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            story.username,
            style: theme.textTheme.labelSmall,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
