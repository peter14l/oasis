import 'package:flutter/material.dart';
import 'package:oasis/features/messages/presentation/widgets/shared/view_mode_button.dart';

/// Media view mode selector (Keep in Chat / Allow Replay / View Once).
/// Extracted from _buildMediaViewModeSelector() in chat_screen.dart.
class MediaViewModeSelector extends StatelessWidget {
  const MediaViewModeSelector({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  final String currentMode;
  final Function(String) onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ViewModeButton(
          label: 'Keep in Chat',
          icon: Icons.chat_bubble_outline,
          isActive: currentMode == 'unlimited',
          onTap: () => onModeChanged('unlimited'),
        ),
        const SizedBox(width: 12),
        ViewModeButton(
          label: 'Allow Replay',
          icon: Icons.refresh_rounded,
          isActive: currentMode == 'twice',
          onTap: () => onModeChanged('twice'),
        ),
        const SizedBox(width: 12),
        ViewModeButton(
          label: 'View Once',
          icon: Icons.looks_one_rounded,
          isActive: currentMode == 'once',
          onTap: () => onModeChanged('once'),
        ),
      ],
    );
  }
}
