import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:oasis_v2/services/auth_service.dart';
import 'package:oasis_v2/services/time_capsule_service.dart';
import 'package:oasis_v2/utils/responsive_layout.dart';

class CreateCapsuleScreen extends StatefulWidget {
  const CreateCapsuleScreen({super.key});

  @override
  State<CreateCapsuleScreen> createState() => _CreateCapsuleScreenState();
}

class _CreateCapsuleScreenState extends State<CreateCapsuleScreen> {
  final TextEditingController _contentController = TextEditingController();
  final TimeCapsuleService _capsuleService = TimeCapsuleService();
  
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 365)); // Default 1 year
  
  // Presets
  final List<Map<String, dynamic>> _datePresets = [
    {
      'label': 'Tomorrow', 
      'duration': const Duration(days: 1),
      'icon': Icons.brightness_3
    },
    {
      'label': 'Next Week', 
      'duration': const Duration(days: 7),
      'icon': Icons.calendar_view_week
    },
    {
      'label': 'Next Year', 
      'duration': const Duration(days: 365),
      'icon': Icons.calendar_today
    },
    {
      'label': '5 Years', 
      'duration': const Duration(days: 365 * 5),
      'icon': Icons.rocket_launch
    },
  ];

  Future<void> _pickCustomDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 50)), // 50 years
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _createCapsule() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a message for your future self')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = context.read<AuthService>().currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      await _capsuleService.createCapsule(
        userId: userId,
        content: _contentController.text.trim(),
        unlockDate: _selectedDate,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Time Capsule sealed successfully!')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to seal capsule: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final content = Scaffold(
      appBar: AppBar(
        title: const Text('New Time Capsule'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _createCapsule,
              icon: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.lock_clock), 
              label: const Text('Seal'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Write a message to the future',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'This message will stay locked until the date you choose.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            
            // Content Input
            TextField(
              controller: _contentController,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: 'Dear Future Me...',
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Date Selection
            Text(
              'Unlock Date',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            
            // Current Selection Display
            InkWell(
              onTap: _pickCustomDate,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event, color: colorScheme.primary),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected Date',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: theme.textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.edit),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Presets Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.5,
              ),
              itemCount: _datePresets.length,
              itemBuilder: (context, index) {
                final preset = _datePresets[index];
                final duration = preset['duration'] as Duration;
                
                return OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedDate = DateTime.now().add(duration);
                    });
                  },
                  icon: Icon(preset['icon'] as IconData),
                  label: Text(preset['label'] as String),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );

    return ResponsiveLayout.isDesktop(context)
        ? MaxWidthContainer(maxWidth: 600, child: content)
        : content;
  }
}
