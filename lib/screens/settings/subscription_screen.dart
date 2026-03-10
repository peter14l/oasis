import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:morrow_v2/services/subscription_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isProcessing = false;
  bool _isAnnual = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final subService = Provider.of<SubscriptionService>(context);

    if (subService.isPro) {
      return Scaffold(
        appBar: AppBar(title: const Text('Morrow Pro'), centerTitle: true),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.stars, size: 80, color: colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                'You are a Pro Member!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Thank you for supporting Morrow.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Upgrade to Pro',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.rocket_launch,
                    size: 48,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Unlock the Ultimate Experience',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Get ad-free browsing, advanced analytics, unlimited vaults, and pure privacy.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Features
              _buildFeatureRow(
                context,
                Icons.block,
                'Completely Ad-Free Experience',
              ),
              _buildFeatureRow(
                context,
                Icons.analytics,
                '90-Day Creator Analytics & Heatmaps',
              ),
              _buildFeatureRow(
                context,
                Icons.lock,
                'Unlimited Protected Vault Storage',
              ),
              _buildFeatureRow(context, Icons.people, 'Host Live Audio Rooms'),
              _buildFeatureRow(
                context,
                Icons.autorenew,
                'Direct Cross-Posting & Social Automations',
              ),

              const SizedBox(height: 32),

              // Pricing toggle
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildToggleButton('Monthly', !_isAnnual, () {
                        setState(() => _isAnnual = false);
                      }),
                      _buildToggleButton('Annual (Save 30%)', _isAnnual, () {
                        setState(() => _isAnnual = true);
                      }),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Price Display
              Center(
                child: Column(
                  children: [
                    Text(
                      _isAnnual ? '\$34.99' : '\$4.99',
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    Text(
                      _isAnnual ? 'per year' : 'per month',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Subscribe Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      _isProcessing
                          ? null
                          : () async {
                            setState(() => _isProcessing = true);
                            // Placeholder for actual revenuecat purchase flow
                            await Future.delayed(const Duration(seconds: 2));

                            // Mocking successful purchase by calling the service
                            // In reality this triggers via webhooks / revenuecat listener
                            await subService.debugToggleProStatus(true);

                            setState(() => _isProcessing = false);

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Welcome to Morrow Pro!'),
                                ),
                              );
                            }
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child:
                      _isProcessing
                          ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: colorScheme.onPrimary,
                              strokeWidth: 2,
                            ),
                          )
                          : Text(
                            'Start 14-Day Free Trial',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),

              const SizedBox(height: 16),

              // Terms footnote
              Center(
                child: Text(
                  'Recurring billing. Cancel anytime.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(BuildContext context, IconData icon, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String text, bool isSelected, VoidCallback onTap) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          text,
          style: theme.textTheme.titleSmall?.copyWith(
            color:
                isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
