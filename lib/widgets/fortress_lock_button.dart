import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:oasis/services/fortress_service.dart';
import 'package:oasis/widgets/fortress_message_selector.dart';
import 'package:oasis/screens/fortress_lock_screen.dart';

/// Fortress lock button with long-press to activate
class FortressLockButton extends StatefulWidget {
  final bool showSettings;

  const FortressLockButton({
    super.key,
    this.showSettings = true,
  });

  @override
  State<FortressLockButton> createState() => _FortressLockButtonState();
}

class _FortressLockButtonState extends State<FortressLockButton> {
  bool _isLongPressing = false;
  double _pressProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    final fortressService = context.watch<FortressService>();
    final isActive = fortressService.isFortressActive;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onLongPressStart: (_) {
        setState(() {
          _isLongPressing = true;
          _pressProgress = 0.0;
        });
        // Start animation
        _animatePress(context, fortressService);
      },
      onLongPressEnd: (_) {
        setState(() {
          _isLongPressing = false;
          _pressProgress = 0.0;
        });
      },
      onLongPressCancel: () {
        setState(() {
          _isLongPressing = false;
          _pressProgress = 0.0;
        });
      },
      onTap: widget.showSettings
          ? () => _showFortressOptions(context, fortressService)
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Progress indicator for long press
            if (_isLongPressing)
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  value: _pressProgress,
                  strokeWidth: 3,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                ),
              ),
            // Lock icon
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive
                    ? FluentIcons.lock_closed_24_filled
                    : FluentIcons.lock_closed_24_regular,
                key: ValueKey(isActive),
                color: isActive
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ),
            // Active indicator
            if (isActive)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.surface,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _animatePress(
      BuildContext context, FortressService fortressService) async {
    // Animate progress over 500ms
    const totalDuration = 500;
    const updateInterval = 16;
    int elapsed = 0;

    while (_isLongPressing && elapsed < totalDuration) {
      await Future.delayed(const Duration(milliseconds: updateInterval));
      if (!_isLongPressing) break;
      elapsed += updateInterval;
      setState(() {
        _pressProgress = elapsed / totalDuration;
      });
    }

    if (_isLongPressing) {
      // Long press completed - toggle fortress
      await fortressService.toggleFortress();

      if (fortressService.isFortressActive && context.mounted) {
        // Show fortress lock screen
        _showFortressLock(context);
      }

      setState(() {
        _isLongPressing = false;
        _pressProgress = 0.0;
      });
    }
  }

  void _showFortressLock(BuildContext context) {
    final fortressService = context.read<FortressService>();

    showFortressLockScreen(
      context,
      awayMessage: fortressService.fortressDisplayMessage,
      onUnlock: () async {
        await fortressService.deactivateFortress();
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
    );
  }

  void _showFortressOptions(
      BuildContext context, FortressService fortressService) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Title with fortress icon
            Row(
              children: [
                Icon(
                  fortressService.isFortressActive
                      ? FluentIcons.lock_closed_24_filled
                      : FluentIcons.lock_closed_24_regular,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Fortress Mode',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              fortressService.isFortressActive
                  ? 'Your app is protected'
                  : 'One-tap to lock your app',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Current status if active
            if (fortressService.isFortressActive) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      FluentIcons.person_available_24_regular,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        fortressService.fortressDisplayMessage,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Quick activate/deactivate button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  if (fortressService.isFortressActive) {
                    await fortressService.deactivateFortress();
                    if (context.mounted) Navigator.pop(context);
                  } else {
                    await fortressService.activateFortress();
                    if (context.mounted) {
                      Navigator.pop(context);
                      _showFortressLock(context);
                    }
                  }
                },
                icon: Icon(
                  fortressService.isFortressActive
                      ? FluentIcons.lock_open_24_regular
                      : FluentIcons.lock_closed_24_regular,
                ),
                label: Text(
                  fortressService.isFortressActive
                      ? 'Unlock Fortress'
                      : 'Activate Fortress',
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Customize message option
            if (!fortressService.isFortressActive)
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  showFortressMessageSelector(
                    context,
                    currentMessage: fortressService.fortressMessage,
                    onSelect: (message) async {
                      await fortressService.activateFortress(
                        customMessage: message,
                      );
                      if (context.mounted) {
                        _showFortressLock(context);
                      }
                    },
                  );
                },
                icon: const Icon(FluentIcons.edit_24_regular),
                label: const Text('Choose away message'),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Triple-tap detector wrapper for activating fortress mode
class TripleTapFortressWrapper extends StatelessWidget {
  final Widget child;
  final FortressService fortressService;

  const TripleTapFortressWrapper({
    super.key,
    required this.child,
    required this.fortressService,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        fortressService.onTripleTap();
      },
      child: child,
    );
  }
}