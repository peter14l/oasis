import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:oasis_v2/main.dart'; // For ThemeProvider
import 'package:oasis_v2/services/auth_service.dart';
import 'package:oasis_v2/services/profile_service.dart';
import 'package:oasis_v2/utils/responsive_layout.dart';
import 'package:oasis_v2/screens/settings/screen_time_screen.dart';
import 'package:oasis_v2/screens/settings/vault_settings_screen.dart';
import 'package:oasis_v2/screens/settings/subscription_screen.dart';
import 'package:oasis_v2/screens/settings/account_privacy_screen.dart';
import 'package:oasis_v2/screens/settings/two_factor_auth_screen.dart';
import 'package:oasis_v2/screens/settings/download_data_screen.dart';
import 'package:oasis_v2/screens/settings/storage_usage_screen.dart';
import 'package:oasis_v2/screens/settings/font_size_screen.dart';
import 'package:oasis_v2/screens/settings/help_support_screen.dart';
import 'package:oasis_v2/screens/messages/encryption_setup_screen.dart';
import 'package:oasis_v2/screens/moderation/moderation_screens.dart'; // For BlockedUsersScreen
import 'package:oasis_v2/providers/user_settings_provider.dart';
import 'package:oasis_v2/providers/conversation_provider.dart';
import 'package:oasis_v2/providers/profile_provider.dart';
import 'package:oasis_v2/providers/feed_provider.dart';
import 'package:oasis_v2/providers/community_provider.dart';
import 'package:oasis_v2/providers/notification_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';

enum SettingsCategory {
  account,
  general,
  privacy,
  appearance,
  data,
  accessibility,
  support,
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  SettingsCategory _selectedCategory = SettingsCategory.account;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = MediaQuery.of(context).size.width >= 1000;

    if (isDesktop) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Row(
                children: [
                  // Sidebar
                  Container(
                    width: 280,
                    color: colorScheme.surfaceContainer.withValues(alpha: 0.2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                          child: Text(
                            'Settings',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            children: [
                              _buildSidebarItem(
                                icon: Icons.person_outline,
                                selectedIcon: Icons.person,
                                label: 'Account',
                                category: SettingsCategory.account,
                              ),
                              _buildSidebarItem(
                                icon: Icons.timer_outlined,
                                selectedIcon: Icons.timer,
                                label: 'General',
                                category: SettingsCategory.general,
                              ),
                              _buildSidebarItem(
                                icon: Icons.shield_outlined,
                                selectedIcon: Icons.shield,
                                label: 'Privacy & Security',
                                category: SettingsCategory.privacy,
                              ),
                              _buildSidebarItem(
                                icon: Icons.palette_outlined,
                                selectedIcon: Icons.palette,
                                label: 'Appearance',
                                category: SettingsCategory.appearance,
                              ),
                              _buildSidebarItem(
                                icon: Icons.storage_outlined,
                                selectedIcon: Icons.storage,
                                label: 'Data & Storage',
                                category: SettingsCategory.data,
                              ),
                              _buildSidebarItem(
                                icon: Icons.text_fields_outlined,
                                selectedIcon: Icons.text_fields,
                                label: 'Accessibility',
                                category: SettingsCategory.accessibility,
                              ),
                              _buildSidebarItem(
                                icon: Icons.help_outline,
                                selectedIcon: Icons.help,
                                label: 'Support & About',
                                category: SettingsCategory.support,
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: _buildSignOutButton(context, isDesktop: true),
                        ),
                      ],
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  // Content Area
                  Expanded(
                    child: Scaffold(
                      backgroundColor: Colors.transparent,
                      appBar: AppBar(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        title: Text(_getCategoryTitle(_selectedCategory)),
                        automaticallyImplyLeading: false,
                      ),
                      body: SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 800),
                            child: _buildSelectedCategoryContent(context),
                          ),
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

    // Mobile Layout
    return MaxWidthContainer(
      maxWidth: ResponsiveLayout.maxFormWidth,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Settings'),
          centerTitle: true,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildProfileSection(context),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'General'),
            _buildGeneralSection(context),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'Privacy & Security'),
            _buildPrivacySection(context),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'Appearance'),
            _buildAppearanceSection(context),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'Data & Storage'),
            _buildDataSection(context),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'Accessibility'),
            _buildAccessibilitySection(context),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'Support & About'),
            _buildSupportSection(context),
            const SizedBox(height: 24),
            _buildSignOutButton(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required SettingsCategory category,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _selectedCategory == category;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedCategory = category),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  size: 20,
                  color:
                      isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color:
                        isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getCategoryTitle(SettingsCategory category) {
    switch (category) {
      case SettingsCategory.account:
        return 'Account';
      case SettingsCategory.general:
        return 'General';
      case SettingsCategory.privacy:
        return 'Privacy & Security';
      case SettingsCategory.appearance:
        return 'Appearance';
      case SettingsCategory.data:
        return 'Data & Storage';
      case SettingsCategory.accessibility:
        return 'Accessibility';
      case SettingsCategory.support:
        return 'Support & About';
    }
  }

