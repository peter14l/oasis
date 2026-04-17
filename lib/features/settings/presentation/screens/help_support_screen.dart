import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:oasis/core/utils/responsive_layout.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    final content = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHelpSection(context, 'Frequently Asked Questions', [
          _buildHelpTile(
            context,
            'How do I change my profile?',
            'Go to Settings > Edit Profile.',
          ),
          _buildHelpTile(
            context,
            'Is Oasis Pro free?',
            'Oasis Pro is a premium subscription service.',
          ),
          _buildHelpTile(
            context,
            'How do I report a bug?',
            'You can use the "Send Feedback" option in Settings.',
          ),
        ]),
        const SizedBox(height: 24),
        _buildHelpSection(context, 'Contact Us', [
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Email Support'),
            subtitle: const Text('oasis.officialsupport@gmail.com'),
            onTap: () async {
              final Uri emailUri = Uri(
                scheme: 'mailto',
                path: 'oasis.officialsupport@gmail.com',
              );
              if (await canLaunchUrl(emailUri)) {
                await launchUrl(emailUri);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.help_center_outlined),
            title: const Text('Help Center'),
            subtitle: const Text('Visit our help website'),
            onTap: () async {
              final Uri url = Uri.parse('https://help.Oasisapp.com');
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
            },
          ),
        ]),
      ],
    );

    if (isDesktop) return Material(color: Colors.transparent, child: content);

    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support'), centerTitle: true),
      body: content,
    );
  }

  Widget _buildHelpSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Card(child: Column(children: children)),
      ],
    );
  }

  Widget _buildHelpTile(BuildContext context, String question, String answer) {
    return ExpansionTile(
      title: Text(question, style: const TextStyle(fontSize: 14)),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}
