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
                    'Last updated: December 2024',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildSection(
                    context,
                    '1. Acceptance of Terms',
                    '''By accessing or using Oasis you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the app.

These terms constitute a legally binding agreement between you and Oasis Please read them carefully before using our services.''',
                  ),

                  _buildSection(
                    context,
                    '2. Eligibility',
                    '''To use Oasisyou must:

• Be at least 13 years of age
• Have the legal capacity to enter into a binding agreement
• Not be prohibited from using the service under applicable law
• Provide accurate and complete registration information''',
                  ),

                  _buildSection(
                    context,
                    '3. Your Account',
                    '''You are responsible for:

• Maintaining the confidentiality of your login credentials
• All activities that occur under your account
• Immediately notifying us of any unauthorized use
• Keeping your account information accurate and up-to-date

We reserve the right to suspend or terminate accounts that violate these terms.''',
                  ),

                  _buildSection(
                    context,
                    '4. User Content',
                    '''When you post content on Oasis

• You retain ownership of your content
• You grant us a license to display, store, and distribute your content within the app
• You are responsible for ensuring you have rights to content you post
• You agree not to post content that infringes on others' rights''',
                  ),

                  _buildSection(
                    context,
                    '5. Prohibited Conduct',
                    '''You agree not to:

• Harass, bully, or intimidate other users
• Post illegal, harmful, or offensive content
• Impersonate others or misrepresent your identity
• Spam or send unsolicited promotional material
• Attempt to hack, exploit, or disrupt our services
• Collect user data without authorization
• Violate any applicable laws or regulations
• Circumvent any security measures or access restrictions''',
                  ),

                  _buildSection(
                    context,
                    '6. Content Moderation',
                    '''We have the right to:

• Remove content that violates these terms
• Suspend or terminate accounts for violations
• Report illegal activity to law enforcement
• Use automated systems to detect policy violations

We strive to enforce our policies fairly and consistently.''',
                  ),

                  _buildSection(
                    context,
                    '7. Community Guidelines',
                    '''Users must follow our community guidelines:

• Be respectful in all interactions
• Report violations through proper channels
• Use blocking and muting features for unwanted content
• Contribute positively to communities you join''',
                  ),

                  _buildSection(
                    context,
                    '8. Intellectual Property',
                    '''Oasisand its content are protected by:

• Copyright and trademark laws
• Other intellectual property rights

You may not copy, modify, or distribute our app or branding without permission.''',
                  ),

                  _buildSection(
                    context,
                    '9. Disclaimers',
                    '''Oasisis provided "as is" without warranties:

• We do not guarantee uninterrupted or error-free service
• We are not responsible for user-generated content
• We do not endorse opinions expressed by users
• Use the app at your own risk''',
                  ),

                  _buildSection(
                    context,
                    '10. Limitation of Liability',
                    '''To the maximum extent permitted by law:

• We are not liable for indirect, incidental, or consequential damages
• Our total liability is limited to the amount you paid us (if any)
• Some jurisdictions may not allow these limitations''',
                  ),

                  _buildSection(
                    context,
                    '11. Indemnification',
                    '''You agree to indemnify and hold harmless Oasisrom:

• Claims arising from your use of the service
• Claims arising from your violation of these terms
• Claims arising from content you post''',
                  ),

                  _buildSection(
                    context,
                    '12. Changes to Terms',
                    '''We may modify these terms:

• We will notify you of significant changes
• Continued use constitutes acceptance of changes
• If you disagree with changes, you may delete your account''',
                  ),

                  _buildSection(
                    context,
                    '13. Termination',
                    '''Either party may terminate:

• You may delete your account at any time
• We may suspend or terminate accounts for violations
• Upon termination, certain provisions survive (e.g., content licenses)''',
                  ),

                  _buildSection(
                    context,
                    '14. Contact Information',
                    '''For questions about these terms:

• Email: oasis.officialsupport@gmail.com
• In-app: Settings → Help & Support

We welcome your feedback and questions.''',
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
