import 'package:flutter/material.dart';
import 'package:oasis/features/wellbeing/presentation/providers/cozy_mode_state.dart';

class CozyModeSheet extends StatefulWidget {
  final CozyMode? currentMode;
  final String? currentText;
  final Function(CozyMode mode, String? customText, Duration? duration) onSelect;
  final VoidCallback onClear;

  const CozyModeSheet({
    super.key,
    this.currentMode,
    this.currentText,
    required this.onSelect,
    required this.onClear,
  });

  @override
  State<CozyModeSheet> createState() => _CozyModeSheetState();
}

class _CozyModeSheetState extends State<CozyModeSheet> {
  late CozyMode _selectedMode;
  final TextEditingController _customTextController = TextEditingController();
  Duration? _selectedDuration;

  final List<Duration> _durationOptions = [
    const Duration(minutes: 30),
    const Duration(hours: 1),
    const Duration(hours: 2),
    const Duration(hours: 4),
    const Duration(hours: 8),
    const Duration(days: 1),
  ];

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.currentMode ?? CozyMode.cocoon;
    if (widget.currentText != null) {
      _customTextController.text = widget.currentText!;
    }
  }

  @override
  void dispose() {
    _customTextController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} ${duration.inDays == 1 ? 'day' : 'days'}';
    }
    if (duration.inHours > 0) {
      return '${duration.inHours} ${duration.inHours == 1 ? 'hour' : 'hours'}';
    }
    return '${duration.inMinutes} ${duration.inMinutes == 1 ? 'min' : 'mins'}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cozy Hours',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.currentMode != null)
                TextButton(
                  onPressed: () {
                    widget.onClear();
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Clear',
                    style: TextStyle(color: colorScheme.error),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Set a cozy status to let friends know you\'re taking time for yourself',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),

          // Mode selection
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CozyMode.values.where((m) => m != CozyMode.custom).map((mode) {
              final isSelected = _selectedMode == mode;
              return ChoiceChip(
                label: Text('${mode.emoji} ${mode.defaultText}'),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedMode = mode);
                  }
                },
                selectedColor: colorScheme.primaryContainer,
                labelStyle: TextStyle(
                  color: isSelected 
                      ? colorScheme.onPrimaryContainer 
                      : colorScheme.onSurface,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Custom text for custom mode
          if (_selectedMode == CozyMode.custom) ...[
            TextField(
              controller: _customTextController,
              decoration: InputDecoration(
                labelText: 'Custom status',
                hintText: 'What are you up to?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLength: 50,
            ),
            const SizedBox(height: 16),
          ],

          // Duration selection
          Text(
            'Duration',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Until I turn it off'),
                selected: _selectedDuration == null,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedDuration = null);
                  }
                },
              ),
              ..._durationOptions.map((duration) {
                final isSelected = _selectedDuration == duration;
                return ChoiceChip(
                  label: Text(_formatDuration(duration)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedDuration = duration);
                    }
                  },
                );
              }),
            ],
          ),
          const SizedBox(height: 24),

          // Apply button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                final customText = _selectedMode == CozyMode.custom
                    ? _customTextController.text
                    : null;
                widget.onSelect(_selectedMode, customText, _selectedDuration);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.check),
              label: const Text('Apply Cozy Mode'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    ));
  }
}