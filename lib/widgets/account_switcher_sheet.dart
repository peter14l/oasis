import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oasis_v2/services/app_initializer.dart';
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isM3E = themeProvider.isM3EEnabled;
    final disableTransparency = themeProvider.isM3ETransparencyDisabled;
    final authService = context.watch<AuthService>();
    final currentUserId = authService.currentUser?.id;
    final accounts = authService.registeredAccounts;

    final sheetContent = Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: disableTransparency ? colorScheme.surface : colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.vertical(top: Radius.circular(isM3E ? 48 : 28)),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
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
                fontWeight: isM3E ? FontWeight.w900 : FontWeight.bold,
                letterSpacing: isM3E ? -0.5 : 0,
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
                    leading: Container(
                      padding: EdgeInsets.all(isM3E ? 2 : 0),
                      decoration: BoxDecoration(
                        shape: isM3E ? BoxShape.rectangle : BoxShape.circle,
                        borderRadius: isM3E ? BorderRadius.circular(12) : null,
                        border: isM3E ? Border.all(color: colorScheme.primary, width: 1.5) : null,
                      ),
                      child: ClipRRect(
                        borderRadius: isM3E ? BorderRadius.circular(10) : BorderRadius.circular(20),
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: (account.avatarUrl ?? '').isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: account.avatarUrl!,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  color: colorScheme.surfaceContainerHighest,
                                  child: Center(
                                    child: Text(
                                      account.username[0].toUpperCase(),
                                      style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    title: Text(
                      account.username,
                      style: TextStyle(
                        fontWeight: isCurrent ? (isM3E ? FontWeight.w900 : FontWeight.bold) : FontWeight.normal,
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
                  borderRadius: BorderRadius.circular(isM3E ? 12 : 20),
                  shape: isM3E ? BoxShape.rectangle : BoxShape.circle,
                ),
                child: Icon(Icons.add, color: colorScheme.onPrimaryContainer),
              ),
              title: Text(
                'Add Account',
                style: TextStyle(fontWeight: isM3E ? FontWeight.w700 : FontWeight.normal),
              ),
              onTap: () {
                Navigator.pop(context);
                context.push('/login?add_account=true');
              },
            ),
          ],
        ),
      ),
    );

    if (disableTransparency) {
      return sheetContent;
    }

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(isM3E ? 48 : 28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: sheetContent,
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
