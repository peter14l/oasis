import 'package:flutter/material.dart';

class CircleWarmthIndicator extends StatelessWidget {
  final double score;
  final double size;
  final bool showLabel;

  const CircleWarmthIndicator({
    super.key,
    required this.score,
    this.size = 24,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getWarmthColor(score);
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.1),
            border: Border.all(color: color, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              _getWarmthIcon(score),
              size: size * 0.6,
              color: color,
            ),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 4),
          Text(
            _getWarmthLabel(score),
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  Color _getWarmthColor(double score) {
    if (score < 0.2) return const Color(0xFF00E5FF); // Icy Blue
    if (score < 0.4) return const Color(0xFF2979FF); // Blue
    if (score < 0.6) return const Color(0xFF9E9E9E); // Grey/Neutral
    if (score < 0.8) return const Color(0xFFFFAB40); // Orange
    return const Color(0xFFFF3D00); // Burning Orange
  }

  IconData _getWarmthIcon(double score) {
    if (score < 0.3) return Icons.ac_unit_rounded;
    if (score < 0.7) return Icons.wb_sunny_outlined;
    return Icons.whatshot_rounded;
  }

  String _getWarmthLabel(double score) {
    if (score < 0.2) return 'Icy';
    if (score < 0.4) return 'Cool';
    if (score < 0.6) return 'Active';
    if (score < 0.8) return 'Warm';
    return 'Burning';
  }
}
