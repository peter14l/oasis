import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:morrow_v2/models/story_model.dart';
import 'dart:async';

class StoryViewScreen extends StatefulWidget {
  final String initialStoryId;
  final List<StoryModel> stories;

  const StoryViewScreen({
    super.key,
    required this.initialStoryId,
    required this.stories,
  });

  @override
  State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animController;
  int _currentIndex = 0;
  bool _isPaused = false;

  // Duration for each story item
  final Duration _storyDuration = const Duration(seconds: 10);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.stories.indexWhere(
      (s) => s.id == widget.initialStoryId,
    );
    if (_currentIndex == -1) _currentIndex = 0;

    _pageController = PageController(initialPage: _currentIndex);

    _animController = AnimationController(
      vsync: this,
      duration: _storyDuration,
    );

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStory();
      }
    });

    _startStory();
  }

  void _startStory() {
    _animController.reset();
    _animController.forward();
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _pageController.jumpToPage(_currentIndex);
      _startStory();
    } else {
      context.pop();
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _pageController.jumpToPage(_currentIndex);
      _startStory();
    } else {
      _startStory(); // Restart current if it's the first one
    }
  }

  void _pauseStory() {
    setState(() {
      _isPaused = true;
    });
    _animController.stop();
  }

  void _resumeStory() {
    setState(() {
      _isPaused = false;
    });
    _animController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) => _pauseStory(),
        onTapUp: (details) {
          _resumeStory();
          final width = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < width / 3) {
            _previousStory();
          } else {
            _nextStory();
          }
        },
        onLongPressStart: (_) => _pauseStory(),
        onLongPressEnd: (_) => _resumeStory(),
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity! > 500) {
            context.pop();
          }
        },
        child: Stack(
          children: [
            // Story Content
            PageView.builder(
              controller: _pageController,
              physics:
                  const NeverScrollableScrollPhysics(), // Disable swipe to change page manually
              itemCount: widget.stories.length,
              itemBuilder: (context, index) {
                return _buildStoryContent(widget.stories[index]);
              },
            ),

            // Top Gradient Overlay for text visibility
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 120,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // Progress Bar
            Positioned(
              top: 50,
              left: 10,
              right: 10,
              child: Row(
                children:
                    widget.stories.asMap().entries.map((entry) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0),
                          child: _buildProgressBar(entry.key),
                        ),
                      );
                    }).toList(),
              ),
            ),

            // User Info & Close
            Positioned(
              top: 65,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: CachedNetworkImageProvider(
                      story.userAvatar,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          story.username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _getTimeAgo(story.createdAt),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryContent(StoryModel story) {
    if (story.mediaType == 'video') {
      // Placeholder for video support - would ideally use a VideoPlayerController here
      // For now treating as image/mockup or showing icon
      return Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl:
                story
                    .mediaUrl, // Thumbnail or video URL if supported by image widget
            fit: BoxFit.cover,
            errorWidget:
                (context, url, error) => Container(
                  color: Colors.grey[900],
                  child: const Center(
                    child: Icon(
                      Icons.videocam_off,
                      color: Colors.white54,
                      size: 50,
                    ),
                  ),
                ),
          ),
          const Center(
            child: Icon(
              Icons.play_circle_outline,
              color: Colors.white70,
              size: 80,
            ),
          ),
        ],
      );
    }

    return CachedNetworkImage(
      imageUrl: story.mediaUrl,
      fit: BoxFit.cover,
      placeholder:
          (context, url) => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
      errorWidget:
          (context, url, error) => Container(
            color: Colors.grey[900],
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.white54, size: 50),
                SizedBox(height: 8),
                Text(
                  "Could not load story",
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildProgressBar(int index) {
    if (index < _currentIndex) {
      // Completed stories
      return const LinearProgressIndicator(
        value: 1.0,
        backgroundColor: Colors.white24,
        valueColor: AlwaysStoppedAnimation(Colors.white),
      );
    } else if (index == _currentIndex) {
      // Current story animated
      return AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          return LinearProgressIndicator(
            value: _animController.value,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation(Colors.white),
          );
        },
      );
    } else {
      // Future stories
      return const LinearProgressIndicator(
        value: 0.0,
        backgroundColor: Colors.white24,
        valueColor: AlwaysStoppedAnimation(Colors.white),
      );
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Just now';
    }
  }
}
