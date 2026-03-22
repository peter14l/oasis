import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:oasis_v2/services/circle_service.dart';
import 'package:oasis_v2/models/circle.dart';
import 'package:oasis_v2/providers/profile_provider.dart';
import 'package:oasis_v2/widgets/fluid_mesh_background.dart';

class CircleJoinScreen extends StatefulWidget {
  final String circleId;
  const CircleJoinScreen({super.key, required this.circleId});

  @override
  State<CircleJoinScreen> createState() => _CircleJoinScreenState();
}

class _CircleJoinScreenState extends State<CircleJoinScreen> {
  Circle? _circle;
  bool _isLoading = true;
  final CircleService _circleService = CircleService();

  @override
  void initState() {
    super.initState();
    _loadCircle();
  }

  Future<void> _loadCircle() async {
    try {
      final circle = await _circleService.getCircleDetails(widget.circleId);
      setState(() {
        _circle = circle;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _join() async {
    final userId = context.read<ProfileProvider>().currentProfile?.id;
    if (userId == null) return;

    setState(() => _isLoading = true);
    try {
      await _circleService.joinCircle(widget.circleId, userId);
      if (mounted) {
        context.pushReplacement('/spaces/circles/${widget.circleId}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_circle == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: const Center(
          child: Text('Invite link expired or invalid', style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: FluidMeshBackground(streakCount: _circle!.streakCount)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _circle!.emoji,
                    style: const TextStyle(fontSize: 80),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'You\'re invited to',
                    style: theme.textTheme.labelLarge?.copyWith(color: Colors.white70, letterSpacing: 2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _circle!.name,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_circle!.streakCount} day streak',
                      style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _join,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('JOIN CIRCLE & VERIFY STREAK'),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/feed'),
                    child: const Text('Maybe later', style: TextStyle(color: Colors.white54)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
