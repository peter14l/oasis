import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:morrow_v2/models/story_model.dart';
import 'package:morrow_v2/services/stories_service.dart';
import 'package:go_router/go_router.dart';

class StoryRing extends StatelessWidget {
  final StoryGroup storyGroup;
  final VoidCallback? onTap;

  const StoryRing({super.key, required this.storyGroup, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient:
                  storyGroup.hasUnviewed
                      ? LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      )
                      : null,
              border:
                  !storyGroup.hasUnviewed
                      ? Border.all(color: Colors.grey.shade300, width: 2)
                      : null,
            ),
            padding: const EdgeInsets.all(3),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 3,
                ),
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: storyGroup.avatarUrl,
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
              storyGroup.username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    storyGroup.hasUnviewed
                        ? FontWeight.w600
                        : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StoriesBar extends StatefulWidget {
  const StoriesBar({super.key});

  @override
  State<StoriesBar> createState() => _StoriesBarState();
}

class _StoriesBarState extends State<StoriesBar> {
  final _storiesService = StoriesService();
  List<StoryGroup> _storyGroups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories() async {
    setState(() => _isLoading = true);
    try {
      final groups = await _storiesService.getFollowingStories();
      if (mounted) {
        setState(() {
          _storyGroups = groups;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openStoryViewer(StoryGroup group) async {
    // Load stories for this user
    final stories = await _storiesService.getUserStories(group.userId);
    if (stories.isEmpty || !mounted) return;

    // Navigate to story viewer
    context.push('/stories/${group.userId}', extra: stories);
  }

  void _createStory() {
    context.push('/stories/create').then((result) {
      if (result == true) {
        _loadStories(); // Refresh stories after creation
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: 5,
          itemBuilder:
              (context, index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade200,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 50,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
        ),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _storyGroups.length + 1, // +1 for "Add Story" button
        itemBuilder: (context, index) {
          if (index == 0) {
            // Add Story button
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: _createStory,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade200,
                      ),
                      child: Icon(
                        Icons.add,
                        size: 32,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const SizedBox(
                      width: 70,
                      child: Text(
                        'Your Story',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final storyGroup = _storyGroups[index - 1];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: StoryRing(
              storyGroup: storyGroup,
              onTap: () => _openStoryViewer(storyGroup),
            ),
          );
        },
      ),
    );
  }
}
