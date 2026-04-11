import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:oasis/widgets/moderation_dialogs.dart';
import 'package:url_launcher/url_launcher.dart';

class CommunityGuidelinesScreen extends StatelessWidget {
  final String name;
  final String theme;

  const CommunityGuidelinesScreen({
    super.key,
    required this.name,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1200;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Community Guidelines'),
        centerTitle: isDesktop,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 800 : double.infinity,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Our Commitment',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'We\'re dedicated to fostering a safe and inclusive community. These guidelines outline the standards for behavior and content on our platform. We encourage everyone to contribute positively and respectfully.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Key Guidelines',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                _buildGuidelineCard(
                  context,
                  title: 'Respectful Interactions',
                  description:
                      'Treat others with kindness and respect. Avoid personal attacks, harassment, or any form of discrimination.',
                  color: const Color(0xFF6B9EFF),
                ),
                const SizedBox(height: 16),
                _buildGuidelineCard(
                  context,
                  title: 'Content Standards',
                  description:
                      'Content should be appropriate for a diverse audience. Avoid posting content that is sexually suggestive, exploits, abuses, or endangers children.',
                  color: const Color(0xFF1152D4),
                ),
                const SizedBox(height: 16),
                _buildGuidelineCard(
                  context,
                  title: 'Reporting Violations',
                  description:
                      'If you encounter content that violates our guidelines, please report it immediately. Your reports help us maintain a safe environment.',
                  color: const Color(0xFF9B59B6),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Reporting Tools',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                _buildMenuItem(
                  context,
                  title: 'Report a Post',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => const ReportDialog(),
                    );
                  },
                ),
                const Divider(height: 1, color: Color(0xFF282E39)),
                _buildMenuItem(
                  context,
                  title: 'Report a User',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => const ReportDialog(),
                    );
                  },
                ),
                const Divider(height: 1, color: Color(0xFF282E39)),
                _buildMenuItem(
                  context,
                  title: 'Contact Support',
                  onTap: () async {
                    final Uri emailUri = Uri(
                      scheme: 'mailto',
                      path: 'oasis.officialsupport@outlook.com',
                      query: 'subject=Community Support Request',
                    );
                    if (await canLaunchUrl(emailUri)) {
                      await launchUrl(emailUri);
                    }
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 800 : double.infinity,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFF3D4451)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'Back',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to the next screen
                      context.push(
                        '/community/create/description',
                        extra: {'name': name, 'theme': theme},
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1152D4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'I Understand',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuidelineCard(
    BuildContext context, {
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.7)],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Color(0xFF9DA6B9),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
    );
  }
}
