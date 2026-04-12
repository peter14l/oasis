import 'package:oasis/core/config/app_config.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:oasis/services/pricing_service.dart';
import 'package:oasis/services/iap_service.dart';
import 'package:oasis/services/subscription_service.dart';
import 'package:oasis/widgets/subscription/razorpay_windows_view.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:oasis/core/network/supabase_client.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class OasisProScreen extends StatefulWidget {
  const OasisProScreen({super.key});

  @override
  State<OasisProScreen> createState() => _OasisProScreenState();
}

class _OasisProScreenState extends State<OasisProScreen> {
  Currency _detectedCurrency = Currency.usd;
  List<PricingPlan> _plans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initPricing();
  }

  Future<void> _initPricing() async {
    final currency = await PricingService.detectPPP();
    if (mounted) {
      setState(() {
        _detectedCurrency = currency;
        _plans = PricingService.getPlans(currency);
        _isLoading = false;
      });
    }
  }

  Future<void> _subscribe(PricingPlan plan) async {
    if (Platform.isWindows) {
      // Use Razorpay Flow for Windows (Phase 4)
      _startRazorpayWindowsFlow(plan);
    } else {
      // Use Web Checkout for all other platforms (Android, iOS, MacOS, Web)
      // to handle checkout outside of standard App Store/Play Store IAP
      _launchWebCheckout(plan);
    }
  }

  Widget _buildWebRedirectBanner(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(FluentIcons.info_24_regular, color: Colors.blueAccent),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Web Checkout',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Payments are currently handled via our secure web portal. You will be redirected to complete your purchase.',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _startRazorpayWindowsFlow(PricingPlan plan) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.black,
            insetPadding: const EdgeInsets.all(20),
            child: Container(
              width: 800,
              height: 600,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  AppBar(
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    title: const Text(
                      'Secure Checkout',
                      style: TextStyle(fontSize: 16),
                    ),
                    leading: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Expanded(
                    child: RazorpayWindowsView(
                      plan: plan,
                      onSuccess: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Payment Successful! Your Pro status will be updated shortly.',
                            ),
                          ),
                        );
                        context.read<SubscriptionService>().refresh();
                      },
                      onCancel: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(content: Text('Payment Cancelled.')),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _launchWebCheckout(PricingPlan plan) async {
    final userId = SupabaseService().client.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to upgrade to Oasis Pro.'),
          ),
        );
      }
      return;
    }

    final url = Uri.parse(
      AppConfig.getWebUrl(
        '/checkout?user_id=$userId&plan=${plan.name}&currency=${plan.currency.name.toUpperCase()}',
      ),
    );
    try {
      final canLaunch = await canLaunchUrl(url);
      if (!canLaunch) {
        // canLaunchUrl returns false - try anyway as fallback
        debugPrint(
          'canLaunchUrl returned false for $url, attempting launch anyway',
        );
      }
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw Exception('launchUrl returned false');
      }
    } catch (e) {
      debugPrint('Could not launch $url: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open checkout page: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 1000;

    final content = Stack(
      children: [
        // Background Glow
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.blueAccent.withValues(alpha: 0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(color: Colors.blueAccent),
          )
        else
          CustomScrollView(
            slivers: [
              if (!isDesktop)
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  leading: IconButton(
                    icon: const Icon(
                      FluentIcons.dismiss_24_filled,
                      color: Colors.white,
                    ),
                    onPressed: () => context.pop(),
                  ),
                  expandedHeight: 200,
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: true,
                    title: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Oasis Pro',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 24,
                          ),
                        ),
                        Text(
                          'Elevate your experience',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildFeatureItem(
                      FluentIcons.video_clip_24_regular,
                      'Ad-Free Experience',
                      'Enjoy a clean feed without any interruptions.',
                    ),
                    _buildFeatureItem(
                      FluentIcons.shield_lock_24_regular,
                      'Unlimited Vault & Capsules',
                      'Store unlimited items and active time capsules.',
                    ),
                    _buildFeatureItem(
                      FluentIcons.draw_shape_24_regular,
                      'Unlimited Canvas & Circles',
                      'Create as many collaborative spaces as you need.',
                    ),
                    _buildFeatureItem(
                      FluentIcons.heart_pulse_24_regular,
                      'Advanced Wellness',
                      'Weekly reports, custom focus modes, and wind-down.',
                    ),
                    _buildFeatureItem(
                      FluentIcons.data_usage_24_regular,
                      'Creator Analytics',
                      '90-day history, demographics, and posting heatmaps.',
                    ),
                    _buildFeatureItem(
                      FluentIcons.arrow_download_24_regular,
                      'Power Features',
                      '2GB+ file uploads and media downloads.',
                    ),
                    const SizedBox(height: 40),

                    _buildWebRedirectBanner(context),

                    ..._plans.map((plan) => _buildPricingCard(plan)),

                    const SizedBox(height: 40),
                    Center(
                      child: Text(
                        'Secure payments handled via our web portal.',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white24,
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
      ],
    );

    if (isDesktop) return Material(color: Colors.black, child: content);

    return Scaffold(backgroundColor: Colors.black, body: content);
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.blueAccent, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard(PricingPlan plan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Oasis Pro',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'FULL ACCESS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                plan.symbol,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              Text(
                '${plan.price}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 32,
                ),
              ),
              const Text(
                '/mo',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _subscribe(plan),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Upgrade to Oasis Pro',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
