import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oasis/features/profile/presentation/providers/profile_provider.dart';
import 'package:oasis/services/auth_service.dart';

class AccountPrivacyScreen extends StatelessWidget {
  const AccountPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    final isPrivate = profileProvider.currentProfile?.isPrivate ?? false;
    final isDesktop = MediaQuery.of(context).size.width >= 1000;

    final content = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Private Account'),
            subtitle: const Text(
              'When your account is private, only people you approve can see your photos and videos.',
            ),
            value: isPrivate,
            onChanged: (value) async {
              if (user != null) {
                try {
                  await profileProvider.updatePrivacy(
                    userId: user.id,
                    isPrivate: value,
                  );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating privacy: $e')),
                    );
                  }
                }
              }
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'This doesn\'t change who can message you or see your profile information.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      );

    if (isDesktop) return Material(color: Colors.transparent, child: content);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Privacy'),
        centerTitle: true,
      ),
      body: content,
    );
  }
}
