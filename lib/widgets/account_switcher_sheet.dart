import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:oasis_v2/services/auth_service.dart';
import 'package:oasis_v2/services/session_registry_service.dart';
import 'package:go_router/go_router.dart';

class AccountSwitcherSheet extends StatelessWidget {
  const AccountSwitcherSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authService = context.watch<AuthService>();
    final currentUserId = authService.currentUser?.id;
    final accounts = authService.registeredAccounts;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Switch Account',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Accounts List
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: accounts.length,
                itemBuilder: (context, index) {
                  final account = accounts[index];
                  final isCurrent = account.userId == currentUserId;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundImage: (account.avatarUrl ?? '').isNotEmpty
                          ? CachedNetworkImageProvider(account.avatarUrl!)
                          : null,
                      child: (account.avatarUrl ?? '').isEmpty
                          ? Text(account.username[0].toUpperCase())
                          : null,
                    ),
                    title: Text(
                      account.username,
                      style: TextStyle(
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      account.email,
                      style: theme.textTheme.bodySmall,
                    ),
                    trailing: isCurrent
                        ? Icon(Icons.check_circle, color: colorScheme.primary)
                        : null,
                    onTap: isCurrent
                        ? null
                        : () async {
                            Navigator.pop(context);
                            await authService.switchAccount(context, account.userId);
                          },
                  );
                },
              ),
            ),

            const Divider(),
            
            // Add Account Button
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add, color: colorScheme.onPrimaryContainer),
              ),
              title: const Text('Add Account'),
              onTap: () {
                Navigator.pop(context);
                context.push('/login?add_account=true');
              },
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const AccountSwitcherSheet(),
    );
  }
}
