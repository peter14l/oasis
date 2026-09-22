import 'package:flutter/material.dart';

/// WhatsApp-style soft entrance micro-animation for sent and received messages.
///
/// Ensures smooth 120Hz compositor performance with zero layout jitter.
/// Historical messages (where [isFresh] is false) render immediately without replaying.
class WhatsAppBubbleAnimation extends StatefulWidget {
  const WhatsAppBubbleAnimation({
    super.key,
    required this.child,
    required this.isMe,
    required this.isFresh,
  });

  final Widget child;
  final bool isMe;
  final bool isFresh;

  @override
  State<WhatsAppBubbleAnimation> createState() => _WhatsAppBubbleAnimationState();
}

class _WhatsAppBubbleAnimationState extends State<WhatsAppBubbleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.isMe ? 180 : 220),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    // Outgoing messages slide gently upward; incoming slide gently from the left
    final beginOffset = widget.isMe
        ? const Offset(0.0, 0.12)
        : const Offset(-0.05, 0.08);

    _slideAnimation = Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.isMe ? Curves.easeOutQuad : Curves.easeOutCubic,
      ),
    );

    if (widget.isFresh) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant WhatsAppBubbleAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If a previously non-fresh message became fresh or reset
    if (!oldWidget.isFresh && widget.isFresh && !_controller.isCompleted) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isFresh || _controller.isCompleted) {
      return widget.child;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
