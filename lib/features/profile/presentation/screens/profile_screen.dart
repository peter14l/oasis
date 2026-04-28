import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:oasis/features/profile/presentation/providers/profile_provider.dart';
import 'package:oasis/features/profile/domain/models/user_profile_entity.dart';
import 'package:oasis/services/auth_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:oasis/features/auth/presentation/widgets/account_switcher_sheet.dart';
import 'package:oasis/services/app_initializer.dart';
import 'package:oasis/core/utils/responsive_layout.dart';
import 'package:oasis/widgets/desktop_header.dart';
import 'package:oasis/widgets/moderation_dialogs.dart';
import 'package:oasis/widgets/pulse_indicator_widget.dart';
import 'package:oasis/widgets/pulse_picker_sheet.dart';
import 'package:oasis/widgets/wellbeing/warm_whisper_sheet.dart';
import 'package:oasis/widgets/wellbeing/cozy_mode_sheet.dart';
import 'package:oasis/features/wellbeing/presentation/providers/cozy_mode_state.dart';
import 'package:oasis/core/config/app_config.dart';
import 'package:oasis/features/settings/presentation/providers/user_settings_provider.dart';
import 'package:oasis/features/badging/presentation/widgets/badge_widget.dart';
import 'package:oasis/features/profile/presentation/widgets/guestbook_widget.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final ScrollController _scrollController = ScrollController();

  bool get isOwnProfile {
    final currentUserId = _authService.currentUser?.id;
    return widget.userId == null || widget.userId == currentUserId;
  }

  String get targetUserId =>
      widget.userId ?? _authService.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final currentUserId = _authService.currentUser?.id;
    final targetId = targetUserId;
    if (targetId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (isOwnProfile) {
          context.read<ProfileProvider>().loadCurrentProfile(targetId);
        } else if (currentUserId != null) {
          context.read<ProfileProvider>().loadProfile(targetId, currentUserId);
          context.read<ProfileProvider>().checkFollowRequestStatus(
                followerId: currentUserId,
                followingId: targetId,
              );
        }
      });
    }
  }

  Future<void> _handleMessage(String currentUserId, String targetId, UserProfileEntity? profile) async {
    try {
      final conversationId = await context
          .read<ProfileProvider>()
          .getOrCreateConversation(user1Id: currentUserId, user2Id: targetId);
      if (mounted) {
        context.push('/messages/$conversationId', extra: {
          'otherUserId': targetId,
          'otherUserName': profile?.username,
          'otherUserAvatar': profile?.avatarUrl,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting conversation: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isM3E = themeProvider.isM3EEnabled;
    final disableTransparency = themeProvider.isM3ETransparencyDisabled;
    final userId = _authService.currentUser?.id;
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final useFluent = themeProvider.useFluentUI;

    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        final profile = isOwnProfile
            ? profileProvider.currentProfile
            : profileProvider.viewedProfile;

        if (profileProvider.isLoading && profile == null) {
          if (useFluent) {
            return const fluent.ScaffoldPage(
              content: Center(child: fluent.ProgressRing()),
            );
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (profile == null) {
          return const Scaffold(body: Center(child: Text('Profile not found')));
        }

        final isCozy = !isOwnProfile && profile.cozyStatus != null;

        Widget mainContent;
        if (useFluent) {
          mainContent = Material(
            color: Colors.transparent,
            child: _buildFluentProfile(
              profile,
              themeProvider,
              colorScheme,
              profileProvider,
              userId,
            ),
          );
        } else if (isDesktop) {
          mainContent = Material(
            type: MaterialType.transparency,
            child: _buildDesktopLayout(
              profile,
              theme,
              colorScheme,
              profileProvider,
              userId,
              isM3E,
              disableTransparency,
            ),
          );
        } else {
          mainContent = _buildMobileLayout(
            profile,
            theme,
            colorScheme,
            isM3E,
            disableTransparency,
            userId,
          );
        }

        if (isCozy) {
          return Stack(
            children: [
              mainContent,
              _buildCozyCurtain(profile, colorScheme),
            ],
          );
        }

        return mainContent;
      },
    );
  }

  Widget _buildCozyCurtain(UserProfileEntity profile, ColorScheme colorScheme) {
    return Positioned.fill(
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            color: colorScheme.surface.withValues(alpha: 0.7),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        _getCozyEmoji(profile.cozyStatus),
                        style: const TextStyle(fontSize: 48),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      profile.cozyStatus ?? 'In my sanctuary',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (profile.cozyStatusText != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        profile.cozyStatusText!,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 48),
                    OutlinedButton.icon(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: colorScheme.surface,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                          ),
                          builder: (context) => WarmWhisperSheet(
                            recipientId: profile.id,
                            recipientName: profile.displayName,
                          ),
                        );
                      },
                      icon: const Icon(Icons.front_hand_outlined),
                      label: const Text('Send a gentle knock'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

    );
  }

  Widget _buildHomeBaseButton(BuildContext context, ThemeData theme, UserProfileEntity profile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: InkWell(
        onTap: () => context.push('/profile/${profile.id}/home'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
                theme.colorScheme.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.secondary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  FluentIcons.home_24_regular,
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Home Base',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Visit a personal visual space',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDigitalGardenButton(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: InkWell(
        onTap: () => context.push('/garden'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                theme.colorScheme.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.yard_outlined,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Digital Garden',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'A private space to plant your thoughts',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCozyEmoji(String? status) {
    if (status == null) return '🌙';
    if (status.toLowerCase().contains('cocoon')) return '🦋';
    if (status.toLowerCase().contains('reading')) return '📚';
    if (status.toLowerCase().contains('garden')) return '🌱';
    return '🌙';
  }

  Widget _buildFluentProfile(
    UserProfileEntity profile,
    ThemeProvider themeProvider,
    ColorScheme colorScheme,
    ProfileProvider profileProvider,
    String? userId,
  ) {
    return fluent.ScaffoldPage(
      header: fluent.PageHeader(
        title: fluent.HoverButton(
          onPressed: isOwnProfile ? () => AccountSwitcherSheet.show(context) : null,
          builder: (context, states) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  profile.username,
                  style: fluent.FluentTheme.of(context).typography.title,
                ),
                if (isOwnProfile) ...[
                  const SizedBox(width: 8),
                  Icon(
                    fluent.FluentIcons.chevron_down,
                    size: 12,
                    color: states.contains(WidgetState.hovered) 
                      ? fluent.FluentTheme.of(context).accentColor 
                      : null,
                  ),
                ],
              ],
            );
          },
        ),
        commandBar: fluent.CommandBar(
          mainAxisAlignment: MainAxisAlignment.end,
          primaryItems: [
            if (isOwnProfile) ...[
              fluent.CommandBarButton(
                icon: const Icon(fluent.FluentIcons.reading_mode),
                label: const Text('Cozy Hours'),
                onPressed: () => _showCozyPicker(profile, profileProvider),
              ),
              fluent.CommandBarButton(
                icon: const Icon(fluent.FluentIcons.settings),
                label: const Text('Settings'),
                onPressed: () => context.push('/settings'),
              ),
            ],
            fluent.CommandBarButton(
              icon: const Icon(fluent.FluentIcons.share),
              label: const Text('Share'),
              onPressed: () {
                final shareText = isOwnProfile
                    ? 'Check out my profile on Oasis!'
                    : 'Check out ${profile.username} on Oasis!';
                final profileUrl = AppConfig.getWebUrl('/profile/${profile.id}');
                Share.share('$shareText\n$profileUrl');
              },
            ),
          ],
        ),
      ),
      content: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Header Section
                  _buildFluentHeroHeader(profile, themeProvider, colorScheme, profileProvider, userId),
                  const SizedBox(height: 48),
                  
                  // Sanctuary Content
                  const fluent.Divider(),
                  const SizedBox(height: 32),
                  _buildSanctuaryMessage(isFluent: true),
                  const SizedBox(height: 48),
                  if (userId != null)
                    GuestbookWidget(
                      profileId: profile.id,
                      currentUserId: userId,
                      isOwner: isOwnProfile,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCozyPicker(UserProfileEntity profile, ProfileProvider profileProvider) {
    CozyMode? currentMode;
    if (profile.cozyStatus != null) {
      try {
        currentMode = CozyMode.values.firstWhere(
          (m) => m.defaultText == profile.cozyStatus,
          orElse: () => CozyMode.custom,
        );
      } catch (_) {}
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CozyModeSheet(
        currentMode: currentMode,
        currentText: profile.cozyStatusText,
        onSelect: (mode, text, duration) {
          final userId = _authService.currentUser?.id;
          if (userId != null) {
            final DateTime? until = duration != null ? DateTime.now().add(duration) : null;
            profileProvider.setCozyMode(
              userId: userId,
              status: mode.defaultText,
              statusText: text,
              until: until,
            );
          }
        },
        onClear: () {
          final userId = _authService.currentUser?.id;
          if (userId != null) {
            profileProvider.clearCozyMode(userId);
          }
        },
      ),
    );
  }

  Widget _buildSanctuaryMessage({bool isFluent = false}) {
    if (isFluent) {
      final theme = fluent.FluentTheme.of(context);
      return Center(
        child: Column(
          children: [
            Icon(fluent.FluentIcons.heart, size: 48, color: theme.accentColor.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'Welcome to this digital sanctuary',
              style: theme.typography.subtitle?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'A private space for calm and connection.',
              style: theme.typography.body?.copyWith(color: theme.typography.body?.color?.withValues(alpha: 0.6)),
            ),
          ],
        ),
      );
    }

    final theme = Theme.of(context);
    return Center(
      child: Column(
        children: [
          Icon(Icons.favorite_rounded, size: 48, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'Welcome to this digital sanctuary',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'A private space for calm and connection.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }

  Widget _buildFluentHeroHeader(
    UserProfileEntity profile,
    ThemeProvider themeProvider,
    ColorScheme colorScheme,
    ProfileProvider profileProvider,
    String? userId,
  ) {
    final isM3E = themeProvider.isM3EEnabled;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Large Avatar with Fluent Styling
        _buildFluentAvatar(profile, colorScheme, isM3E),
        const SizedBox(width: 48),
        
        // Profile Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    profile.fullName ?? profile.username,
                    style: fluent.FluentTheme.of(context).typography.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (profile.moodEmoji != null) ...[
                    const SizedBox(width: 12),
                    fluent.Tooltip(
                      message: profile.currentMood ?? '',
                      child: Text(
                        profile.moodEmoji!,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '@${profile.username}',
                style: fluent.FluentTheme.of(context).typography.body?.copyWith(
                  color: fluent.FluentTheme.of(context).accentColor.lighter,
                ),
              ),
              const SizedBox(height: 16),
              if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                Text(
                  profile.bio!,
                  style: fluent.FluentTheme.of(context).typography.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
              ],

              // Pulse Status
              if (isOwnProfile)
                _buildFluentPulseSection(profile, profileProvider)
              else if (profile.pulseVisible && profile.hasActivePulse)
                _buildFluentPulseDisplay(profile),

              const SizedBox(height: 24),
               
               // Badges Section
               _buildBadgesSection(userId),
               
               const SizedBox(height: 24),
               
               // Actions
               _buildFluentActionButtons(
                profile,
                profileProvider,
                colorScheme,
                userId,
                isM3E,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFluentAvatar(
    UserProfileEntity profile,
    ColorScheme colorScheme,
    bool isM3E,
  ) {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: isM3E ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: isM3E ? BorderRadius.circular(32) : null,
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: isM3E ? BorderRadius.circular(32) : BorderRadius.circular(90),
        child: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: profile.avatarUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => const fluent.ProgressRing(),
              )
            : Container(
                color: colorScheme.surfaceContainerHighest,
                child: Center(
                  child: Text(
                    profile.username[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildFluentPulseSection(UserProfileEntity profile, ProfileProvider profileProvider) {
    return PulseIndicatorWidget(
      pulseStatus: profile.pulseStatus,
      pulseText: profile.pulseText,
      pulseSince: profile.pulseSince,
      onTap: () => _showPulsePicker(profile, profileProvider),
    );
  }

  Widget _buildFluentPulseDisplay(UserProfileEntity profile) {
    return PulseIndicatorWidget(
      pulseStatus: profile.pulseStatus,
      pulseText: profile.pulseText,
      pulseSince: profile.pulseSince,
      onTap: () {},
    );
  }

  void _showPulsePicker(UserProfileEntity profile, ProfileProvider profileProvider) {
    PulseStatus? currentStatus;
    if (profile.pulseStatus != null) {
      try {
        currentStatus = PulseStatus.values.firstWhere(
          (s) => s.name == profile.pulseStatus,
        );
      } catch (_) {}
    }

    showPulsePicker(
      context: context,
      currentStatus: currentStatus,
      currentText: profile.pulseText,
      onSelect: (status, customText) {
        final userId = _authService.currentUser?.id;
        if (userId != null) {
          profileProvider.setPulseStatus(
            userId: userId,
            status: status.name,
            text: customText,
          );
        }
      },
      onClear: () {
        final userId = _authService.currentUser?.id;
        if (userId != null) {
          profileProvider.clearPulseStatus(userId);
        }
      },
    );
  }

  Widget _buildFluentActionButtons(
    UserProfileEntity profile,
    ProfileProvider profileProvider,
    ColorScheme colorScheme,
    String? currentUserId,
    bool isM3E,
  ) {
    if (isOwnProfile) {
      return Row(
        children: [
          fluent.Button(
            onPressed: () => context.push('/edit-profile'),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(fluent.FluentIcons.edit, size: 16),
                  SizedBox(width: 8),
                  Text('Edit Profile'),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          fluent.Button(
            onPressed: () {
              final userId = _authService.currentUser?.id;
              if (userId != null) {
                 profileProvider.setFortressMode(
                   userId: userId, 
                   enabled: !profile.fortressMode,
                   message: !profile.fortressMode ? 'In my fortress' : null,
                 );
              }
            },
            style: fluent.ButtonStyle(
              backgroundColor: profile.fortressMode 
                ? fluent.WidgetStateProperty.all(fluent.FluentTheme.of(context).accentColor.withValues(alpha: 0.1))
                : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(profile.fortressMode ? fluent.FluentIcons.lock : fluent.FluentIcons.unlock, size: 16),
                  const SizedBox(width: 8),
                  Text(profile.fortressMode ? 'Fortress Active' : 'Fortress Mode'),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        fluent.FilledButton(
          onPressed: () {
            if (currentUserId != null) {
              if (profileProvider.isFollowing) {
                profileProvider.unfollowUser(followerId: currentUserId, followingId: profile.id);
              } else {
                profileProvider.followUser(followerId: currentUserId, followingId: profile.id);
              }
            }
          },
          style: fluent.ButtonStyle(
            backgroundColor: profileProvider.isFollowing
                ? fluent.WidgetStateProperty.all(fluent.FluentTheme.of(context).cardColor)
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(profileProvider.isFollowing ? 'Following' : 'Follow'),
          ),
        ),
        const SizedBox(width: 12),
        if (currentUserId != null)
          fluent.Button(
            onPressed: () => _handleMessage(currentUserId, profile.id, profile),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Icon(fluent.FluentIcons.chat, size: 16),
            ),
          ),
      ],
    );
  }

  // Badge section for profile
  Widget _buildBadgesSection(String? userId) {
    if (userId == null || userId.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TRUST BADGES',
          style: fluent.FluentTheme.of(context).typography.caption?.copyWith(
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<dynamic>>(
          future: _loadUserBadges(userId),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Text(
                'No badges yet',
                style: fluent.FluentTheme.of(context).typography.body?.copyWith(
                  color: fluent.FluentTheme.of(context).typography.body?.color?.withValues(alpha: 0.6),
                ),
              );
            }

            return BadgeListWidget(
              badges: snapshot.data!.cast(),
              badgeSize: 40,
              showLabels: true,
            );
          },
        ),
      ],
    );
  }

  Future<List<dynamic>> _loadUserBadges(String userId) async {
    return BadgeService().getUserBadges(userId);
  }

  Widget _buildDesktopLayout(
    UserProfileEntity profile,
    ThemeData theme,
    ColorScheme colorScheme,
    ProfileProvider profileProvider,
    String? userId,
    bool isM3E,
    bool disableTransparency,
  ) {
    final desktopBgColor = disableTransparency
        ? colorScheme.surface
        : colorScheme.surface.withValues(alpha: 0.4);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
          color: desktopBgColor,
          borderRadius: BorderRadius.circular(isM3E ? 32 : 12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isM3E ? 32 : 12),
          child: disableTransparency
              ? _buildDesktopContent(
                  profile,
                  theme,
                  colorScheme,
                  profileProvider,
                  userId,
                  isM3E,
                  disableTransparency,
                )
              : BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: _buildDesktopContent(
                    profile,
                    theme,
                    colorScheme,
                    profileProvider,
                    userId,
                    isM3E,
                    disableTransparency,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildDesktopContent(
    UserProfileEntity profile,
    ThemeData theme,
    ColorScheme colorScheme,
    ProfileProvider profileProvider,
    String? userId,
    bool isM3E,
    bool disableTransparency,
  ) {
    return Column(
      children: [
        DesktopHeader(
          title: profile.username,
          subtitle: profile.fullName ?? 'Oasis Member',
          showBackButton: true,
          onBack: () => context.pop(),
          actions: [
            if (isOwnProfile) ...[
              IconButton(
                icon: Icon(profile.fortressMode ? Icons.security : Icons.security_outlined),
                color: profile.fortressMode ? colorScheme.primary : null,
                onPressed: () {
                   final uid = _authService.currentUser?.id;
                   if (uid != null) {
                     profileProvider.setFortressMode(
                       userId: uid, 
                       enabled: !profile.fortressMode,
                       message: !profile.fortressMode ? 'In my fortress' : null,
                     );
                   }
                },
                tooltip: 'Fortress Mode',
              ),
              IconButton(
                icon: const Icon(Icons.nights_stay_outlined),
                onPressed: () => _showCozyPicker(profile, profileProvider),
                tooltip: 'Cozy Hours',
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => context.push('/settings'),
                tooltip: 'Settings',
              ),
            ],
          ],
        ),
        const Divider(height: 1),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Pane: Profile Info
              Container(
                width: 350,
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: colorScheme.onSurface.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDesktopAvatar(profile, colorScheme, isM3E),
                      const SizedBox(height: 32),
                      _buildDesktopInfoSection(
                        profile,
                        theme,
                        colorScheme,
                        profileProvider,
                        userId,
                        isM3E,
                      ),
                      const SizedBox(height: 40),
                      _buildDesktopInfoCard(
                        profile,
                        theme,
                        colorScheme,
                        isM3E,
                        disableTransparency,
                      ),
                    ],
                  ),
                ),
              ),
              // Right Pane: Sanctuary Space
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSanctuaryMessage(),
                      const SizedBox(height: 48),
                      if (userId != null)
                        SizedBox(
                          width: 400,
                          child: GuestbookWidget(
                            profileId: profile.id,
                            currentUserId: userId,
                            isOwner: isOwnProfile,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopAvatar(
    UserProfileEntity profile,
    ColorScheme colorScheme,
    bool isM3E,
  ) {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: isM3E ? BoxShape.rectangle : BoxShape.circle,
              borderRadius: isM3E ? BorderRadius.circular(32) : null,
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.tertiary],
              ),
            ),
            child: ClipRRect(
              borderRadius: isM3E
                  ? BorderRadius.circular(28)
                  : BorderRadius.circular(60),
              child: Container(
                width: 120,
                height: 120,
                color: colorScheme.surface,
                child:
                    profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: profile.avatarUrl!,
                        fit: BoxFit.cover,
                      )
                    : Center(
                        child: Text(
                          profile.username[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 32,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: MoodOrbitWidget(
              userId: profile.id,
              currentMood: profile.currentMood,
              currentEmoji: profile.moodEmoji,
              isOwner: isOwnProfile,
            ),
          ),
          if (profile.isPro)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(isM3E ? 8 : 12),
                  border: Border.all(color: colorScheme.surface, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: const Text(
                  'PRO MEMBER',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopInfoSection(
    UserProfileEntity profile,
    ThemeData theme,
    ColorScheme colorScheme,
    ProfileProvider profileProvider,
    String? currentUserId,
    bool isM3E,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                profile.username,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            if (profile.moodEmoji != null)
              Text(profile.moodEmoji!, style: const TextStyle(fontSize: 24)),
          ],
        ),
        const SizedBox(height: 16),
        _buildDesktopActionButtons(
          profile,
          profileProvider,
          theme,
          colorScheme,
          currentUserId,
          isM3E,
        ),
        const SizedBox(height: 24),
        Text(
          profile.fullName ?? profile.username,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (profile.bio != null)
          Text(
            profile.bio!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          _buildHomeBaseButton(context, theme, profile),
          const SizedBox(height: 12),
          if (isOwnProfile)
            _buildDigitalGardenButton(context, theme),
          if (isOwnProfile)
            const SizedBox(height: 24),
          _buildDesktopBadgesSection(context, currentUserId),      ],
    );
  }

  Widget _buildDesktopActionButtons(
    UserProfileEntity profile,
    ProfileProvider profileProvider,
    ThemeData theme,
    ColorScheme colorScheme,
    String? currentUserId,
    bool isM3E,
  ) {
    final radius = isM3E ? 16.0 : 10.0;
    if (isOwnProfile) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => context.push('/edit-profile'),
          icon: const Icon(Icons.edit_note_rounded, size: 18),
          label: const Text('Edit Profile'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: () {
              if (currentUserId != null) {
                if (profileProvider.isFollowing) {
                  profileProvider.unfollowUser(
                    followerId: currentUserId,
                    followingId: profile.id,
                  );
                } else {
                  profileProvider.followUser(
                    followerId: currentUserId,
                    followingId: profile.id,
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: profileProvider.isFollowing
                  ? colorScheme.surfaceContainerHighest
                  : colorScheme.primary,
              foregroundColor: profileProvider.isFollowing
                  ? colorScheme.onSurface
                  : colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius),
              ),
            ),
            child: Text(
              profileProvider.isFollowing ? 'Following' : 'Follow',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (currentUserId != null) ...[
          IconButton.filledTonal(
            onPressed: () => _handleMessage(currentUserId, profile.id, profile),
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        IconButton.filledTonal(
          onPressed: () {
            final shareText = isOwnProfile
                ? 'Check out my profile on Oasis!'
                : 'Check out ${profile.username} on Oasis!';
            final profileUrl = AppConfig.getWebUrl('/profile/${profile.id}');
            Share.share('$shareText\n$profileUrl');
          },
          icon: const Icon(Icons.ios_share_rounded, size: 20),
          style: IconButton.styleFrom(
            padding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopInfoCard(
    UserProfileEntity profile,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isM3E,
    bool disableTransparency,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: disableTransparency
            ? colorScheme.surfaceContainerLow
            : colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(isM3E ? 24 : 12),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'COMMUNITY STATUS',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoRow(Icons.calendar_today_outlined, 'Joined March 2024'),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.verified_user_outlined, 'Identity Verified'),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.favorite_outline_rounded, 'Top 5% Contributor'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  // Desktop badges section
  Widget _buildDesktopBadgesSection(BuildContext context, String? userId) {
    if (userId == null || userId.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TRUST BADGES',
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<dynamic>>(
          future: _loadUserBadges(userId),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Text(
                'No badges yet',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              );
            }

            return BadgeListWidget(
              badges: snapshot.data!.cast(),
              badgeSize: 40,
              showLabels: true,
            );
          },
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
    UserProfileEntity profile,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isM3E,
    bool disableTransparency,
    String? userId,
  ) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildModernAppBar(
            profile,
            theme,
            colorScheme,
            false,
            isM3E,
            disableTransparency,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
              child: Column(
                children: [
                  _buildProfileHeader(profile, theme, colorScheme, isM3E),
                  const SizedBox(height: 24),
                  _buildActionButtons(
                    profile,
                    context.read<ProfileProvider>(),
                    theme,
                    colorScheme,
                    userId,
                    isM3E,
                  ),
                  const SizedBox(height: 24),
                  _buildHomeBaseButton(context, theme, profile),
                  const SizedBox(height: 12),
                  if (isOwnProfile)
                    _buildDigitalGardenButton(context, theme),
                  if (isOwnProfile)
                    const SizedBox(height: 24),
                  _buildMobileBadgesSection(userId),
                  const SizedBox(height: 48),
                  const Divider(),
                  const SizedBox(height: 48),
                  _buildSanctuaryMessage(),
                  const SizedBox(height: 48),
                  if (userId != null)
                    GuestbookWidget(
                      profileId: profile.id,
                      currentUserId: userId,
                      isOwner: isOwnProfile,
                    ),
                ],
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  // Mobile badges section
  Widget _buildMobileBadgesSection(String? userId) {
    if (userId == null || userId.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TRUST BADGES',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<dynamic>>(
          future: _loadUserBadges(userId),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Text(
                'No badges yet',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              );
            }

            return BadgeListWidget(
              badges: snapshot.data!.cast(),
              badgeSize: 40,
              showLabels: true,
            );
          },
        ),
      ],
    );
  }

  Widget _buildProfileHeader(
    UserProfileEntity profile,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isM3E,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: isM3E ? BoxShape.rectangle : BoxShape.circle,
                    borderRadius: isM3E ? BorderRadius.circular(24) : null,
                    gradient: LinearGradient(
                      colors: [colorScheme.primary, colorScheme.tertiary],
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: isM3E
                        ? BorderRadius.circular(21)
                        : BorderRadius.circular(45),
                    child: Container(
                      width: 90,
                      height: 90,
                      color: colorScheme.surface,
                      child:
                          profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: profile.avatarUrl!,
                              fit: BoxFit.cover,
                            )
                          : Center(
                              child: Text(
                                profile.username[0].toUpperCase(),
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                    ),
                  ),
                ),
                Positioned(
                  top: -10,
                  right: -10,
                  child: MoodOrbitWidget(
                    userId: profile.id,
                    currentMood: profile.currentMood,
                    currentEmoji: profile.moodEmoji,
                    isOwner: isOwnProfile,
                  ),
                ),
                if (profile.isPro)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(isM3E ? 8 : 12),
                        border: Border.all(color: colorScheme.surface, width: 2),
                      ),
                      child: const Text(
                        'PRO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.fullName ?? profile.username,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '@${profile.username}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  PulseIndicatorWidget(
                    pulseStatus: profile.pulseStatus,
                    pulseText: profile.pulseText,
                    pulseSince: profile.pulseSince,
                    onTap: isOwnProfile
                        ? () => _showPulsePicker(profile, context.read<ProfileProvider>())
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    UserProfileEntity profile,
    ProfileProvider profileProvider,
    ThemeData theme,
    ColorScheme colorScheme,
    String? currentUserId,
    bool isM3E,
  ) {
    final radius = isM3E ? 24.0 : 18.0;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: isOwnProfile
                  ? FilledButton.icon(
                      onPressed: () => context.push('/edit-profile'),
                      icon: const Icon(Icons.edit_note_rounded, size: 20),
                      label: const Text('Edit Profile'),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(radius),
                        ),
                      ),
                    )
                  : profileProvider.isFollowing
                        ? OutlinedButton(
                            onPressed: () {
                              if (currentUserId != null) {
                                profileProvider.unfollowUser(
                                  followerId: currentUserId,
                                  followingId: profile.id,
                                );
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(radius),
                              ),
                            ),
                            child: const Text('Following'),
                          )
                        : profileProvider.state.hasSentRequest
                        ? OutlinedButton(
                            onPressed: null,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(radius),
                              ),
                            ),
                            child: const Text('Requested'),
                          )
                        : FilledButton(
                            onPressed: () {
                              if (currentUserId != null) {
                                profileProvider.followUser(
                                  followerId: currentUserId,
                                  followingId: profile.id,
                                );
                              }
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(radius),
                              ),
                            ),
                            child: const Text('Follow'),
                          ),
            ),
            const SizedBox(width: 12),
            if (!isOwnProfile && currentUserId != null) ...[
              IconButton.filledTonal(
                onPressed: () => _handleMessage(currentUserId, profile.id, profile),
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(radius),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: colorScheme.surface,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    builder: (context) => WarmWhisperSheet(
                      recipientId: profile.id,
                      recipientName: profile.displayName,
                    ),
                  );
                },
                icon: const Icon(Icons.favorite_outline_rounded),
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: colorScheme.tertiaryContainer,
                  foregroundColor: colorScheme.onTertiaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(radius),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            IconButton.filledTonal(
              onPressed: () {
                final shareText = isOwnProfile
                    ? 'Check out my profile on Oasis!'
                    : 'Check out ${profile.username} on Oasis!';
                final profileUrl = AppConfig.getWebUrl('/profile/${profile.id}');
                Share.share('$shareText\n$profileUrl');
              },
              icon: const Icon(Icons.ios_share_rounded),
              style: IconButton.styleFrom(
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radius),
                ),
              ),
            ),
          ],
        ),
        if (isOwnProfile) ...[
           const SizedBox(height: 12),
           Row(
             children: [
               Expanded(
                 child: OutlinedButton.icon(
                    onPressed: () => _showCozyPicker(profile, profileProvider),
                    icon: const Icon(Icons.nights_stay_rounded),
                    label: Text(profile.cozyStatus != null ? 'Cozy: ${profile.cozyStatus}' : 'Set Cozy Hours'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
                    ),
                 ),
               ),
               const SizedBox(width: 12),
               Expanded(
                 child: OutlinedButton.icon(
                    onPressed: () {
                      final uid = _authService.currentUser?.id;
                      if (uid != null) {
                        profileProvider.setFortressMode(
                          userId: uid, 
                          enabled: !profile.fortressMode,
                          message: !profile.fortressMode ? 'In my fortress' : null,
                        );
                      }
                    },
                    icon: Icon(profile.fortressMode ? Icons.security : Icons.security_outlined),
                    label: Text(profile.fortressMode ? 'Fortress On' : 'Fortress Mode'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
                      foregroundColor: profile.fortressMode ? colorScheme.primary : null,
                    ),
                 ),
               ),
             ],
           ),
        ],
      ],
    );
  }

  Widget _buildModernAppBar(
    UserProfileEntity profile,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDesktop,
    bool isM3E,
    bool disableTransparency,
  ) {
    final appBarBgColor = disableTransparency
        ? theme.colorScheme.surface
        : theme.colorScheme.surface.withValues(alpha: 0.4);

    return SliverAppBar(
      pinned: true,
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: !isDesktop,
      title: InkWell(
        onTap: isOwnProfile ? () => AccountSwitcherSheet.show(context) : null,
        borderRadius: BorderRadius.circular(isM3E ? 12 : 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isM3E ? 12 : 20),
          child: disableTransparency
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: appBarBgColor,
                  child: _buildAppBarTitle(profile, colorScheme),
                )
              : BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: appBarBgColor,
                    child: _buildAppBarTitle(profile, colorScheme),
                  ),
                ),
        ),
      ),
      actions: [
        if (!isDesktop && isOwnProfile)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.more_vert_rounded),
              onPressed: () => context.push('/settings'),
            ),
          ),
        if (!isDesktop && !isOwnProfile)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.more_vert_rounded),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.flag_outlined,
                            color: Colors.red,
                          ),
                          title: const Text(
                            'Report Profile',
                            style: TextStyle(color: Colors.red),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            ReportDialog.show(context, userId: widget.userId);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildAppBarTitle(UserProfileEntity profile, ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          profile.username,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
        ),
        if (isOwnProfile) ...[
          const SizedBox(width: 4),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ],
      ],
    );
  }
}
