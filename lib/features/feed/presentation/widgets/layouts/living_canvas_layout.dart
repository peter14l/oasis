import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oasis/features/feed/presentation/providers/feed_provider.dart';
import 'package:oasis/core/utils/responsive_layout.dart';
import 'package:oasis/themes/app_colors.dart';

class LivingCanvasLayout extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final Widget mobileHeader;
  final Widget Function(dynamic post, FeedProvider provider, bool isDesktopPadding) buildPostItem;

  const LivingCanvasLayout({
    super.key,
    required this.onRefresh,
    required this.mobileHeader,
    required this.buildPostItem,
  });

  @override
  State<LivingCanvasLayout> createState() => _LivingCanvasLayoutState();
}

class _LivingCanvasLayoutState extends State<LivingCanvasLayout> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {}); // For fiber animation/offset updates
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Stack(
      children: [
        // The "Canvas" Background
        Container(color: OasisColors.deep),
        
        // Fiber Painter
        Positioned.fill(
          child: CustomPaint(
            painter: FiberPainter(
              scrollOffset: _scrollController.hasClients ? _scrollController.offset : 0,
              color: OasisColors.glow.withValues(alpha: 0.1),
            ),
          ),
        ),

        RefreshIndicator(
          onRefresh: widget.onRefresh,
          child: Consumer<FeedProvider>(
            builder: (context, provider, _) {
              final posts = provider.posts;
              if (provider.isLoading && posts.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              return ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.only(
                  top: isDesktop ? 40 : 100,
                  bottom: 120,
                  left: isDesktop ? 100 : 16,
                  right: isDesktop ? 100 : 16,
                ),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: _buildOrganicPost(post, provider, isDesktop),
                  );
                },
              );
            },
          ),
        ),

        // Mobile Overlay Header
        if (!isDesktop)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              color: OasisColors.deep.withValues(alpha: 0.8),
              child: widget.mobileHeader,
            ),
          ),
      ],
    );
  }

  Widget _buildOrganicPost(dynamic post, FeedProvider provider, bool isDesktop) {
    // This layout removes the "Card" container metaphor
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(40),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: widget.buildPostItem(post, provider, isDesktop),
        ),
      ),
    );
  }
}

class FiberPainter extends CustomPainter {
  final double scrollOffset;
  final Color color;

  FiberPainter({required this.scrollOffset, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    
    // Draw some flowing fibers that move with scroll
    for (int i = 0; i < 5; i++) {
      double xStart = size.width * (0.2 + (i * 0.15));
      double xControl = xStart + (size.width * 0.1 * (i % 2 == 0 ? 1 : -1));
      
      path.moveTo(xStart, -500 + (scrollOffset * 0.2));
      path.quadraticBezierTo(
        xControl, 
        size.height / 2, 
        xStart, 
        size.height + 500 + (scrollOffset * 0.2)
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant FiberPainter oldDelegate) {
    return oldDelegate.scrollOffset != scrollOffset;
  }
}
