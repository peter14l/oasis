import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:morrow_v2/models/feed_layout_strategy.dart';

/// Widget for switching between different feed layouts
/// Displays as a popup menu in the AppBar
class FeedLayoutSwitcher extends StatefulWidget {
  final FeedLayoutType currentLayout;
  final ValueChanged<FeedLayoutType> onLayoutChanged;

  const FeedLayoutSwitcher({
    super.key,
    required this.currentLayout,
    required this.onLayoutChanged,
  });

  /// Load saved layout preference from SharedPreferences
  static Future<FeedLayoutType> loadLayoutPreference() async {
    const preferenceKey = 'feed_layout_preference';
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(preferenceKey) ?? FeedLayoutType.standard.index;
    return FeedLayoutType.values[index];
  }

  @override
  State<FeedLayoutSwitcher> createState() => _FeedLayoutSwitcherState();
}

class _FeedLayoutSwitcherState extends State<FeedLayoutSwitcher> {
  static const String _preferenceKey = 'feed_layout_preference';

  Future<void> _saveLayoutPreference(FeedLayoutType layout) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_preferenceKey, layout.index);
  }

  void _onLayoutSelected(FeedLayoutType layout) {
    if (layout != widget.currentLayout) {
      _saveLayoutPreference(layout);
      widget.onLayoutChanged(layout);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopupMenuButton<FeedLayoutType>(
      icon: Icon(widget.currentLayout.icon),
      tooltip: 'Change feed layout',
      onSelected: _onLayoutSelected,
      itemBuilder:
          (context) =>
              FeedLayoutType.values.map((layout) {
                final isSelected = layout == widget.currentLayout;

                return PopupMenuItem<FeedLayoutType>(
                  value: layout,
                  child: Row(
                    children: [
                      Icon(
                        layout.icon,
                        color: isSelected ? theme.colorScheme.primary : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          layout.displayName,
                          style: TextStyle(
                            color:
                                isSelected ? theme.colorScheme.primary : null,
                            fontWeight: isSelected ? FontWeight.bold : null,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                    ],
                  ),
                );
              }).toList(),
    );
  }
}
