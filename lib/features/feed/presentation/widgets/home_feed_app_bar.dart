import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oasis/core/theme/oasis_colors.dart';
import 'package:oasis/core/extensions/context_extensions.dart';
import 'package:oasis/features/notifications/presentation/providers/notification_provider.dart';
import 'package:oasis/features/settings/presentation/providers/user_settings_provider.dart';
import 'package:oasis/models/feed_layout_strategy.dart';

/// Clean, editorial app bar for the Home/Feed screen.
///
/// Features:
/// - Brand wordmark ("OASIS ▾") with feed & layout switcher bottom sheet.
/// - Tactical action hub: Ripples launcher, Create post button (+), and Notifications (🔔) with live unread badge.
/// - Strictly excludes Direct Messages (which reside on Tab 3 of bottom nav).
/// - Excludes redundant Search and Profile buttons (which reside on Tabs 1 and 4).
class HomeFeedAppBar extends StatelessWidget {
  final VoidCallback? onRipplesTap;

  const HomeFeedAppBar({
    super.key,
    this.onRipplesTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final unreadCount = context.select<NotificationProvider, int>(
      (p) => p.unreadCount,
    );

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            // Left: Brand Wordmark with drop-down switcher
            _buildBrandWordmark(context, colorScheme, isDark),

            const Spacer(),

            // Right: Ripples launcher
            if (onRipplesTap != null) ...[
              _buildRipplesButton(context, colorScheme, isDark),
              const SizedBox(width: 8),
            ],

            // Right: Create Post Button (+)
            _buildCreateButton(context, colorScheme, isDark),
            const SizedBox(width: 8),

            // Right: Notifications Bell (🔔) with unread badge
            _buildNotificationsButton(context, colorScheme, isDark, unreadCount),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandWordmark(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          _showFeedSwitcherSheet(context);
        },
        borderRadius: BorderRadius.circular(12),
        splashColor: colorScheme.primary.withValues(alpha: 0.1),
        highlightColor: colorScheme.primary.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: isDark
                      ? [
                          OasisColors.sand,
                          OasisColors.glow,
                        ]
                      : [
                          colorScheme.primary,
                          colorScheme.secondary,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: Text(
                  'OASIS',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: isDark
                    ? OasisColors.mist
                    : colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRipplesButton(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onRipplesTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: isDark
                ? OasisColors.glow.withValues(alpha: 0.12)
                : colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? OasisColors.glow.withValues(alpha: 0.25)
                  : colorScheme.primary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 14,
                color: isDark ? OasisColors.glow : colorScheme.primary,
              ),
              const SizedBox(width: 5),
              Text(
                'Ripples',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? OasisColors.glow : colorScheme.primary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateButton(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          context.pushNamed('create_post');
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? OasisColors.moss.withValues(alpha: 0.7)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            border: Border.all(
              color: isDark
                  ? OasisColors.sage.withValues(alpha: 0.4)
                  : colorScheme.outlineVariant.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.add_rounded,
              size: 20,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsButton(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
    int unreadCount,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          context.pushNamed('notifications');
        },
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? OasisColors.moss.withValues(alpha: 0.7)
                    : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: Border.all(
                  color: isDark
                      ? OasisColors.sage.withValues(alpha: 0.4)
                      : colorScheme.outlineVariant.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Center(
                child: Icon(
                  FluentIcons.alert_24_regular,
                  size: 19,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                top: -3,
                right: -3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  decoration: BoxDecoration(
                    color: OasisColors.glow,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: OasisColors.glow.withValues(alpha: 0.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 9 ? '9+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showFeedSwitcherSheet(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final settings = context.read<UserSettingsProvider>();

    context.showResponsiveSheet(
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            20 + MediaQuery.of(sheetContext).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: isDark ? OasisColors.moss : colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? OasisColors.sage.withValues(alpha: 0.35)
                    : colorScheme.outlineVariant.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? OasisColors.mist.withValues(alpha: 0.3)
                        : colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Text(
                'Feed & Layout',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: isDark ? OasisColors.sand : colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Personalize how Oasis presents your home feed',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? OasisColors.mist : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),

              // Layout Types List
              ...FeedLayoutType.values.map((type) {
                final isSelected = settings.feedLayout == type;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark
                            ? OasisColors.glow.withValues(alpha: 0.15)
                            : colorScheme.primary.withValues(alpha: 0.08))
                        : (isDark
                            ? OasisColors.deep.withValues(alpha: 0.4)
                            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? (isDark ? OasisColors.glow : colorScheme.primary)
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? OasisColors.glow : colorScheme.primary)
                            : (isDark
                                ? OasisColors.sage.withValues(alpha: 0.3)
                                : colorScheme.surfaceContainerHighest),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        type.icon,
                        size: 20,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? OasisColors.sand : colorScheme.onSurface),
                      ),
                    ),
                    title: Text(
                      type.displayName,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? (isDark ? OasisColors.sand : colorScheme.primary)
                            : (isDark ? OasisColors.sand : colorScheme.onSurface),
                        fontSize: 15,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: isDark ? OasisColors.glow : colorScheme.primary,
                            size: 22,
                          )
                        : null,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      settings.setFeedLayout(type);
                      Navigator.pop(sheetContext);
                    },
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
