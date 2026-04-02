import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oasis_v2/services/app_initializer.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:oasis_v2/screens/circles/circles_list_screen.dart';
import 'package:oasis_v2/screens/canvas/canvas_list_screen.dart';

/// The Spaces hub replaces the old Communities tab.
/// It contains two sub-tabs: Circles & Canvas.
class SpacesScreen extends StatefulWidget {
  const SpacesScreen({super.key});

  @override
  State<SpacesScreen> createState() => _SpacesScreenState();
}

class _SpacesScreenState extends State<SpacesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isM3E = themeProvider.isM3EEnabled;
    final disableTransparency = themeProvider.isM3ETransparencyDisabled;
    final isDesktop = MediaQuery.of(context).size.width >= 1000;

    Widget spacesContent = Column(
      children: [
        // ── Custom top tab bar ───────────────────────────────────────
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: _SpacesTabBar(controller: _tabController, isM3E: isM3E),
          ),
        ),

        // ── Tab views ────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: const [CirclesListScreen(), CanvasListScreen()],
          ),
        ),
      ],
    );

    if (isDesktop) {
      final desktopBgColor = disableTransparency 
          ? theme.colorScheme.surface 
          : theme.colorScheme.surface.withValues(alpha: 0.4);

      return Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          decoration: BoxDecoration(
            color: desktopBgColor,
            borderRadius: BorderRadius.circular(isM3E ? 32 : 24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isM3E ? 32 : 24),
            child: disableTransparency 
              ? Scaffold(
                  backgroundColor: Colors.transparent,
                  body: spacesContent,
                )
              : BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Scaffold(
                    backgroundColor: Colors.transparent,
                    body: spacesContent,
                  ),
                ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: spacesContent,
    );
  }
}

// ─── Custom pill tab bar ──────────────────────────────────────────────────────

class _SpacesTabBar extends StatelessWidget {
  final TabController controller;
  final bool isM3E;
  const _SpacesTabBar({required this.controller, this.isM3E = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isM3E ? 12 : 16),
        color: theme.colorScheme.surface,
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: TabBar(
        controller: controller,
        labelColor: theme.colorScheme.onPrimary,
        unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
        labelStyle: theme.textTheme.titleSmall?.copyWith(
          fontWeight: isM3E ? FontWeight.w900 : FontWeight.bold,
          letterSpacing: isM3E ? -0.5 : 0,
        ),
        unselectedLabelStyle: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.normal,
        ),
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(isM3E ? 10 : 13),
          color: theme.colorScheme.primary,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(FluentIcons.people_team_24_regular, size: 16),
                SizedBox(width: 6),
                Text('Circles'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(FluentIcons.whiteboard_24_regular, size: 16),
                SizedBox(width: 6),
                Text('Canvas'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
