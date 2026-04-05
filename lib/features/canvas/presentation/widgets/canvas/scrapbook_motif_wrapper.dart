import 'package:flutter/material.dart';

class ScrapbookMotifWrapper extends StatelessWidget {
  final Widget child;
  final bool hasTape;
  final bool hasPaperClip;
  final double rotation;

  const ScrapbookMotifWrapper({
    super.key,
    required this.child,
    this.hasTape = false,
    this.hasPaperClip = false,
    this.rotation = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          if (hasTape)
            Positioned(
              top: -15,
              left: 20,
              child: Transform.rotate(
                angle: -0.2,
                child: Container(
                  width: 60,
                  height: 25,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (hasPaperClip)
            Positioned(
              top: -10,
              right: 10,
              child: Transform.rotate(
                angle: 0.4,
                child: Icon(
                  Icons.attachment_rounded,
                  color: Colors.grey[400],
                  size: 32,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