  Widget _buildSelectedCategoryContent(BuildContext context) {
    switch (_selectedCategory) {
      case SettingsCategory.account:
        return _buildProfileSection(context);
      case SettingsCategory.general:
        return _buildGeneralSection(context);
      case SettingsCategory.privacy:
        return _buildPrivacySection(context);
      case SettingsCategory.appearance:
        return _buildAppearanceSection(context);
      case SettingsCategory.data:
        return _buildDataSection(context);
      case SettingsCategory.accessibility:
        return _buildAccessibilitySection(context);
      case SettingsCategory.support:
        return _buildSupportSection(context);
    }
  }

  Widget _buildProfileSection(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final profileService = ProfileService();
    final user = authService.currentUser;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (user == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FutureBuilder(
          future: profileService.getProfile(user.id),
          builder: (context, snapshot) {
            final profile = snapshot.data;
            return Container(
              padding: const EdgeInsets.all(24),
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
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage:
                            profile?.avatarUrl != null
                                ? CachedNetworkImageProvider(profile!.avatarUrl!)
                                : null,
                        child:
                            profile?.avatarUrl == null
                                ? Text(
                                  profile?.username
                                          .substring(0, 1)
                                          .toUpperCase() ??
                                      'U',
                                  style: theme.textTheme.headlineMedium,
                                )
                                : null,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile?.username ?? user.email,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (profile?.fullName != null)
                              Text(
                                profile!.fullName!,
                                style: theme.textTheme.bodyMedium,
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => context.push('/edit-profile'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
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
        _buildPremiumTile(context),
      ],
    );
  }

  Widget _buildPremiumTile(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade700, Colors.orange.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: const Icon(
          Icons.workspace_premium,
          color: Colors.white,
          size: 32,
        ),
        title: const Text(
          'Oasis Pro',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: const Text(
          'Unlock premium features & go ad-free',
          style: TextStyle(color: Colors.white70),
        ),
        trailing:
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
        onTap:
            () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const SubscriptionScreen(),
              ),
            ),
      ),
    );
  }

  Widget _buildGeneralSection(BuildContext context) {
    return _buildSettingsGroup(context, [
      _buildSettingsTile(
        context,
        icon: Icons.timer_outlined,
        title: 'Screen Time & Wellness',
        subtitle: 'Track usage and manage wellbeing',
        iconColor: Theme.of(context).colorScheme.secondary,
        onTap:
            () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ScreenTimeScreen()),
            ),
      ),
    ]);
  }

  Widget _buildPrivacySection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return _buildSettingsGroup(context, [
      _buildSettingsTile(
        context,
        icon: Icons.shield_outlined,
        title: 'Vault',
        subtitle: 'Manage hidden content and security',
        iconColor: colorScheme.primary,
        onTap:
            () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const VaultSettingsScreen(),
              ),
            ),
      ),
      _buildSettingsTile(
        context,
        icon: Icons.lock_outline,
        title: 'Encryption',
        subtitle: 'Manage End-to-End Encryption keys',
        iconColor: Colors.purple,
        onTap:
            () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const EncryptionSetupScreen(),
              ),
            ),
      ),
      _buildSettingsTile(
        context,
        icon: Icons.lock_outlined,
        title: 'Account Privacy',
        subtitle: 'Control who can see your content',
        iconColor: Colors.green,
        onTap:
            () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AccountPrivacyScreen(),
              ),
            ),
      ),
      _buildSettingsTile(
        context,
        icon: Icons.block_outlined,
        title: 'Blocked Accounts',
        subtitle: 'Manage blocked users',
        iconColor: Colors.red,
        onTap:
            () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const BlockedUsersScreen(),
              ),
            ),
      ),
      _buildSettingsTile(
        context,
        icon: Icons.security_outlined,
        title: 'Two-Factor Authentication',
        subtitle: 'Add extra security',
        iconColor: Colors.indigo,
        onTap:
            () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const TwoFactorAuthScreen(),
              ),
            ),
      ),
      _buildSettingsTile(
        context,
        icon: Icons.download_outlined,
        title: 'Download Your Data',
        subtitle: 'Request a copy of your data',
        iconColor: Colors.teal,
        onTap:
            () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const DownloadDataScreen(),
              ),
            ),
      ),
    ]);
  }

  Widget _buildAppearanceSection(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final userSettingsProvider = Provider.of<UserSettingsProvider>(context);

    return _buildSettingsGroup(context, [
      _buildSettingsTile(
        context,
        icon: Icons.palette_outlined,
        title: 'Theme',
        subtitle: _getThemeModeName(themeProvider.themeMode),
        iconColor: Colors.blue,
        trailing: DropdownButton<ThemeMode>(
          value: themeProvider.themeMode,
          underline: const SizedBox(),
          onChanged:
              (mode) => mode != null ? themeProvider.setTheme(mode) : null,
          items: const [
            DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
            DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
            DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
          ],
        ),
      ),
      _buildSettingsTile(
        context,
        icon: Icons.auto_awesome_motion_outlined,
        title: 'Mesh Background',
        subtitle: 'Dynamic living background.',
        iconColor: Colors.indigo,
        trailing: Switch(
          value: userSettingsProvider.meshEnabled,
          onChanged: (v) => userSettingsProvider.setMeshEnabled(v),
        ),
      ),
    ]);
  }

  Widget _buildDataSection(BuildContext context) {
    final userSettingsProvider = Provider.of<UserSettingsProvider>(context);
    return _buildSettingsGroup(context, [
      _buildSettingsTile(
        context,
        icon: Icons.storage_outlined,
        title: 'Storage Usage',
        subtitle: 'Manage app storage',
        iconColor: Colors.amber,
        onTap:
            () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const StorageUsageScreen(),
              ),
            ),
      ),
      _buildSettingsTile(
        context,
        icon: Icons.data_usage_outlined,
        title: 'Data Saver',
        subtitle: 'Reduce data usage',
        iconColor: Colors.cyan,
        trailing: Switch(
          value: userSettingsProvider.dataSaver,
          onChanged: (v) => userSettingsProvider.setDataSaver(v),
        ),
      ),
      _buildSettingsTile(
        context,
        icon: Icons.clear_all_outlined,
        title: 'Clear Cache',
        subtitle: 'Free up space',
        iconColor: Colors.deepOrange,
        onTap:
            () => ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Cache cleared'))),
      ),
    ]);
  }

  Widget _buildAccessibilitySection(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return _buildSettingsGroup(context, [
      _buildSettingsTile(
        context,
        icon: Icons.text_fields_outlined,
        title: 'Font Size',
        subtitle: 'Adjust text size',
        iconColor: Theme.of(context).colorScheme.primary,
        onTap:
            () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const FontSizeScreen()),
            ),
      ),
      _buildSettingsTile(
        context,
        icon: Icons.contrast_outlined,
        title: 'High Contrast',
        subtitle: 'Improve visibility',
        iconColor: Theme.of(context).colorScheme.tertiary,
        trailing: Switch(
          value: themeProvider.highContrast,
          onChanged: (v) => themeProvider.setHighContrast(v),
        ),
      ),
    ]);
  }

  Widget _buildSupportSection(BuildContext context) {
    return _buildSettingsGroup(context, [
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
        subtitle: 'Get help with Oasis',
        iconColor: Colors.green,
        onTap:
            () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
            ),
      ),
      _buildSettingsTile(
        context,
        icon: Icons.description_outlined,
        title: 'Terms of Service',
        iconColor: Colors.grey,
        onTap: () => context.push('/terms-of-service'),
      ),
      _buildSettingsTile(
        context,
        icon: Icons.privacy_tip_outlined,
        title: 'Privacy Policy',
        iconColor: Colors.grey,
        onTap: () => context.push('/privacy-policy'),
      ),
      _buildSettingsTile(
        context,
        icon: Icons.info_outline,
        title: 'About Oasis',
        subtitle: 'Version 4.0.0',
        iconColor: Colors.grey,
        onTap: () {
          showAboutDialog(
            context: context,
            applicationName: 'Oasis',
            applicationVersion: '4.0.0',
            applicationIcon: const Icon(Icons.flutter_dash, size: 48),
            children: [
              const Text(
                'A modern social media app for sharing moments and connecting with communities.',
              ),
            ],
          );
        },
      ),
    ]);
  }

  Widget _buildSignOutButton(BuildContext context, {bool isDesktop = false}) {
    final authService = Provider.of<AuthService>(context, listen: false);
    return Container(
      decoration:
          isDesktop
              ? null
              : BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
              ),
      child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.red),
        title: const Text(
          'Sign Out',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        onTap: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
          );

          if (confirmed == true) {
            _clearProviders(context);
            await authService.signOut();
            if (context.mounted) context.go('/login');
          }
        },
      ),
    );
  }

  void _clearProviders(BuildContext context) {
    context.read<ConversationProvider>().clear();
    context.read<ProfileProvider>().clear();
    context.read<FeedProvider>().clear();
    context.read<CommunityProvider>().clear();
    context.read<NotificationProvider>().init(null);
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
      path: 'support@Oasisapp.com',
      query:
          'subject=${Uri.encodeComponent('${prefix}Oasis App Feedback: $label')}',
    );

    try {
      await launchUrl(emailLaunchUri);
    } catch (e) {
      debugPrint('Could not launch email client: $e');
    }
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
