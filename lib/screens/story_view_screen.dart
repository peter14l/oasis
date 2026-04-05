import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:oasis/models/story_model.dart';
import 'package:oasis/features/messages/domain/models/message.dart';
import 'package:oasis/services/stories_service.dart';
import 'package:oasis/services/messaging_service.dart';
import 'package:oasis/services/auth_service.dart';
import 'package:oasis/features/stories/presentation/widgets/story_viewers_sheet.dart';
import 'package:oasis/services/app_initializer.dart';
import 'package:oasis/core/utils/haptic_utils.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
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
  final StoriesService _storiesService = StoriesService();
  final MessagingService _messagingService = MessagingService();
  final AuthService _authService = AuthService();
  final AudioPlayer _audioPlayer = AudioPlayer();
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

  Future<void> _startStory() async {
    _animController.reset();
    _animController.duration = Duration(
      seconds: widget.stories[_currentIndex].duration,
    );
    _animController.forward();

    // Handle Music
    await _audioPlayer.stop();
    final story = widget.stories[_currentIndex];
    if (story.hasMusic && story.musicMetadata?.previewUrl != null) {
      await _audioPlayer.play(UrlSource(story.musicMetadata!.previewUrl));
    }
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
    _audioPlayer.pause();
  }

  void _resumeStory() {
    if (!_isPaused || _isReplying) return;
    setState(() {
      _isPaused = false;
    });
    _animController.forward();
    _audioPlayer.resume();
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
      final conversationId = await _messagingService.getOrCreateConversation(
        user1Id: currentUserId,
        user2Id: story.userId,
      );

      await _messagingService.sendMessage(
        conversationId: conversationId,
        senderId: currentUserId,
        content: text,
        messageType: MessageType.storyReply,
        storyId: story.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reply sent!'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      HapticUtils.success();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send reply: $e')));
      }
    }
  }

  void _showViewers() {
    _pauseStory();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) =>
              StoryViewersSheet(storyId: widget.stories[_currentIndex].id),
    ).then((_) => _resumeStory());
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    _replyController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_currentIndex];
    final isOwner = _authService.currentUser?.id == story.userId;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isM3E = themeProvider.isM3EEnabled;

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
                return _buildStoryBody(widget.stories[index], isM3E);
              },
            ),
          ),

          // Top Gradient Overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 160,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
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
              children:
                  widget.stories.asMap().entries.map((entry) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: _buildProgressBar(entry.key, isM3E),
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
                Container(
                  decoration: BoxDecoration(
                    shape: isM3E ? BoxShape.rectangle : BoxShape.circle,
                    borderRadius: isM3E ? BorderRadius.circular(12) : null,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundImage: CachedNetworkImageProvider(
                      story.userAvatar,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        story.username,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: isM3E ? FontWeight.w800 : FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: isM3E ? -0.5 : null,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            _getTimeAgo(story.createdAt),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                          ),
                          if (story.hasMusic) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.music_note, color: Colors.white70, size: 10),
                            const SizedBox(width: 4),
                            Text(
                              story.musicMetadata!.title,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
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
            child:
                isOwner
                    ? _buildOwnerControls(story)
                    : _buildViewerControls(isM3E),
          ),

          // Story Caption
          if (story.caption != null &&
              story.caption!.isNotEmpty &&
              !_isReplying)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 80,
              left: 32,
              right: 32,
              child: Text(
                story.caption!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: isM3E ? FontWeight.bold : null,
                  shadows: const [
                    Shadow(
                      blurRadius: 10,
                      color: Colors.black,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStoryBody(StoryModel story, bool isM3E) {
    return Stack(
      children: [
        Positioned.fill(
          child: CachedNetworkImage(
            imageUrl: story.mediaUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
            errorWidget: (context, url, error) => const Center(
              child: Icon(Icons.error, color: Colors.white54),
            ),
          ),
        ),
        
        // Music Sticker Overlay
        if (story.hasMusic)
          _buildMusicStickerOverlay(story.musicMetadata!, isM3E),

        // Interactive Text Layers Overlay
        if (story.interactiveMetadata != null)
          ...story.interactiveMetadata!.map((sticker) => _buildInteractiveLayer(sticker, isM3E)),
      ],
    );
  }

  Widget _buildMusicStickerOverlay(StoryMusic music, bool isM3E) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(isM3E ? 20 : 12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(isM3E ? 8 : 4),
              child: CachedNetworkImage(
                imageUrl: music.albumArtUrl,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  music.title,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: isM3E ? FontWeight.w900 : FontWeight.bold,
                  ),
                ),
                Text(
                  music.artist,
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            const Icon(Icons.music_note, color: Colors.black, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveLayer(StorySticker sticker, bool isM3E) {
    if (sticker.type == 'text') {
      final colorHex = sticker.data['color'] as String;
      final color = Color(int.parse(colorHex.replaceFirst('#', '0xff')));
      final backgroundMode = sticker.data['background_mode'] as int;
      
      return Positioned(
        left: sticker.x * MediaQuery.of(context).size.width - 100,
        top: sticker.y * MediaQuery.of(context).size.height - 25,
        child: Container(
          width: 200,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: backgroundMode == 1 
                ? color.withValues(alpha: 0.9) 
                : (backgroundMode == 2 ? Colors.black54 : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            sticker.data['text'],
            textAlign: TextAlign.center,
            style: TextStyle(
              color: backgroundMode == 1 
                  ? (color.computeLuminance() > 0.5 ? Colors.black : Colors.white) 
                  : color,
              fontSize: 28,
              fontWeight: isM3E ? FontWeight.w900 : FontWeight.bold,
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildProgressBar(int index, bool isM3E) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(isM3E ? 4 : 2),
      child: Container(
        height: isM3E ? 4 : 3,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3)),
        child:
            index < _currentIndex
                ? const Divider(color: Colors.white, thickness: 4, height: 4)
                : index == _currentIndex
                ? AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) {
                    return FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _animController.value,
                      child: Divider(
                        color: Colors.white,
                        thickness: isM3E ? 4 : 3,
                        height: isM3E ? 4 : 3,
                      ),
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
                  Icon(
                    Icons.visibility,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 14,
                  ),
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

  Widget _buildViewerControls(bool isM3E) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: isM3E ? 56 : 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isM3E ? 28 : 24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
              color: isM3E ? Colors.white.withValues(alpha: 0.1) : null,
            ),
            child: TextField(
              controller: _replyController,
              onTap: () {
                _pauseStory();
                setState(() => _isReplying = true);
              },
              onSubmitted: _sendReply,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Send message...',
                hintStyle: const TextStyle(color: Colors.white70, fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: isM3E ? 14 : 10,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          icon: Icon(
            Icons.favorite_border,
            color: Colors.white,
            size: isM3E ? 32 : 28,
          ),
          onPressed: () {
            _storiesService.reactToStory(
              widget.stories[_currentIndex].id,
              '❤️',
            );
            HapticUtils.lightImpact();
          },
        ),
        IconButton(
          icon: Icon(
            Icons.send_outlined,
            color: Colors.white,
            size: isM3E ? 32 : 28,
          ),
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
