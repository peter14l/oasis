import 'package:flutter/material.dart';

/// Privacy Policy Screen
/// Displays the app's privacy policy with proper formatting
class PrivacyPolicyScreen extends StatelessWidget {
  /// Optional callback when user accepts the policy (for registration flow)
  final VoidCallback? onAccept;

  /// Whether this is being shown during registration (shows accept button)
  final bool showAcceptButton;

  const PrivacyPolicyScreen({
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
        title: const Text('Privacy Policy'),
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
                    'Oasis Privacy Policy',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last updated: December 2024',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildSection(
                    context,
                    '1. Information We Collect',
                    '''When you use Oasis, we collect the following types of information:

• Account Information: Your email address, username, display name, and profile picture.

• Content You Create: Posts, comments, messages, stories, and other content you share.

• Usage Data: How you interact with the app, including features you use, time spent, and device information.

• Device Information: Device type, operating system, and app version for improving compatibility.''',
                  ),

                  _buildSection(
                    context,
                    '2. How We Use Your Information',
                    '''We use your information to:

• Provide and maintain the Oasis service
• Personalize your experience and content recommendations
• Enable communication between users
• Send important notifications about your account
• Improve our services and develop new features
• Ensure safety and security of our platform
• Comply with legal obligations''',
                  ),

                  _buildSection(
                    context,
                    '3. Message Encryption',
                    '''Oasis uses end-to-end encryption for direct messages:

• Your messages are encrypted on your device before being sent
• Only you and the recipient can read your messages
• We cannot access the content of encrypted messages
• Encryption keys are protected by your PIN''',
                  ),

                  _buildSection(
                    context,
                    '4. Information Sharing',
                    '''We do not sell your personal information. We may share information:

• With your consent
• To comply with legal requirements
• To protect rights and safety
• With service providers who help operate our platform (under strict confidentiality agreements)''',
                  ),

                  _buildSection(
                    context,
                    '5. Data Storage & Security',
                    '''Your data is stored securely:

• We use industry-standard encryption for data in transit and at rest
• Access to user data is strictly limited to authorized personnel
• We regularly review and update our security practices
• Data is stored on secure servers with appropriate safeguards''',
                  ),

                  _buildSection(
                    context,
                    '6. Your Rights',
                    '''You have the right to:

• Access your personal data
• Correct inaccurate data
• Delete your account and associated data
• Export your data
• Control your privacy settings
• Opt out of certain data collection''',
                  ),

                  _buildSection(
                    context,
                    '7. Screen Time Tracking',
                    '''Oasis includes screen time features:

• Usage data is stored locally on your device
• We do not share your screen time data with third parties
• You can view your usage statistics in the app settings''',
                  ),

                  _buildSection(
                    context,
                    '8. Children\'s Privacy',
                    '''Oasis is not intended for children under 13:

• We do not knowingly collect information from children under 13
• If you believe a child has provided us with personal information, please contact us''',
                  ),

                  _buildSection(
                    context,
                    '9. Changes to This Policy',
                    '''We may update this policy from time to time:

• We will notify you of significant changes
• Continued use after changes constitutes acceptance
• Previous versions are available upon request''',
                  ),

                  _buildSection(
                    context,
                    '10. Contact Us',
                    '''If you have questions about this privacy policy:

• Email: privacy@morrow.app
• In-app: Settings → Help & Support

We aim to respond to all inquiries within 48 hours.''',
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
