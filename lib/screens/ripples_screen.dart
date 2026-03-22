import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:go_router/go_router.dart';
import 'package:oasis_v2/services/ripples_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ui';
import 'package:oasis_v2/widgets/share_sheet.dart';
import 'package:oasis_v2/models/message.dart';
import 'package:oasis_v2/services/supabase_service.dart';

class RipplesScreen extends StatefulWidget {
  const RipplesScreen({super.key});

  @override
  State<RipplesScreen> createState() => _RipplesScreenState();
}

class _RipplesScreenState extends State<RipplesScreen> {
  List<Map<String, dynamic>> _ripples = [];
  final PageController _pageController = PageController();
  StreamSubscription? _sessionSub;
  int _currentIndex = 0;
  bool _isLoading = true;
  DateTime? _sessionStartTime;

  @override
  void initState() {
    super.initState();
    _sessionStartTime = DateTime.now();
    _loadRipples();

    final ripplesService = context.read<RipplesService>();
    _sessionSub = ripplesService.onSessionEnd.listen((_) {
      if (mounted) {
        context.go('/feed');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your Ripples session has ended. Time to reconnect!')),
        );
      }
    });
  }

  Future<void> _loadRipples() async {
    final ripples = await context.read<RipplesService>().getRipples();
    if (mounted) {
      setState(() {
        _ripples = ripples;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _sessionSub?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _handleExit() {
    if (_sessionStartTime != null) {
      final elapsed = DateTime.now().difference(_sessionStartTime!);
      final service = context.read<RipplesService>();
      if (service.remainingDuration != null) {
        final newRemaining = service.remainingDuration! - elapsed;
        if (newRemaining.isNegative) {
          service.endSession();
        } else {
          service.pauseSession(newRemaining);
        }
      }
    }
    context.pop();
  }

  void _showLayoutSwitcher(BuildContext context, RipplesService service) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Layout Style', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ...RipplesLayoutType.values.map((type) {
              return RadioListTile<RipplesLayoutType>(
                title: Text(type.name.replaceAll(RegExp(r'(?=[A-Z])'), ' ').toUpperCase()),
                value: type,
                groupValue: service.currentLayout,
                onChanged: (val) {
                  if (val != null) {
                    service.setLayoutPreference(val);
                    Navigator.pop(context);
                  }
                },
              );
            }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ripplesService = context.watch<RipplesService>();
    final isDesktop = MediaQuery.of(context).size.width >= 1000;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (isDesktop && _ripples.isNotEmpty && _currentIndex < _ripples.length)
            Positioned.fill(
              child: Image.network(
                _ripples[_currentIndex]['thumbnail_url'] ?? '',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: Colors.black),
              ),
            ),
          if (isDesktop)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(color: Colors.black.withValues(alpha: 0.5)),
              ),
            ),
          
          Center(
            child: Container(
              constraints: isDesktop ? const BoxConstraints(maxWidth: 500) : null,
              child: AspectRatio(
                aspectRatio: isDesktop ? 9 / 16 : MediaQuery.of(context).size.aspectRatio,
                child: ClipRRect(
                  borderRadius: isDesktop ? BorderRadius.circular(8) : BorderRadius.zero,
                  child: Stack(
                    children: [
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator(color: Colors.white24))
                      else if (_ripples.isEmpty)
                        const Center(child: Text('No ripples yet. Be the first to share one!', style: TextStyle(color: Colors.white54)))
                      else
                        _buildActiveLayout(ripplesService.currentLayout),

                      // Custom AppBar inside the aspect ratio container on desktop
                      Positioned(
                        top: (isDesktop ? 20 : MediaQuery.of(context).padding.top + 10),
                        left: 16,
                        right: 16,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildGlassCircleButton(
                              icon: FluentIcons.dismiss_24_filled,
                              onTap: _handleExit,
                            ),
                            _buildGlassCircleButton(
                              icon: FluentIcons.grid_24_regular,
                              onTap: () => _showLayoutSwitcher(context, ripplesService),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCircleButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveLayout(RipplesLayoutType layout) {
    switch (layout) {
      case RipplesLayoutType.kineticCardStack:
        return _buildKineticCardStack();
      case RipplesLayoutType.choiceMosaic:
        return _buildChoiceMosaic();
    }
  }

  Widget _buildKineticCardStack() {
    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      itemCount: _ripples.length,
      onPageChanged: (index) => setState(() => _currentIndex = index),
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _pageController,
          builder: (context, child) {
            double value = 1.0;
            if (_pageController.position.haveDimensions) {
              value = _pageController.page! - index;
              value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
            }
            return Transform(
              alignment: Alignment.center,
              transform:
                  Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..scale(value)
                    ..rotateX(
                      (_pageController.position.haveDimensions
                              ? _pageController.page! - index
                              : 0) *
                          0.5,
                    ),
              child: Opacity(
                opacity: value,
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 0.0,
                        vertical: 0.0,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(0),
                        child: RippleVideoPlayer(
                          url: _ripples[index]['video_url'],
                          isPlaying: _currentIndex == index,
                        ),
                      ),
                    ),
                    if (_currentIndex == index)
                      Positioned(
                        bottom: 90,
                        left: 16,
                        right: 16,
                        child: Center(
                          child: DynamicRipplePill(ripple: _ripples[index]),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChoiceMosaic() {
    return GridView.builder(
      padding: const EdgeInsets.only(top: 120, left: 16, right: 16, bottom: 40),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.65,
      ),
      itemCount: _ripples.length,
      itemBuilder: (context, index) {
        final ripple = _ripples[index];
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => FullScreenRippleView(ripple: ripple),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (ripple['thumbnail_url'] != null)
                  Image.network(ripple['thumbnail_url'], fit: BoxFit.cover)
                else
                  Container(color: Colors.grey.withValues(alpha: 0.2)),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                const Center(
                  child: Icon(
                    FluentIcons.play_24_filled,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                Positioned(
                  left: 12,
                  bottom: 12,
                  right: 12,
                  child: Text(
                    ripple['profiles']['username'] ?? 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class DynamicRipplePill extends StatefulWidget {
  final Map<String, dynamic> ripple;
  const DynamicRipplePill({super.key, required this.ripple});

  @override
  State<DynamicRipplePill> createState() => _DynamicRipplePillState();
}

class _DynamicRipplePillState extends State<DynamicRipplePill> {
  bool _isExpanded = false;
  bool _isLiked = false;
  bool _isSaved = false;
  late int _likesCount;
  late int _commentsCount;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.ripple['likes_count'] ?? 0;
    _commentsCount = widget.ripple['comments_count'] ?? 0;
    _isLiked = widget.ripple['is_liked'] ?? false;
    _isSaved = widget.ripple['is_saved'] ?? false;
  }

  void _showComments() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RippleCommentsSheet(rippleId: widget.ripple['id']),
    );
    // Ideally update comment count here if changed
  }

  void _shareRipple() {
    ShareSheet.show(
      context,
      title: 'Share Ripple',
      payload: widget.ripple['caption'] ?? 'Check out this Ripple!',
      messageType: MessageType.ripple,
      rippleId: widget.ripple['id'],
    );
  }

  void _toggleLike() {
    final service = context.read<RipplesService>();
    setState(() {
      if (_isLiked) {
        _likesCount--;
        _isLiked = false;
        service.unlikeRipple(widget.ripple['id']);
      } else {
        _likesCount++;
        _isLiked = true;
        service.likeRipple(widget.ripple['id']);
      }
      if (_likesCount < 0) _likesCount = 0;
    });
  }

  void _toggleSave() {
    final service = context.read<RipplesService>();
    setState(() {
      if (_isSaved) {
        _isSaved = false;
        service.unsaveRipple(widget.ripple['id']);
      } else {
        _isSaved = true;
        service.saveRipple(widget.ripple['id']);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final username = widget.ripple['profiles']['username'] ?? 'User';
    final avatarUrl = widget.ripple['profiles']['avatar_url'];
    final caption = widget.ripple['caption'];

    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            width: MediaQuery.of(context).size.width * 0.85,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Avatar & Text
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage:
                          avatarUrl != null ? NetworkImage(avatarUrl) : null,
                      child:
                          avatarUrl == null
                              ? const Icon(Icons.person, size: 20)
                              : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (caption != null)
                            AnimatedCrossFade(
                              duration: const Duration(milliseconds: 200),
                              crossFadeState:
                                  _isExpanded
                                      ? CrossFadeState.showSecond
                                      : CrossFadeState.showFirst,
                              firstChild: Text(
                                caption,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              secondChild: Text(
                                caption,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Expanded Action Row
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  child: Container(
                    height: _isExpanded ? null : 0,
                    child: Opacity(
                      opacity: _isExpanded ? 1.0 : 0.0,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildActionPill(
                              icon:
                                  _isLiked
                                      ? FluentIcons.heart_24_filled
                                      : FluentIcons.heart_24_regular,
                              color: _isLiked ? Colors.redAccent : Colors.white,
                              label: '$_likesCount',
                              onTap: _toggleLike,
                            ),
                            _buildActionPill(
                              icon: FluentIcons.comment_24_regular,
                              label: '$_commentsCount',
                              onTap: _showComments,
                            ),
                            _buildActionPill(
                              icon:
                                  _isSaved
                                      ? FluentIcons.bookmark_24_filled
                                      : FluentIcons.bookmark_24_regular,
                              color:
                                  _isSaved ? Colors.blueAccent : Colors.white,
                              label: 'Save',
                              onTap: _toggleSave,
                            ),
                            _buildActionPill(
                              icon: FluentIcons.share_24_regular,
                              label: 'Share',
                              onTap: _shareRipple,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    Color color = Colors.white,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class RippleCommentsSheet extends StatefulWidget {
  final String rippleId;
  const RippleCommentsSheet({super.key, required this.rippleId});

  @override
  State<RippleCommentsSheet> createState() => _RippleCommentsSheetState();
}

class _RippleCommentsSheetState extends State<RippleCommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  List<dynamic> _comments = [];
  bool _isLoading = true;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      if (path != null) {
        _uploadVoiceComment(path);
      }
    } else {
      if (await _audioRecorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/ripple_comment_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(const RecordConfig(), path: path);
        setState(() => _isRecording = true);
      }
    }
  }

  Future<void> _uploadVoiceComment(String path) async {
    // Implement voice comment upload logic here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voice comments coming soon!')),
    );
  }

  Future<void> _loadComments() async {
    final supabase = SupabaseService().client;
    try {
      final response = await supabase
          .from('ripple_comments')
          .select('*, profiles:user_id(username, avatar_url)')
          .eq('ripple_id', widget.rippleId)
          .order('created_at', ascending: true);
      
      if (mounted) {
        setState(() {
          _comments = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;
    
    final service = context.read<RipplesService>();
    await service.commentOnRipple(widget.rippleId, _commentController.text.trim());
    _commentController.clear();
    _loadComments();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 32, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('Comments', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _comments.length,
                  itemBuilder: (context, index) {
                    final comment = _comments[index];
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundImage: comment['profiles']['avatar_url'] != null ? NetworkImage(comment['profiles']['avatar_url']) : null,
                      ),
                      title: Text(comment['profiles']['username'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text(comment['content'], style: const TextStyle(fontSize: 14)),
                    );
                  },
                ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 16, left: 16, right: 16, top: 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(_isRecording ? Icons.stop_circle : Icons.mic_none_rounded, 
                    color: _isRecording ? Colors.red : Colors.white54),
                  onPressed: _toggleRecording,
                ),
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: _isRecording ? 'Recording...' : 'Add a comment...',
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(FluentIcons.send_24_filled, color: Colors.blueAccent),
                  onPressed: _isRecording ? null : _postComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FullScreenRippleView extends StatelessWidget {
  final Map<String, dynamic> ripple;
  const FullScreenRippleView({super.key, required this.ripple});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          RippleVideoPlayer(url: ripple['video_url'], isPlaying: true),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: IconButton(
              icon: const Icon(
                FluentIcons.chevron_left_24_filled,
                color: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 16,
            right: 16,
            child: Center(child: DynamicRipplePill(ripple: ripple)),
          ),
        ],
      ),
    );
  }
}

class RippleVideoPlayer extends StatefulWidget {
  final String url;
  final bool isPlaying;

  const RippleVideoPlayer({super.key, required this.url, required this.isPlaying});

  @override
  State<RippleVideoPlayer> createState() => _RippleVideoPlayerState();
}

class _RippleVideoPlayerState extends State<RippleVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
            _controller.setLooping(true);
            if (widget.isPlaying) _controller.play();
          });
        }
      });
  }

  @override
  void didUpdateWidget(RippleVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPlaying != widget.isPlaying) {
      if (widget.isPlaying) {
        _controller.play();
      } else {
        _controller.pause();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator(color: Colors.white24)),
      );
    }
    
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: _controller.value.size.width,
          height: _controller.value.size.height,
          child: VideoPlayer(_controller),
        ),
      ),
    );
  }
}
