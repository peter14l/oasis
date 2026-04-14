import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oasis/services/subscription_service.dart';
import 'package:oasis/services/revenuecat_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

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
    final rcService = Provider.of<RevenueCatService>(context);
    final isDesktop = MediaQuery.of(context).size.width >= 1000;

    if (subService.isPro) {
      final proContent = Center(
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
              'Thank you for supporting Oasis.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );

      if (isDesktop)
        return Material(color: Colors.transparent, child: proContent);

      return Scaffold(
        appBar: AppBar(title: const Text('Oasis Pro'), centerTitle: true),
        body: proContent,
      );
    }

    // Get offerings from RevenueCat
    final offerings = rcService.offerings;
    final currentOffering = offerings?.current;
    final annualPackage = currentOffering?.annual;
    final monthlyPackage = currentOffering?.monthly;

    final upgradeContent = SingleChildScrollView(
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

          // Comparison Matrix
          const SizedBox(height: 16),
          Text(
            'Compare Plans',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              children: [
                _buildMatrixHeader(context),
                const Divider(height: 1),
                _buildMatrixRow(context, 'Feed Experience', 'Ads', 'Ad-Free'),
                _buildMatrixRow(
                  context,
                  'Vault Storage',
                  '10 Items',
                  'Unlimited',
                ),
                _buildMatrixRow(
                  context,
                  'Time Capsules',
                  '2 Active',
                  'Unlimited',
                ),
                _buildMatrixRow(
                  context,
                  'Canvases & Circles',
                  '2 Each',
                  'Unlimited',
                ),
                _buildMatrixRow(
                  context,
                  'Creator Analytics',
                  '7 Days',
                  '90 Days + Insights',
                ),
                _buildMatrixRow(
                  context,
                  'Wellness Reports',
                  'None',
                  'Weekly Reports',
                ),
                _buildMatrixRow(
                  context,
                  'Focus & Wind-down',
                  'Basic',
                  'Custom & Advanced',
                ),
                _buildMatrixRow(
                  context,
                  'Large File Sharing',
                  'No',
                  'Up to 2GB+',
                ),
                _buildMatrixRow(
                  context,
                  'Media Downloads',
                  'Own only',
                  'Full access',
                  isLast: true,
                ),
              ],
            ),
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
                  _isAnnual 
                      ? (annualPackage?.storeProduct.priceString ?? '$34.99')
                      : (monthlyPackage?.storeProduct.priceString ?? '$4.99'),
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
                        final package = _isAnnual ? annualPackage : monthlyPackage;
                        if (package == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Plan not available.')),
                          );
                          return;
                        }

                        setState(() => _isProcessing = true);
                        
                        final success = await rcService.purchasePackage(package);
                        
                        setState(() => _isProcessing = false);

                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Congratulations! You are now Pro.'),
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
                        _isAnnual ? 'Start Annual Pro' : 'Start Monthly Pro',
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
    );

    if (isDesktop)
      return Material(color: Colors.transparent, child: upgradeContent);

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
      body: SafeArea(child: upgradeContent),
    );
  }

  Widget _buildMatrixHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Feature',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Free',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Pro',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatrixRow(
    BuildContext context,
    String feature,
    String freeVal,
    String proVal, {
    bool isLast = false,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(feature, style: theme.textTheme.bodyMedium),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  freeVal,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  proVal,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16),
      ],
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

