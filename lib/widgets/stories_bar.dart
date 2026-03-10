import 'package:morrow_v2/widgets/skeleton_container.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:morrow_v2/models/story_model.dart';
import 'package:morrow_v2/screens/stories/create_story_screen.dart';
import 'package:morrow_v2/services/auth_service.dart';

class StoriesBar extends StatefulWidget {
  final List<StoryGroup> storyGroups;
  final List<StoryModel>? currentUserStories;
  final bool isLoading;
  final VoidCallback? onRefresh;

  const StoriesBar({
    super.key,
    required this.storyGroups,
    this.currentUserStories,
    this.isLoading = false,
    this.onRefresh,
  });

  @override
  State<StoriesBar> createState() => _StoriesBarState();
}

class _StoriesBarState extends State<StoriesBar> {
  final AuthService _authService = AuthService();

  Widget _buildYourStoryButton(BuildContext context, ThemeData theme) {
    final currentUser = _authService.currentUser;
    final hasOwnStories = widget.currentUserStories?.isNotEmpty ?? false;
    final hasUnviewedOwnStories =
        widget.currentUserStories?.any((s) => !s.hasViewed) ?? false;

    return GestureDetector(
      onTap: () async {
        if (hasOwnStories) {
          // View own stories
          context.push(
            '/story/${widget.currentUserStories!.first.id}',
            extra: widget.currentUserStories,
          );
        } else {
          // Create new story
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CreateStoryScreen()),
          );

          if (result == true && widget.onRefresh != null) {
            widget.onRefresh!();
          }
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient:
                      hasOwnStories && hasUnviewedOwnStories
                          ? LinearGradient(
                            colors: [
                              theme.primaryColor,
                              theme.colorScheme.secondary,
                            ],
                          )
                          : null,
                  border:
                      hasOwnStories && !hasUnviewedOwnStories
                          ? Border.all(color: Colors.grey.shade300, width: 2)
                          : (!hasOwnStories
                              ? Border.all(
                                color: theme.colorScheme.outlineVariant,
                              )
                              : null),
                ),
                padding: const EdgeInsets.all(3),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.scaffoldBackgroundColor,
                      width: hasOwnStories ? 3 : 0,
                    ),
                  ),
                  child:
                      hasOwnStories && currentUser?.photoUrl != null
                          ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: currentUser!.photoUrl!,
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) =>
                                      Container(color: Colors.grey.shade200),
                              errorWidget:
                                  (context, url, error) => Container(
                                    color: Colors.grey.shade200,
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.grey,
                                    ),
                                  ),
                            ),
                          )
                          : Center(
                            child: Icon(
                              Icons.add,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                ),
              ),
              // Add button overlay when user has stories
              if (hasOwnStories)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CreateStoryScreen(),
                        ),
                      );
                      if (result == true && widget.onRefresh != null) {
                        widget.onRefresh!();
                      }
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary,
                        border: Border.all(
                          color: theme.scaffoldBackgroundColor,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 70,
            child: Text(
              'Your Story',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryGroupCircle(
    BuildContext context,
    ThemeData theme,
    StoryGroup group,
  ) {
    return GestureDetector(
      onTap: () {
        // Navigate to story viewer with all stories from this user
        if (group.stories.isNotEmpty) {
          context.push(
            '/story/${group.stories.first.id}',
            extra: group.stories,
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient:
                  group.hasUnviewed
                      ? LinearGradient(
                        colors: [
                          theme.primaryColor,
                          theme.colorScheme.secondary,
                        ],
                      )
                      : null,
              border:
                  !group.hasUnviewed
                      ? Border.all(color: Colors.grey.shade300, width: 2)
                      : null,
            ),
            padding: const EdgeInsets.all(3),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.scaffoldBackgroundColor,
                  width: 3,
                ),
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: group.avatarUrl,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Container(color: Colors.grey.shade200),
                  errorWidget:
                      (context, url, error) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.person, color: Colors.grey),
                      ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 70,
            child: Text(
              group.username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    group.hasUnviewed ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = _authService.currentUser?.id;

    // Filter out current user's stories from groups (they go in "Your Story")
    final otherUserGroups =
        widget.storyGroups
            .where((group) => group.userId != currentUserId)
            .toList();

    return SliverToBoxAdapter(
      child: Container(
        height: 110,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: widget.isLoading ? 6 : otherUserGroups.length + 1,
          separatorBuilder: (context, index) => const SizedBox(width: 16),
          itemBuilder: (context, index) {
            if (widget.isLoading) {
              return Column(
                children: [
                  const SkeletonContainer.circular(size: 70),
                  const SizedBox(height: 4),
                  const SkeletonContainer.rounded(width: 50, height: 10),
                ],
              );
            }

            if (index == 0) {
              return _buildYourStoryButton(context, theme);
            }

            final group = otherUserGroups[index - 1];
            return _buildStoryGroupCircle(context, theme, group);
          },
        ),
      ),
    );
  }
}
