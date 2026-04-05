import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:oasis/features/circles/presentation/providers/circle_provider.dart';
import 'package:oasis/features/profile/presentation/providers/profile_provider.dart';

class CreateCircleScreen extends StatefulWidget {
  const CreateCircleScreen({super.key});

  @override
  State<CreateCircleScreen> createState() => _CreateCircleScreenState();
}

class _CreateCircleScreenState extends State<CreateCircleScreen> {
  final _nameController = TextEditingController();
  String _selectedEmoji = '🌊';
  bool _isLoading = false;

  // Available emojis for circles
  static const _emojis = [
    '🌊',
    '🔥',
    '⚡',
    '🌿',
    '🎯',
    '💫',
    '🦋',
    '✨',
    '🌙',
    '☀️',
    '🏔️',
    '🌺',
    '🎸',
    '📚',
    '🧠',
    '💪',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final profile = context.read<ProfileProvider>().currentProfile;
    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for profile to load')),
      );
      return;
    }

    final userId = profile.id;

    setState(() => _isLoading = true);
    try {
      final circle = await context.read<CircleProvider>().createCircle(
        createdBy: userId,
        name: name,
        emoji: _selectedEmoji,
        memberIds: const [], // members can be invited after creation
      );
      if (!mounted) return;
      if (circle != null) {
        context.pushReplacementNamed(
          'circle_detail',
          pathParameters: {'circleId': circle.id},
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create circle. Please try again.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Building CreateCircleScreen...');
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('New Circle'),
        leading: IconButton(
          icon: const Icon(FluentIcons.dismiss_24_regular),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Emoji Picker ────────────────────────────────────────────
            Text(
              'Pick an emoji',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children:
                  _emojis.map((emoji) {
                    final isSelected = emoji == _selectedEmoji;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedEmoji = emoji),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 52,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color:
                              isSelected
                                  ? theme.colorScheme.primary.withValues(
                                    alpha: 0.2,
                                  )
                                  : theme.colorScheme.surface,
                          border: Border.all(
                            color:
                                isSelected
                                    ? theme.colorScheme.primary
                                    : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    );
                  }).toList(),
            ),

            const SizedBox(height: 32),

            // ── Name ────────────────────────────────────────────────────
            Text(
              'Name your circle',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              maxLength: 40,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'e.g. The Morning Crew',
                prefixText: '$_selectedEmoji  ',
                prefixStyle: const TextStyle(fontSize: 18),
              ),
            ),

            const SizedBox(height: 16),

            // ── Info chip ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    FluentIcons.info_24_regular,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You can invite friends to your circle after creating it.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // ── Create Button ────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _create,
                icon:
                    _isLoading
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(FluentIcons.checkmark_circle_24_regular),
                label: Text(_isLoading ? 'Creating...' : 'Create Circle'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
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
