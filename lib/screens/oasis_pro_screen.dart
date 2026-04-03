import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:oasis_v2/services/pricing_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:oasis_v2/core/network/supabase_client.dart';
import 'dart:ui';

class OasisProScreen extends StatefulWidget {
  const OasisProScreen({super.key});

  @override
  State<OasisProScreen> createState() => _OasisProScreenState();
}

class _OasisProScreenState extends State<OasisProScreen> {
  late Currency _detectedCurrency;
  late List<PricingPlan> _plans;

  @override
  void initState() {
    super.initState();
    _detectedCurrency = PricingService.detectCurrency();
    _plans = PricingService.getPlans(_detectedCurrency);
  }

  Future<void> _subscribe(PricingPlan plan) async {
    final userId = SupabaseService().client.auth.currentUser?.id;
    if (userId == null) return;

    final url = Uri.parse('https://oasis-web-red.vercel.app/pricing?user_id=$userId&plan=${plan.name.toLowerCase()}&currency=${plan.currency.name}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
                  colors: [Colors.blueAccent.withValues(alpha: 0.2), Colors.transparent],
                ),
              ),
            ),
          ),

          CustomScrollView(
            slivers: [
              if (!isDesktop)
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  leading: IconButton(
                    icon: const Icon(FluentIcons.dismiss_24_filled, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                  expandedHeight: 200,
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: true,
                    title: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Oasis Pro', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 24)),
                        Text('Elevate your experience', style: theme.textTheme.labelSmall?.copyWith(color: Colors.white70)),
                      ],
                    ),
                  ),
                ),

              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildFeatureItem(FluentIcons.shield_lock_24_regular, 'Signal Protocol Encryption', 'The gold standard for privacy.'),
                    _buildFeatureItem(FluentIcons.video_clip_24_regular, 'Unlimited Ripples', 'Share your moments without limits.'),
                    _buildFeatureItem(FluentIcons.storage_24_regular, '100GB Secure Storage', 'Keep your memories safe in the vault.'),
                    const SizedBox(height: 40),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Detected Region: ', style: theme.textTheme.bodySmall?.copyWith(color: Colors.white54)),
                        Text(_detectedCurrency.name, style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    ..._plans.map((plan) => _buildPricingCard(plan)).toList(),
                    
                    const SizedBox(height: 40),
                    Center(
                      child: Text(
                        'Secure payments handled via our web portal.',
                        style: theme.textTheme.labelSmall?.copyWith(color: Colors.white24),
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

    return Scaffold(
      backgroundColor: Colors.black,
      body: content,
    );
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
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard(PricingPlan plan) {
    final isPro = plan.name == 'Pro';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isPro ? Colors.blueAccent.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isPro ? Colors.blueAccent.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(plan.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
              if (isPro)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(8)),
                  child: const Text('BEST VALUE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(plan.symbol, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
              Text('${plan.price}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 32)),
              const Text('/mo', style: TextStyle(color: Colors.white54, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _subscribe(plan),
              style: FilledButton.styleFrom(
                backgroundColor: isPro ? Colors.blueAccent : Colors.white,
                foregroundColor: isPro ? Colors.white : Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('Upgrade to ${plan.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
