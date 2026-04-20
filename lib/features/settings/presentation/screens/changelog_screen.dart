import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ChangelogScreen extends StatelessWidget {
  const ChangelogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: colorScheme.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Changelog',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              centerTitle: true,
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    _buildVersionCard(
                      context,
                      version: '4.6.0+1',
                      date: 'April 20, 2026',
                      features: [],
                      fixes: [
                        'Fixed startup assertion by ensuring WidgetsFlutterBinding is initialized inside runZonedGuarded',
                        'Resolved severe scrolling lag and UI freezing in chat by caching RSA private keys',
                        'Chunked decryption workloads in the event loop to prevent UI blocking',
                        'Fixed a bug where local unread counters incorrectly reset when the other user read a message',
                        'Fixed silent realtime timeouts by adding missing tables to Supabase Realtime publication',
                        'Reduced latency when receiving new messages by stripping unnecessary fields',
                      ],
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 16),
                    _buildVersionCard(
                      context,
                      version: '4.3.0+1',
                      date: 'April 18, 2026',
                      features: [
                        'Real-time Media Upload Progress with blurred overlays',
                        'Optimistic Media Messages for images, videos, and documents',
                        'Optimistic Voice Messages with real-time progress',
                        'Parallel Message Decryption for faster chat loading',
                        'Smart Message Retries with exponential backoff',
                        'Notification Grouping for cleaner message alerts',
                        'Encrypted Notification Previews in real-time',
                        'Accessibility: Native Open Dyslexic font support',
                        'Expanded Font Selection (Outfit, Lexend, Tinos, etc.)',
                      ],
                      fixes: [
                        'Fixed Global Lag by optimizing procedural background rendering',
                        'Fixed Data-Only Notification regression in foreground/background',
                        'Fixed persistent Reply Context bug in chat screen',
                        'Refined Chat Input UI height and button alignment',
                        'Fixed local media playback for optimistic messages',
                        'Improved M3E theme contrast and readability',
                      ],
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 16),
                    _buildVersionCard(
                      context,
                      version: '4.2.0',
                      date: 'April 15, 2026',
                      features: [
                        'Secure Error Handling system',
                        'Animated Splash Screen',
                        'Parallelized Service Initialization',
                        'In-App Update Notifier',
                        'Dynamic Theme Color Palettes',
                        'Interactive Onboarding Flow',
                      ],
                      fixes: [
                        'Release signing configuration improvements',
                        'Realtime polling fallbacks for Supabase stability',
                        'Screen time lockout enforcement',
                        'Messaging architecture decoupling',
                      ],
                    ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 16),
                    _buildVersionCard(
                      context,
                      version: '4.1.0',
                      date: 'Current Version',
                      features: [
                        'Advanced Calling Experience with E2EE',
                        'Multi-participant Mesh calls',
                        'Screen sharing in calls',
                      ],
                      fixes: [
                        'Improved stability for background notifications',
                        'Fixed UI glitches in dark mode',
                      ],
                    ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionCard(
    BuildContext context, {
    required String version,
    required String date,
    required List<String> features,
    required List<String> fixes,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'v$version',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              Text(
                date,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (features.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'NEW FEATURES',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.secondary,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            ...features.map((f) => _buildBulletPoint(context, f)),
          ],
          if (fixes.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'FIXES & IMPROVEMENTS',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            ...fixes.map((f) => _buildBulletPoint(context, f)),
          ],
        ],
      ),
    );
  }

  Widget _buildBulletPoint(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
