import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:oasis/services/fortress_service.dart';

class FortressMessageSelector extends StatefulWidget {
  final String? currentMessage;
  final Function(String) onSelect;

  const FortressMessageSelector({
    super.key,
    this.currentMessage,
    required this.onSelect,
  });

  @override
  State<FortressMessageSelector> createState() => _FortressMessageSelectorState();
}

class _FortressMessageSelectorState extends State<FortressMessageSelector> {
  final TextEditingController _customController = TextEditingController();
  bool _showCustomInput = false;

  @override
  void initState() {
    super.initState();
    if (widget.currentMessage != null) {
      final isCustom = !FortressMessage.predefined
          .any((m) => m.display == widget.currentMessage);
      if (isCustom) {
        _customController.text = widget.currentMessage!;
        _showCustomInput = true;
      }
    }
  }

  @override
  void dispose() {
    _customController.dispose();
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Row(
            children: [
              Icon(
                FluentIcons.person_available_24_regular,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'Away Message',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Choose what friends see when you\'re in fortress mode',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Predefined messages
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: FortressMessage.predefined.map((message) {
              final isSelected = widget.currentMessage == message.display;
              return ChoiceChip(
                label: Text(message.display),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    widget.onSelect(message.display);
                  }
                },
                avatar: isSelected
                    ? Icon(
                        FluentIcons.checkmark_24_regular,
                        size: 18,
                        color: colorScheme.onPrimaryContainer,
                      )
                    : null,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Custom message toggle
          TextButton.icon(
            onPressed: () {
              setState(() {
                _showCustomInput = !_showCustomInput;
              });
            },
            icon: Icon(
              _showCustomInput
                  ? FluentIcons.dismiss_24_regular
                  : FluentIcons.add_24_regular,
            ),
            label: Text(
              _showCustomInput ? 'Cancel custom' : 'Add custom message',
            ),
          ),

          // Custom message input
          if (_showCustomInput) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _customController,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: 'Type your custom away message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(FluentIcons.edit_24_regular),
                suffixIcon: IconButton(
                  icon: const Icon(FluentIcons.checkmark_24_regular),
                  onPressed: () {
                    if (_customController.text.trim().isNotEmpty) {
                      widget.onSelect(_customController.text.trim());
                    }
                  },
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Show the fortress message selector as a modal bottom sheet
Future<void> showFortressMessageSelector(
  BuildContext context, {
  String? currentMessage,
  required Function(String) onSelect,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => FortressMessageSelector(
      currentMessage: currentMessage,
      onSelect: (message) {
        onSelect(message);
        Navigator.pop(context);
      },
    ),
  );
}