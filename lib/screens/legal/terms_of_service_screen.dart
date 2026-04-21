import 'package:flutter/material.dart';

/// Terms of Service Screen
/// Displays the app's terms of service with proper formatting
class TermsOfServiceScreen extends StatelessWidget {
  /// Optional callback when user accepts the terms (for registration flow)
  final VoidCallback? onAccept;

  /// Whether this is being shown during registration (shows accept button)
  final bool showAcceptButton;

  const TermsOfServiceScreen({
    super.key,
    this.onAccept,
    this.showAcceptButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        backgroundColor: colorScheme.surface,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Oasis Terms of Service',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last updated: April 2026',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildSection(
                    context,
                    '1. The Oasis Mission',
                    '''Oasis is an intentional relationship platform. By using this app, you acknowledge that Oasis is designed to prioritize mental wellbeing over engagement metrics. This means we surgically remove features like infinite feeds, view counts, and public likes to protect your peace.''',
                  ),

                  _buildSection(
                    context,
                    '2. Acceptance of Terms',
                    '''By accessing or using Oasis, you agree to be bound by these Terms of Service. If you do not agree to these terms, including our commitment to data sovereignty and intentionality, please do not use the app.''',
                  ),

                  _buildSection(
                    context,
                    '3. Eligibility & Children',
                    '''You must be at least 13 years of age. Users in certain regions (including India under the DPDP Act 2023) between the ages of 13 and 18 may require verifiable parental consent. You represent that you have not been previously suspended or removed from Oasis.''',
                  ),

                  _buildSection(
                    context,
                    '4. Encryption & Account Security',
                    '''Oasis uses End-to-End Encryption (E2EE). 

• Responsibility: You are solely responsible for remembering your PIN and securing your Recovery Code.
• No Recovery: Because Oasis follows a "Zero-Knowledge" architecture, we cannot recover your encrypted messages if you lose your credentials.
• Security: You must notify us immediately of any unauthorized use of your account.''',
                  ),

                  _buildSection(
                    context,
                    '5. The Subscription Covenant',
                    '''Oasis operates on a subscription-first model. "You pay us so we never have to sell you." 

• Payment: Payments are processed via Razorpay or RevenueCat (App Store/Play Store).
• Cancellation: You may cancel your subscription at any time.
• Transparency: We provide annual reports on how subscription funds are used to maintain the platform's mission.''',
                  ),

                  _buildSection(
                    context,
                    '6. Content & Relational Circles',
                    '''• Ownership: You retain ownership of content you post.
• Privacy: Content posted to a "Circle" is intended only for that circle.
• Anti-Virality: You agree not to attempt to circumvent our blocks on content reshare or virality mechanisms. Oasis is for intentional sharing, not broadcast media.''',
                  ),

                  _buildSection(
                    context,
                    '7. Prohibited Conduct',
                    '''You agree not to:
• Harass or bully other users.
• Reverse engineer or attempt to extract our source code (except for our open-source cryptographic components).
• Use automated scripts to scrape user data.
• Share illegal or harmful content.''',
                  ),

                  _buildSection(
                    context,
                    '8. Disclaimers & Limitation of Liability',
                    '''Oasis is provided "as is." While we strive for 100% security, no system is perfect. To the maximum extent permitted by law, Oasis is not liable for data loss caused by lost encryption keys or device failure.''',
                  ),

                  _buildSection(
                    context,
                    '9. Termination',
                    '''You may delete your account at any time. Upon deletion, all your data is permanently scrubbed from our active servers in accordance with your "Right to be Forgotten."''',
                  ),

                  _buildSection(
                    context,
                    '10. Contact',
                    '''For legal or support inquiries:
• Email: legal@oasis.com''',
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          if (showAcceptButton)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onAccept,
                    child: const Text('I Accept'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }
}
