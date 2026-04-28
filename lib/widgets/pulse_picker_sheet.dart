import 'package:flutter/material.dart';

/// Pulse status types for Check-in Pulse feature
enum PulseStatus {
  home('Home', '🏠'),
  work('Work', '💼'),
  traveling('Traveling', '🚗'),
  withFriend('With [friend]', '👥'),
  atLocation('At [location]', '🎯');

  final String label;
  final String emoji;
  const PulseStatus(this.label, this.emoji);
}

class PulsePickerSheet extends StatefulWidget {
  final PulseStatus? currentStatus;
  final String? currentText;
  final Function(PulseStatus status, String? customText) onSelect;
  final VoidCallback onClear;

  const PulsePickerSheet({
    super.key,
    this.currentStatus,
    this.currentText,
    required this.onSelect,
    required this.onClear,
  });

  @override
  State<PulsePickerSheet> createState() => _PulsePickerSheetState();
}

class _PulsePickerSheetState extends State<PulsePickerSheet> {
  late PulseStatus _selectedStatus;
  final TextEditingController _customTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentStatus ?? PulseStatus.home;
    if (widget.currentText != null) {
      _customTextController.text = widget.currentText!;
    }
  }

  @override
  void dispose() {
    _customTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
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
                'Check-in Pulse',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.currentStatus != null)
                TextButton(
                  onPressed: () {
                    widget.onClear();
                    Navigator.of(context).pop();
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
            'Let friends know where you are — no location tracking, just presence.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Status options
          ...PulseStatus.values.map((status) => _buildStatusOption(status)),

          const SizedBox(height: 16),

          // Custom text input for "With [friend]" or "At [location]"
          if (_selectedStatus == PulseStatus.withFriend ||
              _selectedStatus == PulseStatus.atLocation)
            _buildCustomTextInput(colorScheme),

          const SizedBox(height: 24),

          // Set button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                String? customText;
                if (_selectedStatus == PulseStatus.withFriend ||
                    _selectedStatus == PulseStatus.atLocation) {
                  customText = _customTextController.text.trim();
                  if (customText.isEmpty) {
                    // Show error
                    return;
                  }
                }
                widget.onSelect(_selectedStatus, customText);
                Navigator.of(context).pop();
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text('Set Pulse'),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildStatusOption(PulseStatus status) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _selectedStatus == status;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedStatus = status;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Text(
                  status.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    status.label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: colorScheme.primary,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTextInput(ColorScheme colorScheme) {
    final hintText = _selectedStatus == PulseStatus.withFriend
        ? "Friend's name"
        : 'Location name';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: _customTextController,
        decoration: InputDecoration(
          hintText: hintText,
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        textCapitalization: TextCapitalization.words,
      ),
    );
  }
}

/// Shows the pulse picker as a bottom sheet
Future<void> showPulsePicker({
  required BuildContext context,
  PulseStatus? currentStatus,
  String? currentText,
  required Function(PulseStatus status, String? customText) onSelect,
  required VoidCallback onClear,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => PulsePickerSheet(
      currentStatus: currentStatus,
      currentText: currentText,
      onSelect: onSelect,
      onClear: onClear,
    ),
  );
}
