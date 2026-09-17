import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oasis/core/extensions/context_extensions.dart';
import 'package:oasis/features/settings/domain/models/user_settings_entity.dart';
import 'package:oasis/features/settings/presentation/providers/user_settings_provider.dart';
import 'package:oasis/widgets/liquid_glass_wrapper.dart';
import 'package:provider/provider.dart';

/// Destination item data model for [LiquidGlassBottomNavPill].
class LiquidNavDestination {
  final Widget icon;
  final Widget selectedIcon;
  final String? tooltip;
  final Widget? badge;
  final bool isRestricted;

  const LiquidNavDestination({
    required this.icon,
    required this.selectedIcon,
    this.tooltip,
    this.badge,
    this.isRestricted = false,
  });
}

/// Progressive Blur Background that fades in blur towards the bottom of the screen.
/// Inspired by Apple's floating toolbar design in iOS / iPadOS / visionOS.
class ProgressiveBlurBackground extends StatelessWidget {
  final double height;

  const ProgressiveBlurBackground({
    super.key,
    this.height = 120.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return IgnorePointer(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          children: [
            // 1. Progressive Blur using ShaderMask + BackdropFilter
            Positioned.fill(
              child: ShaderMask(
                shaderCallback: (bounds) {
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Color(0x22000000),
                      Color(0x88000000),
                      Colors.black,
                    ],
                    stops: [0.0, 0.3, 0.7, 1.0],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstIn,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.18)
                        : Colors.white.withValues(alpha: 0.18),
                  ),
                ),
              ),
            ),

            // 2. Subtle gradient scrim to gently feather out scrolling content
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.scaffoldBackgroundColor.withValues(alpha: 0.0),
                      theme.scaffoldBackgroundColor.withValues(alpha: 0.35),
                      theme.scaffoldBackgroundColor.withValues(alpha: 0.78),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Apple-style Liquid Glass Bottom Navbar Pill with a draggable circular liquid glass
/// indicator that slides and snaps across navigation destinations.
class LiquidGlassBottomNavPill extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<LiquidNavDestination> destinations;
  final bool disableTransparency;
  final double itemWidth;
  final double pillHeight;
  final double indicatorDiameter;

  const LiquidGlassBottomNavPill({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.disableTransparency = false,
    this.itemWidth = 62.0,
    this.pillHeight = 62.0,
    this.indicatorDiameter = 48.0,
  });

  @override
  State<LiquidGlassBottomNavPill> createState() =>
      _LiquidGlassBottomNavPillState();
}

class _LiquidGlassBottomNavPillState extends State<LiquidGlassBottomNavPill>
    with SingleTickerProviderStateMixin {
  late AnimationController _snapController;
  late Animation<double> _indicatorAnimation;

  // Track position (offset in pixels from the left inside the pill)
  double _indicatorX = 0.0;
  double _dragStartX = 0.0;
  double _dragStartIndicatorX = 0.0;
  bool _isDragging = false;
  double _stretchWidth = 0.0;
  int _hoveredIndex = 0;

  static const double _horizontalTrackPadding = 8.0;

  @override
  void initState() {
    super.initState();
    _hoveredIndex = widget.currentIndex.clamp(0, widget.destinations.length - 1);
    _indicatorX = _calculateRestingX(_hoveredIndex);

    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _indicatorAnimation = Tween<double>(
      begin: _indicatorX,
      end: _indicatorX,
    ).animate(
      CurvedAnimation(
        parent: _snapController,
        curve: Curves.easeOutBack,
      ),
    )..addListener(() {
        setState(() {
          _indicatorX = _indicatorAnimation.value;
        });
      });
  }

  @override
  void didUpdateWidget(LiquidGlassBottomNavPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex && !_isDragging) {
      final safeIndex =
          widget.currentIndex.clamp(0, widget.destinations.length - 1);
      _hoveredIndex = safeIndex;
      _animateToSlot(safeIndex);
    }
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  double _calculateRestingX(int index) {
    // Slot center: _horizontalTrackPadding + (index + 0.5) * widget.itemWidth
    // Indicator left: slotCenter - (widget.indicatorDiameter / 2)
    final slotCenter =
        _horizontalTrackPadding + (index + 0.5) * widget.itemWidth;
    return slotCenter - (widget.indicatorDiameter / 2);
  }

  double get _minIndicatorX => _calculateRestingX(0);

  double get _maxIndicatorX =>
      _calculateRestingX(widget.destinations.length - 1);

  double get _totalPillWidth =>
      (widget.destinations.length * widget.itemWidth) +
      (_horizontalTrackPadding * 2);

  void _animateToSlot(int targetIndex) {
    final targetX = _calculateRestingX(targetIndex);
    _indicatorAnimation = Tween<double>(
      begin: _indicatorX,
      end: targetX,
    ).animate(
      CurvedAnimation(
        parent: _snapController,
        curve: Curves.easeOutBack,
      ),
    );
    _snapController.forward(from: 0.0);
  }

  void _handleTap(TapUpDetails details) {
    final localX = details.localPosition.dx;
    final slotIndex =
        ((localX - _horizontalTrackPadding) / widget.itemWidth).floor();

    if (slotIndex >= 0 && slotIndex < widget.destinations.length) {
      final destination = widget.destinations[slotIndex];
      if (destination.isRestricted) {
        HapticFeedback.lightImpact();
        return;
      }

      HapticFeedback.selectionClick();
      _hoveredIndex = slotIndex;
      _animateToSlot(slotIndex);
      widget.onDestinationSelected(slotIndex);
    }
  }

  void _handleDragStart(DragStartDetails details) {
    _snapController.stop();
    _isDragging = true;
    _dragStartX = details.localPosition.dx;
    _dragStartIndicatorX = _indicatorX;
    _stretchWidth = 4.0;
    HapticFeedback.selectionClick();
    setState(() {});
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final totalDeltaX = details.localPosition.dx - _dragStartX;
    var newX = _dragStartIndicatorX + totalDeltaX;

    // Apply elastic rubber-banding outside track bounds
    if (newX < _minIndicatorX) {
      final overscroll = _minIndicatorX - newX;
      newX = _minIndicatorX - math.sqrt(overscroll * 3.0);
    } else if (newX > _maxIndicatorX) {
      final overscroll = newX - _maxIndicatorX;
      newX = _maxIndicatorX + math.sqrt(overscroll * 3.0);
    }

    // Dynamic liquid stretch based on movement
    final delta = details.primaryDelta ?? 0.0;
    final stretch = (delta.abs() * 2.2).clamp(0.0, 14.0);

    // Identify nearest destination slot
    final indicatorCenter = newX + (widget.indicatorDiameter / 2);
    final hovered = ((indicatorCenter - _horizontalTrackPadding) /
            widget.itemWidth)
        .floor()
        .clamp(0, widget.destinations.length - 1);

    if (hovered != _hoveredIndex) {
      _hoveredIndex = hovered;
      if (!widget.destinations[hovered].isRestricted) {
        HapticFeedback.selectionClick();
      } else {
        HapticFeedback.lightImpact();
      }
    }

    setState(() {
      _indicatorX = newX;
      _stretchWidth = stretch;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    _isDragging = false;
    _stretchWidth = 0.0;

    int targetIndex = _hoveredIndex;
    final velocity = details.primaryVelocity ?? 0.0;

    // Flick gesture velocity handling
    if (velocity > 320 && targetIndex < widget.destinations.length - 1) {
      targetIndex++;
    } else if (velocity < -320 && targetIndex > 0) {
      targetIndex--;
    }

    // Fallback if destination is restricted
    if (widget.destinations[targetIndex].isRestricted) {
      targetIndex = widget.currentIndex;
      HapticFeedback.lightImpact();
    } else if (targetIndex != widget.currentIndex) {
      HapticFeedback.mediumImpact();
      widget.onDestinationSelected(targetIndex);
    } else {
      HapticFeedback.selectionClick();
    }

    _hoveredIndex = targetIndex;
    _animateToSlot(targetIndex);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    UserSettingsProvider? settings;
    try {
      settings = context.watch<UserSettingsProvider>();
    } catch (_) {}
    final liquidGlassMode = settings?.liquidGlassMode ?? LiquidGlassMode.real;
    final isSolid = ContextX(context).shouldUseSolidBackground;

    // Outer Pill Visual Shell
    return Center(
      child: Container(
        width: _totalPillWidth,
        height: widget.pillHeight,
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        child: widget.disableTransparency || isSolid
            ? _buildSolidShell(context, theme, isDark)
            : _buildLiquidShell(context, theme, isDark, liquidGlassMode),
      ),
    );
  }

  Widget _buildSolidShell(BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(widget.pillHeight / 2),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _buildPillContent(context, theme, isDark, false),
    );
  }

  Widget _buildLiquidShell(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    LiquidGlassMode mode,
  ) {
    const pillConfig = LiquidGlassConfig(
      thickness: 28,
      blur: 5.5,
      glassColor: Color(0x18FFFFFF),
      lightIntensity: 1.65,
      saturation: 1.4,
      refractiveIndex: 1.42,
      chromaticAberration: 0.02,
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.pillHeight / 2),
        boxShadow: [
          // Ambient soft glow & depth
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.38 : 0.12),
            blurRadius: 26,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LiquidGlassWrapper(
        borderRadius: widget.pillHeight / 2,
        shape: LiquidRoundedSuperellipse(borderRadius: widget.pillHeight / 2),
        config: pillConfig,
        backgroundColor: isDark
            ? Colors.black.withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.38),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.pillHeight / 2),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.22)
                  : Colors.white.withValues(alpha: 0.65),
              width: 0.9,
            ),
          ),
          child: _buildPillContent(context, theme, isDark, true),
        ),
      ),
    );
  }

  Widget _buildPillContent(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    bool isLiquid,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: _handleTap,
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      child: Stack(
        alignment: Alignment.centerLeft,
        clipBehavior: Clip.none,
        children: [
          // 1. Draggable Liquid Glass Circular Indicator Lens
          _buildDraggableIndicator(context, theme, isDark, isLiquid),

          // 2. Navigation Item Icons (Clean glyphs without text labels)
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _horizontalTrackPadding,
              ),
              child: Row(
                children: List.generate(
                  widget.destinations.length,
                  (index) => _buildNavItem(context, index, theme, isDark),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableIndicator(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    bool isLiquid,
  ) {
    final currentDiameter = widget.indicatorDiameter;
    final stretch = _stretchWidth;
    final width = currentDiameter + stretch;
    final height = currentDiameter - (stretch * 0.25);
    final top = (widget.pillHeight - height) / 2;

    Widget indicatorBody = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height / 2),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.white.withValues(alpha: 0.32),
                  Colors.white.withValues(alpha: 0.08),
                  Colors.white.withValues(alpha: 0.16),
                ]
              : [
                  Colors.white.withValues(alpha: 0.85),
                  Colors.white.withValues(alpha: 0.35),
                  Colors.white.withValues(alpha: 0.6),
                ],
          stops: const [0.0, 0.55, 1.0],
        ),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.85),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.32)
                : Colors.black.withValues(alpha: 0.14),
            blurRadius: 10,
            spreadRadius: -1,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: (isDark ? Colors.white : theme.colorScheme.primary)
                .withValues(alpha: isDark ? 0.16 : 0.22),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
    );

    if (isLiquid) {
      indicatorBody = LiquidGlassWrapper(
        borderRadius: height / 2,
        shape: LiquidRoundedSuperellipse(borderRadius: height / 2),
        config: const LiquidGlassConfig(
          thickness: 18,
          blur: 4.5,
          glassColor: Color(0x24FFFFFF),
          lightIntensity: 1.8,
          saturation: 1.45,
          refractiveIndex: 1.44,
          chromaticAberration: 0.025,
        ),
        child: indicatorBody,
      );
    }

    return Positioned(
      left: _indicatorX - (stretch / 2),
      top: top,
      child: IgnorePointer(
        child: indicatorBody,
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    ThemeData theme,
    bool isDark,
  ) {
    final destination = widget.destinations[index];
    final isSelected = index == widget.currentIndex;
    final isHovered = _isDragging && index == _hoveredIndex;
    final isRestricted = destination.isRestricted;

    final Color activeColor =
        isDark ? Colors.white : theme.colorScheme.primary;
    final Color inactiveColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.68);

    final iconWidget = isSelected || isHovered
        ? destination.selectedIcon
        : destination.icon;

    final Widget renderedIcon = IconTheme(
      data: IconThemeData(
        color: isRestricted
            ? inactiveColor.withValues(alpha: 0.25)
            : (isSelected || isHovered ? activeColor : inactiveColor),
        size: 25.0,
      ),
      child: iconWidget,
    );


    return SizedBox(
      width: widget.itemWidth,
      height: widget.pillHeight,
      child: Center(
        child: AnimatedScale(
          scale: isSelected ? 1.1 : (isHovered ? 1.05 : 1.0),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: renderedIcon,
        ),
      ),
    );
  }
}
