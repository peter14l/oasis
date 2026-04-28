import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oasis/features/wellbeing/presentation/providers/cozy_mode_provider.dart';
import 'package:oasis/features/wellbeing/presentation/providers/cozy_mode_state.dart';
import 'package:oasis/widgets/wellbeing/cozy_mode_sheet.dart';
import 'package:oasis/features/profile/data/repositories/profile_repository_impl.dart';

class CozyModeToggle extends StatelessWidget {
  final bool compact;

  const CozyModeToggle({
    super.key,
    this.compact = false,
  });

  void _showCozyModeSheet(BuildContext context) {
    final provider = context.read<CozyModeProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CozyModeSheet(
        currentMode: provider.activeMode,
        currentText: provider.customText,
        onSelect: (mode, customText, duration) {
          provider.setCozyMode(
            mode: mode,
            customText: customText,
            duration: duration,
          );
        },
        onClear: () {
          provider.clearCozyMode();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ChangeNotifierProvider<CozyModeProvider>(
      create: (_) => CozyModeProvider(
        profileRepository: ProfileRepositoryImpl(),
      )..loadCozyMode(),
      child: Consumer<CozyModeProvider>(
        builder: (context, provider, _) {
          final isActive = provider.hasActiveCozyStatus;

          if (compact) {
            // Compact icon-only button
            return IconButton(
              onPressed: () => _showCozyModeSheet(context),
              icon: Stack(
                children: [
                  Icon(
                    isActive
                        ? Icons.bedtime_rounded
                        : Icons.bedtime_outlined,
                    color: isActive
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  if (isActive)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              tooltip: isActive
                  ? provider.displayText
                  : 'Set Cozy Hours',
            );
          }

          // Full toggle button
          return InkWell(
            onTap: () => _showCozyModeSheet(context),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isActive
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isActive
                        ? Icons.bedtime_rounded
                        : Icons.bedtime_outlined,
                    color: isActive
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isActive ? provider.displayText : 'Cozy Hours',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isActive
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                      fontWeight: isActive
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  if (isActive) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => provider.clearCozyMode(),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}