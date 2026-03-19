import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:oasis_v2/models/story_model.dart';
import 'package:oasis_v2/services/stories_service.dart';
import 'package:oasis_v2/services/messaging_service.dart';
import 'package:oasis_v2/services/auth_service.dart';
import 'package:oasis_v2/widgets/stories/story_viewers_sheet.dart';
import 'package:oasis_v2/utils/haptic_utils.dart';
import 'dart:async';
import 'dart:ui';

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
  final StoriesService _storiesService = StoriesService();
  final MessagingService _messagingService = MessagingService();
  final AuthService _authService = AuthService();
  final TextEditingController _replyController = TextEditingController();

  int _currentIndex = 0;
  bool _isPaused = false;
  bool _isReplying = false;

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
      duration: Duration(seconds: widget.stories[_currentIndex].duration),
    );

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStory();
      }
    });

    _startStory();
    _markAsViewed();
  }

  void _markAsViewed() {
    final story = widget.stories[_currentIndex];
    if (!story.hasViewed) {
      _storiesService.viewStory(story.id);
    }
  }

  void _startStory() {
    _animController.reset();
    _animController.duration = Duration(seconds: widget.stories[_currentIndex].duration);
    _animController.forward();
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _pageController.jumpToPage(_currentIndex);
      _startStory();
      _markAsViewed();
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
      _markAsViewed();
    } else {
      _startStory();
    }
  }

  void _pauseStory() {
    if (_isPaused) return;
    setState(() {
      _isPaused = true;
    });
    _animController.stop();
  }

  void _resumeStory() {
    if (!_isPaused || _isReplying) return;
    setState(() {
      _isPaused = false;
    });
    _animController.forward();
  }

  Future<void> _sendReply(String text) async {
    if (text.trim().isEmpty) return;

    final story = widget.stories[_currentIndex];
    final currentUserId = _authService.currentUser?.id;
    if (currentUserId == null) return;

    setState(() {
      _isReplying = false;
      _isPaused = false;
    });
    
    _replyController.clear();
    FocusScope.of(context).unfocus();
    _resumeStory();

    try {
      // 1. Get or create conversation with story owner
      final conversationId = await _messagingService.getOrCreateConversation(
        user1Id: currentUserId,
        user2Id: story.userId,
      );

      // 2. Send message with story context (simplified for now as text)
      await _messagingService.sendMessage(
        conversationId: conversationId,
        senderId: currentUserId,
        content: "Replied to your story: \"$text\"",
        // In a real app, we might add a 'metadata' field to link the story
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reply sent!'), duration: Duration(seconds: 1)),
        );
      }
      HapticUtils.success();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send reply: $e')),
        );
      }
    }
  }

  void _showViewers() {
    _pauseStory();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StoryViewersSheet(storyId: widget.stories[_currentIndex].id),
    ).then((_) => _resumeStory());
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_currentIndex];
    final isOwner = _authService.currentUser?.id == story.userId;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Story Content
          GestureDetector(
            onTapDown: (details) => _pauseStory(),
            onTapUp: (details) {
              if (_isReplying) return;
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
              } else if (details.primaryVelocity! < -500 && isOwner) {
                _showViewers();
              }
            },
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.stories.length,
              itemBuilder: (context, index) {
                return _buildStoryContent(widget.stories[index]);
              },
            ),
          ),

          // Top Gradient Overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 160,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Progress Bars
          Positioned(
            top: 60,
            left: 12,
            right: 12,
            child: Row(
              children: widget.stories.asMap().entries.map((entry) {
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
            top: 75,
            left: 16,
            right: 16,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: CachedNetworkImageProvider(story.userAvatar),
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
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _getTimeAgo(story.createdAt),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz, color: Colors.white),
                  onPressed: () {
                    // Show options (Delete if owner, Report if not)
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => context.pop(),
                ),
              ],
            ),
          ),

          // Bottom Controls
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 16,
            right: 16,
            child: isOwner 
              ? _buildOwnerControls(story)
              : _buildViewerControls(),
          ),

          // Story Caption
          if (story.caption != null && story.caption!.isNotEmpty && !_isReplying)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 80,
              left: 32,
              right: 32,
              child: Text(
                story.caption!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  shadows: [
                    Shadow(blurRadius: 10, color: Colors.black, offset: Offset(0, 2)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStoryContent(StoryModel story) {
    return CachedNetworkImage(
      imageUrl: story.mediaUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
      ),
      errorWidget: (context, url, error) => const Center(
        child: Icon(Icons.error, color: Colors.white54),
      ),
    );
  }

  Widget _buildProgressBar(int index) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: Container(
        height: 3,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.3),
        ),
        child: index < _currentIndex
            ? const Divider(color: Colors.white, thickness: 3, height: 3)
            : index == _currentIndex
                ? AnimatedBuilder(
                    animation: _animController,
                    builder: (context, child) {
                      return FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _animController.value,
                        child: const Divider(color: Colors.white, thickness: 3, height: 3),
                      );
                    },
                  )
                : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildOwnerControls(StoryModel story) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _showViewers,
          child: Column(
            children: [
              const Icon(Icons.keyboard_arrow_up, color: Colors.white),
              Text(
                'Activity',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.visibility, color: Colors.white.withValues(alpha: 0.7), size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${story.viewCount}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildViewerControls() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
            ),
            child: TextField(
              controller: _replyController,
              onTap: () {
                _pauseStory();
                setState(() => _isReplying = true);
              },
              onSubmitted: _sendReply,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Send message...',
                hintStyle: TextStyle(color: Colors.white70, fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          icon: const Icon(Icons.favorite_border, color: Colors.white, size: 28),
          onPressed: () {
            _storiesService.reactToStory(widget.stories[_currentIndex].id, '❤️');
            HapticUtils.lightImpact();
          },
        ),
        IconButton(
          icon: const Icon(Icons.send_outlined, color: Colors.white, size: 28),
          onPressed: () {
            // Share story
          },
        ),
      ],
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inHours > 0) return '${difference.inHours}h';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m';
    return 'Just now';
  }
}
