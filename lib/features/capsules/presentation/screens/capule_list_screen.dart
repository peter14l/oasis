import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oasis/features/capsules/presentation/providers/capsule_provider.dart';
import 'package:oasis/features/capsules/domain/models/time_capsule_entity.dart';
import 'package:oasis/themes/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

/// Vault Screen - List all time capsules
class CapsuleListScreen extends StatefulWidget {
  const CapsuleListScreen({super.key});

  @override
  State<CapsuleListScreen> createState() => _CapsuleListScreenState();
}

class _CapsuleListScreenState extends State<CapsuleListScreen> {
  @override
  void initState() {
    super.initState();
    // Load capsules on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CapsuleProvider>();
      // Note: In real app, get userId from auth service
      provider.loadCapsules('current_user'); // TODO: Get actual userId
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Vault',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => context.pushNamed('create_capsule'),
          ),
        ],
      ),
      body: Consumer<CapsuleProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: OasisColors.glow),
            );
          }

          final capsules = provider.capsules;
          
          if (capsules.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: capsules.length,
            itemBuilder: (context, index) {
              final capsule = capsules[index];
              return _buildCapsuleCard(context, capsule);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_clock_outlined,
            size: 80,
            color: Colors.white24,
          ),
          const SizedBox(height: 24),
          const Text(
            'Your Vault is empty',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Seal a memory for the future',
            style: TextStyle(color: Colors.white38),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => context.pushNamed('create_capsule'),
            icon: const Icon(Icons.add),
            label: const Text('Create Time Capsule'),
            style: ElevatedButton.styleFrom(
              backgroundColor: OasisColors.glow,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapsuleCard(BuildContext context, TimeCapsule capsule) {
    final theme = Theme.of(context);
    final isLocked = capsule.isLocked;
    final dateFormat = DateFormat('MMM d, yyyy');

    return Card(
      color: const Color(0xFF0C0F14),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/capsule/${capsule.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isLocked 
                      ? Colors.amber.withValues(alpha: 0.2)
                      : Colors.greenAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isLocked ? Icons.lock_clock : Icons.auto_awesome,
                  color: isLocked ? Colors.amber : Colors.greenAccent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      // Use first line of content as title, or default
                      capsule.content.split('\n').first.isEmpty 
                          ? 'Time Capsule' 
                          : capsule.content.split('\n').first,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLocked
                          ? 'Opens ${dateFormat.format(capsule.unlockDate)}'
                          : 'Unsealed',
                      style: TextStyle(
                        color: isLocked ? Colors.white54 : Colors.greenAccent,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.white24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}