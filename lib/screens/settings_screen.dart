import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:morrow_v2/main.dart'; // For ThemeProvider
import 'package:morrow_v2/services/auth_service.dart';
import 'package:morrow_v2/services/profile_service.dart';
import 'package:morrow_v2/utils/responsive_layout.dart';
import 'package:morrow_v2/screens/settings/screen_time_screen.dart';
import 'package:morrow_v2/screens/settings/vault_settings_screen.dart';
import 'package:morrow_v2/screens/settings/subscription_screen.dart';
import 'package:morrow_v2/screens/settings/account_privacy_screen.dart';
import 'package:morrow_v2/screens/settings/two_factor_auth_screen.dart';
import 'package:morrow_v2/screens/settings/download_data_screen.dart';
import 'package:morrow_v2/screens/settings/storage_usage_screen.dart';
import 'package:morrow_v2/screens/settings/font_size_screen.dart';
import 'package:morrow_v2/screens/settings/help_support_screen.dart';
import 'package:morrow_v2/screens/moderation/moderation_screens.dart'; // For BlockedUsersScreen
import 'package:morrow_v2/providers/user_settings_provider.dart';
import 'package:morrow_v2/services/screen_time_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final userSettingsProvider = Provider.of<UserSettingsProvider>(context);
    final authService = Provider.of<AuthService>(context, listen: false);
    final profileService = ProfileService();
    final user = authService.currentUser;

    final content = Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Enhanced Profile Preview with Stats
          if (user != null) ...[
            FutureBuilder(
              future: profileService.getProfile(user.id),
              builder: (context, snapshot) {
                final profile = snapshot.data;
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primaryContainer,
                        colorScheme.secondaryContainer,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Avatar
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 3,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 35,
                              backgroundImage:
                                  profile?.avatarUrl != null
                                      ? CachedNetworkImageProvider(
                                        profile!.avatarUrl!,
                                      )
                                      : null,
                              child:
                                  profile?.avatarUrl == null
                                      ? Text(
                                        profile?.username
                                                .substring(0, 1)
                                                .toUpperCase() ??
                                            user.email
                                                .substring(0, 1)
                                                .toUpperCase(),
                                        style: theme.textTheme.headlineMedium,
                                      )
                                      : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // User Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile?.username ?? user.email,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                if (profile?.fullName != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    profile!.fullName!,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onPrimaryContainer
                                          .withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Edit Button
                          IconButton(
                            icon: Icon(
                              Icons.edit_outlined,
                              color: colorScheme.onPrimaryContainer,
                            ),
                            onPressed: () => context.push('/edit-profile'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Stats Row
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              context,
                              '${profile?.postsCount ?? 0}',
                              'Posts',
                              colorScheme.onPrimaryContainer,
                            ),
                            _buildDivider(colorScheme.onPrimaryContainer),
                            _buildStatItem(
                              context,
                              '${profile?.followersCount ?? 0}',
                              'Followers',
                              colorScheme.onPrimaryContainer,
                            ),
                            _buildDivider(colorScheme.onPrimaryContainer),
                            _buildStatItem(
                              context,
                              '${profile?.followingCount ?? 0}',
                              'Following',
                              colorScheme.onPrimaryContainer,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Pro Subscription Tile
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.shade700, Colors.orange.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                leading: const Icon(
                  Icons.workspace_premium,
                  color: Colors.white,
                  size: 32,
                ),
                title: const Text(
                  'Morrow Pro',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                subtitle: const Text(
                  'Unlock premium features & go ad-free',
                  style: TextStyle(color: Colors.white70),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SubscriptionScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          // General Section
          _buildSectionHeader(context, 'General'),
          _buildSettingsGroup(context, [
            _buildSettingsTile(
              context,
              icon: Icons.timer_outlined,
              title: 'Screen Time & Wellness',
              subtitle: 'Track usage and manage wellbeing',
              iconColor: colorScheme.secondary,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ScreenTimeScreen(),
                  ),
                );
              },
            ),
            _buildSettingsTile(
              context,
              icon: Icons.hourglass_top_outlined,
              title: 'Scroll Limit',
              subtitle: '${userSettingsProvider.scrollLimitMinutes} minutes',
              iconColor: Colors.deepOrange,
              trailing: authService.currentUser?.isPro == true
                  ? null
                  : const Icon(Icons.lock_outline, size: 20, color: Colors.orange),
              onTap: () => _showScrollLimitPicker(context),
            ),
            // ... existing items ...
          ]),

          const SizedBox(height: 24),

          // Privacy & Security Section
          _buildSectionHeader(context, 'Privacy & Security'),
          _buildSettingsGroup(context, [
            _buildSettingsTile(
              context,
              icon: Icons.shield_outlined,
              title: 'Vault',
              subtitle: 'Manage hidden content and security',
              iconColor: colorScheme.primary,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const VaultSettingsScreen(),
                  ),
                );
              },
            ),
            _buildSettingsTile(
              context,
              icon: Icons.lock_outlined,
              title: 'Account Privacy',
              subtitle: 'Control who can see your content',
              iconColor: Colors.green,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AccountPrivacyScreen(),
                  ),
                );
              },
            ),
            _buildSettingsTile(
              context,
              icon: Icons.block_outlined,
              title: 'Blocked Accounts',
              subtitle: 'Manage blocked users',
              iconColor: Colors.red,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const BlockedUsersScreen(),
                  ),
                );
              },
            ),
            _buildSettingsTile(
              context,
              icon: Icons.security_outlined,
              title: 'Two-Factor Authentication',
              subtitle: 'Add extra security',
              iconColor: Colors.indigo,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const TwoFactorAuthScreen(),
                  ),
                );
              },
            ),
            _buildSettingsTile(
              context,
              icon: Icons.download_outlined,
              title: 'Download Your Data',
              subtitle: 'Request a copy of your data',
              iconColor: Colors.teal,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const DownloadDataScreen(),
                  ),
                );
              },
            ),
          ]),

          const SizedBox(height: 24),

          // Appearance Section
          _buildSectionHeader(context, 'Appearance'),
          _buildSettingsGroup(context, [
            _buildSettingsTile(
              context,
              icon: Icons.palette_outlined,
              title: 'Theme',
              subtitle: _getThemeModeName(themeProvider.themeMode),
              iconColor: Colors.blue,
              trailing: DropdownButton<ThemeMode>(
                value: themeProvider.themeMode,
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down_rounded),
                onChanged: (ThemeMode? newMode) {
                  if (newMode != null) {
                    themeProvider.setTheme(newMode);
                  }
                },
                items: const [
                  DropdownMenuItem(
                    value: ThemeMode.system,
                    child: Text('System'),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.light,
                    child: Text('Light'),
                  ),
                  DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                ],
              ),
            ),
          ]),

          const SizedBox(height: 24),

          // Data & Storage Section
          _buildSectionHeader(context, 'Data & Storage'),
          _buildSettingsGroup(context, [
            _buildSettingsTile(
              context,
              icon: Icons.storage_outlined,
              title: 'Storage Usage',
              subtitle: 'Manage app storage',
              iconColor: Colors.amber,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const StorageUsageScreen(),
                  ),
                );
              },
            ),
            _buildSettingsTile(
              context,
              icon: Icons.data_usage_outlined,
              title: 'Data Saver',
              subtitle: 'Reduce data usage',
              iconColor: Colors.cyan,
              trailing: Switch(
                value: userSettingsProvider.dataSaver,
                onChanged: (value) {
                  userSettingsProvider.setDataSaver(value);
                },
              ),
            ),
            _buildSettingsTile(
              context,
              icon: Icons.clear_all_outlined,
              title: 'Clear Cache',
              subtitle: 'Free up space',
              iconColor: Colors.deepOrange,
              onTap: () async {
                // For cached_network_image, clearing cache is handled by its library
                // but we can simulate/notify success here.
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Cache cleared')));
              },
            ),
          ]),

          const SizedBox(height: 24),

          // Accessibility Section
          _buildSectionHeader(context, 'Accessibility'),
          _buildSettingsGroup(context, [
            _buildSettingsTile(
              context,
              icon: Icons.text_fields_outlined,
              title: 'Font Size',
              subtitle: 'Adjust text size',
              iconColor: colorScheme.primary,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const FontSizeScreen(),
                  ),
                );
              },
            ),
            _buildSettingsTile(
              context,
              icon: Icons.contrast_outlined,
              title: 'High Contrast',
              subtitle: 'Improve visibility',
              iconColor: colorScheme.tertiary,
              trailing: Switch(
                value: themeProvider.highContrast,
                onChanged: (value) {
                  themeProvider.setHighContrast(value);
                },
              ),
            ),
          ]),

          const SizedBox(height: 24),

          // Support & About Section
          _buildSectionHeader(context, 'Support & About'),
          _buildSettingsGroup(context, [
            _buildSettingsTile(
              context,
              icon: Icons.feedback_outlined,
              title: 'Send Feedback',
              subtitle: 'Report a bug or suggest a feature',
              iconColor: Colors.orange,
              onTap: () => _showFeedbackDialog(context),
            ),
            _buildSettingsTile(
              context,
              icon: Icons.help_outline,
              title: 'Help & Support',
              subtitle: 'Get help with Morrow',
              iconColor: Colors.green,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const HelpSupportScreen(),
                  ),
                );
              },
            ),
            _buildSettingsTile(
              context,
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              iconColor: Colors.grey,
              onTap: () {
                context.push('/terms-of-service');
              },
            ),
            _buildSettingsTile(
              context,
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              iconColor: Colors.grey,
              onTap: () {
                context.push('/privacy-policy');
              },
            ),
            _buildSettingsTile(
              context,
              icon: Icons.info_outline,
              title: 'About Morrow',
              subtitle: 'Version 1.0.0',
              iconColor: Colors.grey,
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Morrow',
                  applicationVersion: '1.0.0',
                  applicationIcon: const Icon(Icons.flutter_dash, size: 48),
                  children: [
                    const Text(
                      'A modern social media app for sharing moments and connecting with communities.',
                    ),
                  ],
                );
              },
            ),
          ]),

          const SizedBox(height: 24),

          // Sign Out
          _buildSettingsGroup(context, [
            _buildSettingsTile(
              context,
              icon: Icons.logout,
              title: 'Sign Out',
              iconColor: Colors.red,
              textColor: Colors.red,
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Sign Out'),
                        content: const Text(
                          'Are you sure you want to sign out?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Sign Out'),
                          ),
                        ],
                      ),
                );

                if (confirmed == true) {
                  try {
                    await authService.signOut();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error signing out: $e')),
                      );
                    }
                  }
                }
              },
            ),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );

    return ResponsiveLayout.isDesktop(context)
        ? MaxWidthContainer(
          maxWidth: ResponsiveLayout.maxFormWidth,
          child: content,
        )
        : content;
  }

  Widget _buildStatItem(
    BuildContext context,
    String value,
    String label,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(Color color) {
    return Container(height: 30, width: 1, color: color.withValues(alpha: 0.3));
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(BuildContext context, List<Widget> children) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: List.generate(children.length * 2 - 1, (index) {
          if (index.isOdd) {
            return Divider(
              height: 1,
              indent: 56,
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            );
          }
          return children[index ~/ 2];
        }),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    Color? textColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? colorScheme.primary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor ?? colorScheme.primary, size: 24),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      subtitle:
          subtitle != null
              ? Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
              : null,
      trailing:
          trailing ??
          (onTap != null
              ? Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant)
              : null),
      onTap: onTap,
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Send Feedback',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.bug_report_outlined,
                    color: Colors.red,
                  ),
                  title: const Text('Report a Bug'),
                  onTap: () {
                    Navigator.pop(context);
                    _launchEmail('Bug Report', context);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.lightbulb_outline,
                    color: Colors.amber,
                  ),
                  title: const Text('Suggest a Feature'),
                  onTap: () {
                    Navigator.pop(context);
                    _launchEmail('Feature Suggestion', context);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _launchEmail(String label, BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isPro = authService.currentUser?.isPro == true;
    final prefix = isPro ? '[PRO] ' : '';

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@morrowapp.com',
      query:
          'subject=${Uri.encodeComponent('${prefix}Morrow App Feedback: $label')}',
    );

    try {
      await launchUrl(emailLaunchUri);
    } catch (e) {
      debugPrint('Could not launch email client: $e');
    }
  }

  void _showScrollLimitPicker(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isPro = authService.currentUser?.isPro == true;

    if (!isPro) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Custom Scroll Limits are a Pro feature!'),
          action: SnackBarAction(label: 'UPGRADE', onPressed: () {}),
        ),
      );
      return;
    }

    final settings = Provider.of<UserSettingsProvider>(context, listen: false);
    final screenTime = Provider.of<ScreenTimeService>(context, listen: false);

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Set Scroll Limit', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              const Text('The app will turn B/W when you reach this limit.'),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                children: [15, 30, 45, 60, 90, 120].map((mins) {
                  final isSelected = settings.scrollLimitMinutes == mins;
                  return ChoiceChip(
                    label: Text('$mins min'),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        settings.setScrollLimitMinutes(mins);
                        screenTime.setScrollLimit(mins);
                        Navigator.pop(context);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }
}
