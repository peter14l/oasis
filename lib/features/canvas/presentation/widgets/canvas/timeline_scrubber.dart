import 'package:flutter/material.dart';
import 'package:oasis_v2/features/canvas/domain/models/canvas_models.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class TimelineScrubber extends StatelessWidget {
  final List<CanvasItemEntity> items;
  final ScrollController scrollController;

  const TimelineScrubber({
    super.key,
    required this.items,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    // Group items by Month-Year to create markers
    final Map<String, int> monthMarkers = {};
    for (int i = 0; i < items.length; i++) {
      final key = DateFormat('MMM yy').format(items[i].createdAt);
      if (!monthMarkers.containsKey(key)) {
        monthMarkers[key] = i;
      }
    }

    final markers = monthMarkers.keys.toList();

    return Container(
      width: 60,
      margin: const EdgeInsets.only(right: 8, top: 100, bottom: 100),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: markers.map((label) {
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _scrollToIndex(monthMarkers[label]!);
            },
            child: RotatedBox(
              quarterTurns: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _scrollToIndex(int index) {
    // Basic approximation: 400 pixels per item/group
    // Ideally we would use an ItemScrollController or similar for precise indexing
    scrollController.animateTo(
      index * 400.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }
}
