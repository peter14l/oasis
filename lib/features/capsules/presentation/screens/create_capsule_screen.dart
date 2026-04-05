import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:oasis/services/auth_service.dart';
import 'package:oasis/services/time_capsule_service.dart';
import 'package:oasis/widgets/share_sheet.dart';
import 'package:oasis/features/profile/presentation/providers/profile_provider.dart';
import 'package:oasis/screens/oasis_pro_screen.dart';

class CreateCapsuleScreen extends StatefulWidget {
  const CreateCapsuleScreen({super.key});

  @override
  State<CreateCapsuleScreen> createState() => _CreateCapsuleScreenState();
}

class _CreateCapsuleScreenState extends State<CreateCapsuleScreen> {
  final TextEditingController _contentController = TextEditingController();
  final TimeCapsuleService _capsuleService = TimeCapsuleService();
  
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  
  // Presets
  final List<Map<String, dynamic>> _datePresets = [
    {
      'label': 'Tomorrow', 
      'duration': const Duration(days: 1),
      'icon': Icons.brightness_3,
      'isPro': false,
    },
    {
      'label': 'Next Week', 
      'duration': const Duration(days: 7),
      'icon': Icons.calendar_view_week,
      'isPro': false,
    },
    {
      'label': 'Next Year', 
      'duration': const Duration(days: 365),
      'icon': Icons.calendar_today,
      'isPro': true,
    },
    {
      'label': '5 Years', 
      'duration': const Duration(days: 365 * 5),
      'icon': Icons.rocket_launch,
      'isPro': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = context.read<ProfileProvider>().currentProfile;
      if (profile != null && profile.isPro) {
        setState(() {
          _selectedDate = DateTime.now().add(const Duration(days: 365));
        });
      }
    });
  }

  Future<void> _pickCustomDate() async {
    final now = DateTime.now();
    final profile = context.read<ProfileProvider>().currentProfile;
    final isPro = profile?.isPro ?? false;
    final maxFreeDate = now.add(const Duration(days: 14));

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(isPro ? now.add(const Duration(days: 365 * 50)) : maxFreeDate) 
          ? now.add(const Duration(days: 1)) 
          : _selectedDate,
      firstDate: now.add(const Duration(days: 1)),
      lastDate: isPro ? now.add(const Duration(days: 365 * 50)) : maxFreeDate,
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

      final capsule = await _capsuleService.createCapsule(
        userId: userId,
        content: _contentController.text.trim(),
        unlockDate: _selectedDate,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Time Capsule sealed successfully!')),
      );
      
      // Show Share Sheet
      await ShareSheet.show(
        context,
        title: 'Share your memory',
        payload: 'https://oasis-app.com/capsule/${capsule.id}',
        externalMessage: 'I buried a memory in a Time Capsule. It unlocks on ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}. Download Oasis to open it together: https://oasis-app.com/capsule/${capsule.id}',
      );

      if (mounted) context.pop();
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
    final isDesktop = MediaQuery.of(context).size.width >= 1000;
    
    final capsuleContent = SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 32.0 : 24.0),
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
                final isProPreset = preset['isPro'] as bool;
                final userIsPro = context.read<ProfileProvider>().currentProfile?.isPro ?? false;
                final isLocked = isProPreset && !userIsPro;
                
                return OutlinedButton.icon(
                  onPressed: () {
                    if (isLocked) {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const OasisProScreen()),
                      );
                    } else {
                      setState(() {
                        _selectedDate = DateTime.now().add(duration);
                      });
                    }
                  },
                  icon: Icon(isLocked ? Icons.lock : preset['icon'] as IconData, size: 18),
                  label: Text(preset['label'] as String),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isLocked ? colorScheme.onSurfaceVariant : colorScheme.primary,
                    side: BorderSide(
                      color: isLocked ? colorScheme.outlineVariant : colorScheme.primary.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
            ),
            if (isDesktop) ...[
              const SizedBox(height: 40),
              SizedBox(
                height: 50,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _createCapsule,
                  icon: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.lock_clock), 
                  label: const Text('Seal Time Capsule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      );

    if (isDesktop) {
      return Material(
        color: Colors.transparent,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 40),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Row(
                    children: [
                      Text('New Time Capsule', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => context.pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Flexible(child: capsuleContent),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
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
      body: capsuleContent,
    );
  }
}
