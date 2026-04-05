import 'package:flutter/material.dart';

class GlowingNote extends StatelessWidget {
  final String content;
  final String colorHex;
  final DateTime createdAt;

  const GlowingNote({
    super.key,
    required this.content,
    required this.colorHex,
    required this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glowColor = _hexToColor(colorHex);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          // The neon glow effect
          BoxShadow(
            color: glowColor.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: -2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(2), // Border thickness
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                glowColor.withValues(alpha: 0.8),
                glowColor.withValues(alpha: 0.2),
              ],
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0C0F14).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.95),
                    height: 1.5,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: glowColor.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'CORE MEMORY',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: glowColor.withValues(alpha: 0.6),
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    try {
      final code = hex.replaceAll('#', '');
      if (code.length == 6) {
        return Color(int.parse('FF$code', radix: 16));
      } else if (code.length == 8) {
        return Color(int.parse(code, radix: 16));
      }
    } catch (e) {
      debugPrint('GlowingNote: Invalid hex color "$hex" - ${e.toString()}');
    }
    return const Color(0xFF3B82F6); // Default blue
  }
}
