import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:oasis/services/app_initializer.dart'; // For ThemeProvider
import 'package:oasis/services/auth_service.dart';
import 'package:oasis/core/utils/responsive_layout.dart';
import 'package:oasis/features/settings/presentation/screens/vault_settings_screen.dart';
import 'package:oasis/features/wellness/presentation/screens/wellness_center_screen.dart';
import 'package:oasis/features/settings/presentation/screens/account_privacy_screen.dart';
import 'package:oasis/features/settings/presentation/screens/privacy_heartbeat_screen.dart';
import 'package:oasis/features/settings/presentation/widgets/privacy_transparency_card.dart';
import 'package:oasis/features/settings/presentation/screens/two_factor_auth_screen.dart';
import 'package:oasis/features/settings/presentation/screens/download_data_screen.dart';
import 'package:oasis/features/settings/presentation/screens/storage_usage_screen.dart';
import 'package:oasis/features/settings/presentation/screens/font_size_screen.dart';
import 'package:oasis/features/settings/presentation/screens/help_support_screen.dart';
import 'package:oasis/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:oasis/features/messages/presentation/screens/encryption_setup_screen.dart';
import 'package:oasis/screens/oasis_pro_screen.dart';
import 'package:oasis/screens/moderation/moderation_screens.dart'; // For BlockedUsersScreen
import 'package:oasis/features/settings/presentation/providers/user_settings_provider.dart';
import 'package:oasis/providers/conversation_provider.dart';
import 'package:oasis/features/profile/presentation/providers/profile_provider.dart';
import 'package:oasis/features/feed/presentation/providers/feed_provider.dart';
import 'package:oasis/providers/community_provider.dart';
import 'package:oasis/features/notifications/presentation/providers/notification_provider.dart';
import 'package:oasis/services/desktop_window_service.dart';
import 'package:universal_io/io.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:oasis/widgets/desktop_header.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oasis/core/config/app_config.dart';
import 'package:oasis/core/network/supabase_client.dart';
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
  Widget? _selectedSubPage;
  String? _subPageTitle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.currentUser != null) {
        Provider.of<ProfileProvider>(
          context,
          listen: false,
        ).loadCurrentProfile(authService.currentUser!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isM3E = themeProvider.isM3EEnabled;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(isM3E ? 32 : 24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(isM3E ? 32 : 24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Row(
                  children: [
                    // Sidebar
                    Container(
                      width: 320,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainer.withValues(
                          alpha: 0.2,
                        ),
                        border: Border(
                          right: BorderSide(
                            color: colorScheme.onSurface.withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DesktopHeader(
                            title: 'Settings',
                            showBackButton: true,
                            onBack: () {
                              if (_selectedSubPage != null) {
                                setState(() {
                                  _selectedSubPage = null;
                                  _subPageTitle = null;
                                });
                              } else if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go('/profile');
                              }
                            },
                          ),
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              children: [
                                _buildSidebarItem(
                                  icon: FluentIcons.person_24_regular,
                                  selectedIcon: FluentIcons.person_24_filled,
                                  label: 'Account',
                                  category: SettingsCategory.account,
                                ),
                                _buildSidebarItem(
                                  icon: FluentIcons.timer_24_regular,
                                  selectedIcon: FluentIcons.timer_24_filled,
                                  label: 'General',
                                  category: SettingsCategory.general,
                                ),
                                _buildSidebarItem(
                                  icon: FluentIcons.shield_24_regular,
                                  selectedIcon: FluentIcons.shield_24_filled,
                                  label: 'Privacy & Security',
                                  category: SettingsCategory.privacy,
                                ),
                                _buildSidebarItem(
                                  icon: FluentIcons.paint_brush_24_regular,
                                  selectedIcon:
                                      FluentIcons.paint_brush_24_filled,
                                  label: 'Appearance',
                                  category: SettingsCategory.appearance,
                                ),
                                _buildSidebarItem(
                                  icon: FluentIcons.storage_24_regular,
                                  selectedIcon: FluentIcons.storage_24_filled,
                                  label: 'Data & Storage',
                                  category: SettingsCategory.data,
                                ),
                                _buildSidebarItem(
                                  icon: FluentIcons.text_font_24_regular,
                                  selectedIcon: FluentIcons.text_font_24_filled,
                                  label: 'Accessibility',
                                  category: SettingsCategory.accessibility,
                                ),
                                _buildSidebarItem(
                                  icon: FluentIcons.question_circle_24_regular,
                                  selectedIcon:
                                      FluentIcons.question_circle_24_filled,
                                  label: 'Support & About',
                                  category: SettingsCategory.support,
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: _buildSignOutButton(
                              context,
                              isDesktop: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Content Area
                    Expanded(
                      child: Column(
                        children: [
                          DesktopHeader(
                            title:
                                _selectedSubPage != null
                                    ? _subPageTitle ?? ''
                                    : _getCategoryTitle(_selectedCategory),
                            showBackButton: _selectedSubPage != null,
                            onBack:
                                () => setState(() {
                                  _selectedSubPage = null;
                                  _subPageTitle = null;
                                }),
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child:
                                _selectedSubPage != null
                                    ? _selectedSubPage!
                                    : SingleChildScrollView(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 40,
                                        vertical: 32,
                                      ),
                                      child: MaxWidthContainer(
                                        maxWidth: 1000,
                                        child: _buildSelectedCategoryContent(
                                          context,
                                        ),
                                      ),
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
            _buildSupportEmailNote(),
            _buildProfileSection(context),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'General'),
            _buildGeneralSection(context, index: 0),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'Privacy & Security'),
            _buildPrivacySection(context, index: 1),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'Appearance'),
            _buildAppearanceSection(context, index: 2),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'Data & Storage'),
            _buildDataSection(context, index: 3),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'Accessibility'),
            _buildAccessibilitySection(context, index: 4),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'Support & About'),
            _buildSupportSection(context, index: 5),
            const SizedBox(height: 24),
            _buildSignOutButton(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  bool _showSupportEmailNote = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadSupportEmailNoteState();
  }

  Future<void> _loadSupportEmailNoteState() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _showSupportEmailNote = !(prefs.getBool('support_email_note_dismissed') ?? false);
      });
    }
  }

  Future<void> _dismissSupportEmailNote() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('support_email_note_dismissed', true);
    if (mounted) {
      setState(() {
        _showSupportEmailNote = false;
      });
    }
  }

  Widget _buildSupportEmailNote() {
    if (!_showSupportEmailNote) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.secondary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: colorScheme.secondary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Important Note',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.secondary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: _dismissSupportEmailNote,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'All feedback, bugs, and reports will be sent to oasis.officialsupport@outlook.com. This is subject to change when our official domain is available.',
            style: TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _navigateToSubPage(String title, Widget page) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    if (isDesktop) {
      setState(() {
        _selectedSubPage = page;
        _subPageTitle = title;
      });
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) => page));
    }
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isM3E = themeProvider.isM3EEnabled;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap:
              () => setState(() {
                _selectedCategory = category;
                _selectedSubPage = null;
                _subPageTitle = null;
              }),
          borderRadius: BorderRadius.circular(isM3E ? 16 : 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(isM3E ? 16 : 12),
              border:
                  isSelected
                      ? Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.2),
                      )
                      : null,
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  size: 22,
                  color:
                      isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight:
                        isSelected ? FontWeight.w900 : FontWeight.w600,
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
        return _buildGeneralSection(context, index: 0);
      case SettingsCategory.privacy:
        return _buildPrivacySection(context, index: 1);
      case SettingsCategory.appearance:
        return _buildAppearanceSection(context, index: 2);
      case SettingsCategory.data:
        return _buildDataSection(context, index: 3);
      case SettingsCategory.accessibility:
        return _buildAccessibilitySection(context, index: 4);
      case SettingsCategory.support:
        return _buildSupportSection(context, index: 5);
    }
  }

  Widget _buildProfileSection(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(context);
    final profile = profileProvider.currentProfile;
    final user = authService.currentUser;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isM3E = themeProvider.isM3EEnabled;

    if (user == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (profileProvider.isLoading && profile == null)
          const Center(child: CircularProgressIndicator())
        else if (profile != null)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient:
                  isM3E
                      ? LinearGradient(
                        colors: [
                          colorScheme.primaryContainer,
                          colorScheme.tertiaryContainer,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                      : LinearGradient(
                        colors: [
                          colorScheme.primaryContainer,
                          colorScheme.secondaryContainer,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
              borderRadius: BorderRadius.circular(isM3E ? 32 : 20),
              border:
                  isM3E
                      ? Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.3,
                        ),
                        width: 1,
                      )
                      : null,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: isM3E ? const EdgeInsets.all(3) : EdgeInsets.zero,
                      decoration:
                          isM3E
                              ? BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colorScheme.onPrimaryContainer,
                                  width: 2,
                                ),
                              )
                              : null,
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage:
                            profile.avatarUrl != null
                                ? CachedNetworkImageProvider(profile.avatarUrl!)
                                : null,
                        child:
                            profile.avatarUrl == null
                                ? Text(
                                  profile.username
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(
                                        fontWeight:
                                            isM3E ? FontWeight.w600 : null,
                                      ),
                                )
                                : null,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  profile.username,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                              if (profile.isPro)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'PRO',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (profile.fullName != null)
                            Text(
                              profile.fullName!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onPrimaryContainer
                                    .withValues(alpha: 0.8),
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      color: colorScheme.onPrimaryContainer,
                      onPressed:
                          () => _navigateToSubPage(
                            'Edit Profile',
                            const EditProfileScreen(),
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimaryContainer.withValues(
                      alpha: 0.15,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        context,
                        '${profile.postsCount}',
                        'Posts',
                        colorScheme.onPrimaryContainer,
                      ),
                      _buildDivider(colorScheme.onPrimaryContainer),
                      _buildStatItem(
                        context,
                        '${profile.followersCount}',
                        'Followers',
                        colorScheme.onPrimaryContainer,
                      ),
                      _buildDivider(colorScheme.onPrimaryContainer),
                      _buildStatItem(
                        context,
                        '${profile.followingCount}',
                        'Following',
                        colorScheme.onPrimaryContainer,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        profile?.isPro == true ? _buildProMemberTile(context) : _buildPremiumTile(context),
        const SizedBox(height: 24),
        _buildDangerZone(context),
      ],
    );
  }

  Widget _buildDangerZone(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isM3E = themeProvider.isM3EEnabled;

    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(isM3E ? 28 : 16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
        title: const Text(
          'Delete Account',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('Permanently remove your account and data'),
        trailing: const Icon(Icons.chevron_right, color: Colors.red),
        onTap: () => context.push('/settings/delete-account'),
      ),
    );
  }

  Future<void> _handleCancelSubscription() async {
    final theme = Theme.of(context);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription?'),
        content: const Text(
          'Your Pro features will remain active until the end of your current billing period. Automatic renewal will be disabled.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Pro'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel Subscription'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Processing cancellation...')),
      );

      try {
        final supabase = SupabaseService().client;
        final response = await supabase.functions.invoke('razorpay-cancel-subscription');
        
        if (response.status != 200) {
          throw Exception(response.data['error'] ?? 'Failed to cancel subscription');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subscription cancelled. Auto-renewal disabled.'),
              backgroundColor: Colors.orange,
            ),
          );
          
          // Refresh profile to update UI if needed
          final authService = Provider.of<AuthService>(context, listen: false);
          if (authService.currentUser != null) {
            Provider.of<ProfileProvider>(context, listen: false)
                .loadCurrentProfile(authService.currentUser!.id);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildProMemberTile(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isM3E = themeProvider.isM3EEnabled;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(isM3E ? 28 : 16),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.stars_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pro Member',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Thank you for upgrading to Oasis Pro. You are a Pro member now.',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => launchUrl(Uri.parse(AppConfig.getWebUrl('/profile'))),
                      icon: const Icon(Icons.manage_accounts_rounded, size: 18),
                      label: const Text('Web Profile'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                        side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.5)),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _handleCancelSubscription,
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: const Text('Cancel Subscription'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildPremiumTile(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isM3E = themeProvider.isM3EEnabled;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isM3E
                  ? [Colors.amber.shade600, Colors.deepOrange.shade700]
                  : [Colors.amber.shade700, Colors.orange.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isM3E ? 28 : 16),
        border:
            isM3E
                ? Border.all(
                  color: Colors.amber.withValues(alpha: 0.3),
                  width: 1,
                )
                : null,
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
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.white,
          size: 16,
        ),
        onTap:
            () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (context) => const OasisProScreen())),
      ),
    );
  }

  Widget _buildGeneralSection(BuildContext context, {int index = 0}) {
    return _buildSettingsGroup(context, index: index, [
      _buildSettingsTile(
        context,
        icon: Icons.spa_outlined,
        title: 'Wellness Center',
        subtitle: 'Mindful usage, sessions and limits',
        iconColor: Colors.green,
        onTap:
            () => _navigateToSubPage(
              'Wellness Center',
              const WellnessCenterScreen(),
            ),
      ),
    ]);
  }

  Widget _buildPrivacySection(BuildContext context, {int index = 0}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        _buildSettingsGroup(context, index: index, [
          _buildSettingsTile(
            context,
            icon: Icons.shield_outlined,
            title: 'Vault',
            subtitle: 'Manage hidden content and security',
            iconColor: colorScheme.primary,
            onTap: () => _navigateToSubPage('Vault', const VaultSettingsScreen()),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.lock_outline,
            title: 'Encryption',
            subtitle: 'Manage End-to-End Encryption keys',
            iconColor: Colors.purple,
            onTap:
                () =>
                    _navigateToSubPage('Encryption', const EncryptionSetupScreen()),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.lock_outlined,
            title: 'Account Privacy',
            subtitle: 'Control who can see your content',
            iconColor: Colors.green,
            onTap:
                () => _navigateToSubPage(
                  'Account Privacy',
                  const AccountPrivacyScreen(),
                ),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.block_outlined,
            title: 'Blocked Accounts',
            subtitle: 'Manage blocked users',
            iconColor: Colors.red,
            onTap:
                () => _navigateToSubPage(
                  'Blocked Accounts',
                  const BlockedUsersScreen(),
                ),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.security_outlined,
            title: 'Two-Factor Authentication',
            subtitle: 'Add extra security',
            iconColor: Colors.indigo,
            onTap:
                () => _navigateToSubPage(
                  'Two-Factor Auth',
                  const TwoFactorAuthScreen(),
                ),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.favorite_border_outlined,
            title: 'Privacy Heartbeat',
            subtitle: 'View your data access logs',
            iconColor: Colors.red,
            onTap:
                () => _navigateToSubPage(
                  'Privacy Heartbeat',
                  const PrivacyHeartbeatScreen(),
                ),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.download_outlined,
            title: 'Download Your Data',
            subtitle: 'Request a copy of your data',
            iconColor: Colors.teal,
            onTap:
                () =>
                    _navigateToSubPage('Download Data', const DownloadDataScreen()),
          ),
        ]),
        const SizedBox(height: 24),
        const PrivacyTransparencyCard(),
      ],
    );
  }

  static const List<String> _fonts = [
    'System',
    'Comfortaa',
    'Roboto Flex',
    'Inter',
    'Lexend',
    'Outfit',
    'Plus Jakarta Sans',
    'Space Grotesk',
    'Syne',
    'Montserrat',
    'Lora',
    'Playfair Display',
    'Work Sans',
  ];

  Widget _buildAppearanceSection(BuildContext context, {int index = 0}) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final userSettingsProvider = Provider.of<UserSettingsProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return _buildSettingsGroup(context, index: index, [
      _buildSettingsTile(
        context,
        icon: Icons.palette_outlined,
        title: 'Theme',
        subtitle: _getThemeModeName(themeProvider.themeMode),
        iconColor: Colors.blue,
        trailing: DropdownButton<ThemeMode>(
          value: themeProvider.themeMode,
          dropdownColor: colorScheme.surfaceContainerHigh,
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
        icon: Icons.font_download_outlined,
        title: 'App Font',
        subtitle: userSettingsProvider.fontFamily,
        iconColor: Colors.teal,
        trailing: DropdownButton<String>(
          value: userSettingsProvider.fontFamily,
          dropdownColor: colorScheme.surfaceContainerHigh,
          underline: const SizedBox(),
          onChanged: (font) {
            if (font != null) {
              userSettingsProvider.setFontFamily(font);
            }
          },
          items:
              _fonts.map((font) {
                return DropdownMenuItem(
                  value: font,
                  child: Text(
                    font,
                    style: TextStyle(
                      fontFamily: font == 'System' ? null : font,
                    ),
                  ),
                );
              }).toList(),
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
      _buildSettingsTile(
        context,
        icon: Icons.rocket_launch_outlined,
        title: 'M3 Expressive',
        subtitle: 'Vibrant & high-contrast design.',
        iconColor: Colors.pink,
        trailing: Switch(
          value: themeProvider.isM3EEnabled,
          onChanged: (v) => themeProvider.setM3EEnabled(v),
        ),
      ),
      if (themeProvider.isM3EEnabled)
        _buildSettingsTile(
          context,
          icon: Icons.color_lens_outlined,
          title: 'Dynamic Theme',
          subtitle: 'Use system colors (Material You).',
          iconColor: Colors.orange,
          trailing: Switch(
            value: themeProvider.useMaterialYou,
            onChanged: (v) => themeProvider.setMaterialYou(v),
          ),
        ),
      if (themeProvider.isM3EEnabled)
        _buildSettingsTile(
          context,
          icon: Icons.layers_clear_outlined,
          title: 'Disable Transparency',
          subtitle: 'Use solid M3E containers instead of glass.',
          iconColor: Colors.deepPurple,
          trailing: Switch(
            value: themeProvider.isM3ETransparencyDisabled,
            onChanged: (v) => themeProvider.setM3ETransparencyDisabled(v),
          ),
        ),
      if (Platform.isWindows)
        _buildSettingsTile(
          context,
          icon: Icons.window_outlined,
          title: 'Mica UI',
          subtitle: 'Enable Windows translucent effect.',
          iconColor: Colors.blueGrey,
          trailing: Switch(
            value: userSettingsProvider.micaEnabled,
            onChanged: (v) async {
              await userSettingsProvider.setMicaEnabled(v);
              await DesktopWindowService.instance.setWindowEffect(
                enabled: v,
                effect: userSettingsProvider.windowEffect,
              );
            },
          ),
        ),
      if (Platform.isWindows && userSettingsProvider.micaEnabled)
        _buildSettingsTile(
          context,
          icon: Icons.blur_on,
          title: 'Effect Style',
          subtitle: 'Choose between Mica or Acrylic.',
          iconColor: Colors.cyan,
          trailing: DropdownButton<String>(
            value: userSettingsProvider.windowEffect,
            dropdownColor:
                themeProvider.themeMode == ThemeMode.dark
                    ? Colors.grey[900]
                    : Colors.white,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 'mica', child: Text('Mica')),
              DropdownMenuItem(value: 'acrylic', child: Text('Acrylic')),
            ],
            onChanged: (v) async {
              if (v != null) {
                await userSettingsProvider.setWindowEffect(v);
                await DesktopWindowService.instance.setWindowEffect(
                  enabled: userSettingsProvider.micaEnabled,
                  effect: v,
                );
              }
            },
          ),
        ),
    ]);
  }

  Widget _buildDataSection(BuildContext context, {int index = 0}) {
    final userSettingsProvider = Provider.of<UserSettingsProvider>(context);
    return _buildSettingsGroup(context, index: index, [
      _buildSettingsTile(
        context,
        icon: Icons.storage_outlined,
        title: 'Storage Usage',
        subtitle: 'Manage app storage',
        iconColor: Colors.amber,
        onTap:
            () =>
                _navigateToSubPage('Storage Usage', const StorageUsageScreen()),
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

  Widget _buildAccessibilitySection(BuildContext context, {int index = 0}) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return _buildSettingsGroup(context, index: index, [
      _buildSettingsTile(
        context,
        icon: Icons.text_fields_outlined,
        title: 'Font Size',
        subtitle: 'Adjust text size',
        iconColor: Theme.of(context).colorScheme.primary,
        onTap: () => _navigateToSubPage('Font Size', const FontSizeScreen()),
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

  Widget _buildSupportSection(BuildContext context, {int index = 0}) {
    return _buildSettingsGroup(context, index: index, [
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
            () =>
                _navigateToSubPage('Help & Support', const HelpSupportScreen()),
      ),
      _buildSettingsTile(
        context,
        icon: Icons.info_outline,
        title: 'About Oasis',
        subtitle: 'Version 4.1.0',
        iconColor: Colors.grey,
        onTap: () => context.push('/settings/about'),
      ),
    ]);
  }

  Widget _buildSignOutButton(BuildContext context, {bool isDesktop = false}) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final button = ListTile(
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
          if (mounted) {
            context.go('/login');
          }
        }
      },
    );

    if (isDesktop) {
      return Material(color: Colors.transparent, child: button);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: button,
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

  Widget _buildSettingsGroup(
    BuildContext context,
    List<Widget> children, {
    int index = 0,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isM3E = themeProvider.isM3EEnabled;
    final disableTransparency = themeProvider.isM3ETransparencyDisabled;

    // M3E Expressive logic: Varying shapes and textures
    BorderRadius borderRadius;
    if (isM3E) {
      // Rotate through different expressive shapes based on index
      switch (index % 3) {
        case 0:
          borderRadius = BorderRadius.circular(32);
          break;
        case 1:
          borderRadius = const BorderRadius.only(
            topLeft: Radius.circular(48),
            bottomRight: Radius.circular(48),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(12),
          );
          break;
        case 2:
          borderRadius = BorderRadius.circular(16);
          break;
        default:
          borderRadius = BorderRadius.circular(24);
      }
    } else {
      borderRadius = BorderRadius.circular(16);
    }

    final bgColor =
        isM3E
            ? (disableTransparency
                ? (index % 2 == 0
                    ? colorScheme.surfaceContainerHigh
                    : colorScheme.surfaceContainerLow)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3))
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: borderRadius,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(
            alpha: isM3E ? 0.3 : 0.5,
          ),
          width: isM3E ? 1.5 : 1,
        ),
        boxShadow:
            isM3E && disableTransparency
                ? [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
                : null,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Column(
          children: List.generate(children.length * 2 - 1, (idx) {
            if (idx.isOdd) {
              return Divider(
                height: 1,
                indent: 56,
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              );
            }
            return children[idx ~/ 2];
          }),
        ),
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isM3E = themeProvider.isM3EEnabled;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: EdgeInsets.all(isM3E ? 10 : 8),
        decoration: BoxDecoration(
          color: (iconColor ?? colorScheme.primary).withValues(
            alpha: isM3E ? 0.15 : 0.1,
          ),
          borderRadius: BorderRadius.circular(isM3E ? 16 : 10),
        ),
        child: Icon(
          icon,
          color: iconColor ?? colorScheme.primary,
          size: isM3E ? 22 : 24,
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: isM3E ? FontWeight.w600 : FontWeight.w500,
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
      path: 'oasis.officialsupport@outlook.com',
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
