import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oasis/features/wellbeing/presentation/providers/warm_whisper_provider.dart';

class WarmWhisperSheet extends StatefulWidget {
  final String recipientId;
  final String recipientName;

  const WarmWhisperSheet({
    super.key,
    required this.recipientId,
    required this.recipientName,
  });

  @override
  State<WarmWhisperSheet> createState() => _WarmWhisperSheetState();
}

class _WarmWhisperSheetState extends State<WarmWhisperSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _isAnonymous = false;
  String _selectedEmoji = '💛';

  final List<String> _emojis = ['💛', '🌟', '🍀', '🤗', '💪', '✨', '🌈', '🌸'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendWhisper() async {
    final provider = context.read<WarmWhisperProvider>();
    final message = _controller.text.trim();
    final fullMessage = '$_selectedEmoji $message'.trim();

    final success = await provider.sendWhisper(
      recipientId: widget.recipientId,
      message: fullMessage,
      isAnonymous: _isAnonymous,
    );

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Warmth sent! ✨')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send warmth. Maybe you reached your daily limit?')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = context.watch<WarmWhisperProvider>();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            children: [
              Text(
                'Send a Warm Whisper',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${provider.remainingCount}/3 left',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Think of it as a gentle nudge of care for ${widget.recipientName}.',
            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          
          // Emoji Picker
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _emojis.length,
              itemBuilder: (context, index) {
                final emoji = _emojis[index];
                final isSelected = _selectedEmoji == emoji;
                return GestureDetector(
                  onTap: () => setState(() => _selectedEmoji = emoji),
                  child: Container(
                    width: 50,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? colorScheme.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _controller,
            maxLength: 100,
            decoration: InputDecoration(
              hintText: 'Add a small note of warmth (optional)...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              counterText: '',
            ),
          ),
          const SizedBox(height: 12),

          SwitchListTile(
            value: _isAnonymous,
            onChanged: (val) => setState(() => _isAnonymous = val),
            title: const Text('Send Anonymously'),
            subtitle: const Text('They won\'t know it was you'),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: provider.remainingCount > 0 ? _sendWhisper : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: provider.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Send Warmth ✨', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    ));
  }
}
