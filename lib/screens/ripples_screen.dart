import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:go_router/go_router.dart';
import 'package:oasis_v2/services/ripples_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'dart:ui';

class RipplesScreen extends StatefulWidget {
  const RipplesScreen({super.key});

  @override
  State<RipplesScreen> createState() => _RipplesScreenState();
}

class _RipplesScreenState extends State<RipplesScreen> {
  late List<String> _videoUrls;
  final PageController _pageController = PageController();
  StreamSubscription? _sessionSub;
  int _currentIndex = 0;
  double _currentPage = 0.0;

  @override
  void initState() {
    super.initState();
    final ripplesService = context.read<RipplesService>();
    _videoUrls = ripplesService.fetchDummyVideos();

    _pageController.addListener(() {
      if (mounted) {
        setState(() {
          _currentPage = _pageController.page ?? 0.0;
        });
      }
    });

    _sessionSub = ripplesService.onSessionEnd.listen((_) {
      if (mounted) {
        context.go('/feed');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your Ripples session has ended. Time to reconnect!')),
        );
      }
    });
  }

  @override
  void dispose() {
    _sessionSub?.cancel();
    _pageController.dispose();
    super.dispose();
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
            Text('Experiment Lab', style: Theme.of(context).textTheme.titleLarge),
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
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(FluentIcons.dismiss_24_filled, color: Colors.white, size: 28),
          onPressed: () {
            context.read<RipplesService>().cancelSession();
            context.pop();
          },
        ),
        actions: [
          Consumer<RipplesService>(
            builder: (context, service, _) => IconButton(
              icon: const Icon(FluentIcons.beaker_24_regular, color: Colors.white),
              onPressed: () => _showLayoutSwitcher(context, service),
            ),
          ),
        ],
      ),
      body: Consumer<RipplesService>(
        builder: (context, service, _) {
          return Stack(
            children: [
              _buildActiveLayout(service.currentLayout),
              // The Floating Pill UI (Hidden in Mosaic Grid, but shown in its fullscreen expansion)
              if (service.currentLayout != RipplesLayoutType.choiceMosaic)
                const Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: FloatingActionPill(),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActiveLayout(RipplesLayoutType layout) {
    switch (layout) {
      case RipplesLayoutType.kineticCardStack:
        return _buildKineticCardStack();
      case RipplesLayoutType.focusDial:
        return _buildFocusDial();
      case RipplesLayoutType.choiceMosaic:
        return _buildChoiceMosaic();
      case RipplesLayoutType.rippleSwipe:
        return _buildRippleSwipe();
    }
  }

  Widget _buildKineticCardStack() {
    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      itemCount: _videoUrls.length,
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
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..scale(value)
                ..rotateX((_pageController.position.haveDimensions ? _pageController.page! - index : 0) * 0.5),
              child: Opacity(
                opacity: value,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 80.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: DummyVideoPlayer(url: _videoUrls[index], isPlaying: _currentIndex == index),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFocusDial() {
    return Stack(
      children: [
        DummyVideoPlayer(url: _videoUrls[_currentIndex], isPlaying: true),
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('DRAG TO SPIN • HOLD TO SCRUB', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 2)),
              const SizedBox(height: 12),
              GestureDetector(
                onHorizontalDragUpdate: (details) {
                  // Spin logic: move index based on drag distance
                  if (details.primaryDelta!.abs() > 20) {
                    if (details.primaryDelta! > 0 && _currentIndex > 0) {
                      setState(() => _currentIndex--);
                    } else if (details.primaryDelta! < 0 && _currentIndex < _videoUrls.length - 1) {
                      setState(() => _currentIndex++);
                    }
                  }
                },
                onLongPressStart: (_) {
                  // Fast scrubbing logic: jump to random or next
                  Timer.periodic(const Duration(milliseconds: 200), (timer) {
                    if (!mounted) {
                      timer.cancel();
                      return;
                    }
                    if (_currentIndex < _videoUrls.length - 1) {
                      setState(() => _currentIndex++);
                    } else {
                      setState(() => _currentIndex = 0);
                    }
                  });
                },
                child: Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 2),
                    gradient: SweepGradient(
                      colors: [Colors.white.withValues(alpha: 0.1), Colors.transparent, Colors.white.withValues(alpha: 0.1)],
                    ),
                  ),
                  child: const Center(
                    child: Icon(FluentIcons.navigation_24_filled, color: Colors.white, size: 40),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceMosaic() {
    return GridView.builder(
      padding: const EdgeInsets.only(top: 100, left: 8, right: 8, bottom: 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.7,
      ),
      itemCount: _videoUrls.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => FullScreenVideoView(url: _videoUrls[index]),
            ));
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Hero(
              tag: _videoUrls[index],
              child: Container(
                color: Colors.primaries[index % Colors.primaries.length].withValues(alpha: 0.3),
                child: const Center(child: Icon(FluentIcons.play_24_filled, color: Colors.white, size: 50)),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRippleSwipe() {
    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      itemCount: _videoUrls.length,
      onPageChanged: (index) => setState(() => _currentIndex = index),
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _pageController,
          builder: (context, child) {
            double pageOffset = _currentPage - index;
            
            // Bloom / Liquid logic
            // As pageOffset goes from 0 to 1, scale goes down and opacity fades
            // As pageOffset goes from -1 to 0, it expands from center
            
            double scale = 1.0;
            double opacity = 1.0;
            double radiusValue = 0.0;

            if (pageOffset > 0) {
              // Outgoing page
              scale = 1.0 - (pageOffset * 0.2);
              opacity = 1.0 - pageOffset;
            } else {
              // Incoming page
              radiusValue = (1.0 + pageOffset).clamp(0.0, 1.0);
            }

            return Stack(
              children: [
                if (pageOffset <= 0)
                  ClipPath(
                    clipper: CircularRevealClipper(fraction: radiusValue),
                    child: DummyVideoPlayer(url: _videoUrls[index], isPlaying: _currentIndex == index),
                  )
                else
                  Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: scale,
                      child: DummyVideoPlayer(url: _videoUrls[index], isPlaying: _currentIndex == index),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class CircularRevealClipper extends CustomClipper<Path> {
  final double fraction;
  CircularRevealClipper({required this.fraction});

  @override
  Path getClip(Size size) {
    double maxRadius = math.sqrt(size.width * size.width + size.height * size.height);
    double currentRadius = maxRadius * fraction;
    
    return Path()
      ..addOval(Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: currentRadius,
      ));
  }

  @override
  bool shouldReclip(CircularRevealClipper oldClipper) => oldClipper.fraction != fraction;
}

class FullScreenVideoView extends StatelessWidget {
  final String url;
  const FullScreenVideoView({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity! > 100) {
                Navigator.pop(context);
              }
            },
            child: Hero(
              tag: url,
              child: DummyVideoPlayer(url: url, isPlaying: true),
            ),
          ),
          // Ensure Floating Pill is visible here too as requested
          const Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: FloatingActionPill(),
          ),
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(FluentIcons.chevron_left_24_filled, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

class FloatingActionPill extends StatefulWidget {
  const FloatingActionPill({super.key});

  @override
  State<FloatingActionPill> createState() => _FloatingActionPillState();
}

class _FloatingActionPillState extends State<FloatingActionPill> {
  bool _isExpanded = false;
  bool _isLiked = false;
  Timer? _collapseTimer;

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    
    if (_isExpanded) {
      _collapseTimer?.cancel();
      _collapseTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _isExpanded = false);
      });
    }
  }

  @override
  void dispose() {
    _collapseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: _toggleExpand,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          height: 60,
          width: _isExpanded ? 260 : 100,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15), // More transparent/blended
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: SizedBox(
                  width: _isExpanded ? 260 : 100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(
                          _isLiked ? FluentIcons.heart_24_filled : FluentIcons.heart_24_regular, 
                          color: _isLiked ? Colors.redAccent : Colors.white,
                          size: 26,
                        ),
                        onPressed: () => setState(() => _isLiked = !_isLiked),
                      ),
                      if (_isExpanded) ...[
                        IconButton(
                          icon: const Icon(FluentIcons.comment_24_regular, color: Colors.white, size: 24),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(FluentIcons.share_24_regular, color: Colors.white, size: 24),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(FluentIcons.bookmark_24_regular, color: Colors.white, size: 24),
                          onPressed: () {},
                        ),
                      ] else
                        IconButton(
                          key: const ValueKey('expand_pill'),
                          icon: const Icon(FluentIcons.chevron_up_24_filled, color: Colors.white, size: 20),
                          onPressed: _toggleExpand,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DummyVideoPlayer extends StatefulWidget {
  final String url;
  final bool isPlaying;

  const DummyVideoPlayer({super.key, required this.url, required this.isPlaying});

  @override
  State<DummyVideoPlayer> createState() => _DummyVideoPlayerState();
}

class _DummyVideoPlayerState extends State<DummyVideoPlayer> {
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
  void didUpdateWidget(DummyVideoPlayer oldWidget) {
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
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller.value.size.width,
          height: _controller.value.size.height,
          child: VideoPlayer(_controller),
        ),
      ),
    );
  }
}
