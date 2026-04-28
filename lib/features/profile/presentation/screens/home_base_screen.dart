import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oasis/features/profile/domain/models/user_profile_entity.dart';
import 'package:oasis/features/profile/presentation/providers/profile_provider.dart';
import 'package:oasis/features/profile/presentation/widgets/guestbook_widget.dart';
import 'package:oasis/services/auth_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

class HomeBaseScreen extends StatefulWidget {
  final String userId;

  const HomeBaseScreen({super.key, required this.userId});

  @override
  State<HomeBaseScreen> createState() => _HomeBaseScreenState();
}

class _HomeBaseScreenState extends State<HomeBaseScreen> {
  UserProfileEntity? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await context.read<ProfileProvider>().getProfile(widget.userId);
      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_profile == null) {
      return const Scaffold(body: Center(child: Text('Profile not found')));
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentUserId = context.read<AuthService>().currentUser?.id;
    final isOwner = currentUserId == widget.userId;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: _getTextColorForTheme(_profile!.homeTheme)),
        title: Text(
          '${_profile!.username}\'s Home',
          style: TextStyle(color: _getTextColorForTheme(_profile!.homeTheme)),
        ),
        actions: [
          if (isOwner)
            IconButton(
              icon: Icon(FluentIcons.edit_24_regular, color: _getTextColorForTheme(_profile!.homeTheme)),
              onPressed: () {
                // Show theme picker or edit mode
                _showEditOptions(context);
              },
            ),
        ],
      ),
      body: Container(
        decoration: _getBackgroundDecoration(_profile!.homeTheme, colorScheme),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.4,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildAvatar(colorScheme),
                      const SizedBox(height: 16),
                      Text(
                        _profile!.username,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: _getTextColorForTheme(_profile!.homeTheme),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_profile!.bio != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
                          child: Text(
                            _profile!.bio!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: _getTextColorForTheme(_profile!.homeTheme).withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              sliver: SliverToBoxAdapter(
                child: GuestbookWidget(
                  profileId: widget.userId,
                  currentUserId: currentUserId ?? '',
                  isOwner: isOwner,
                ),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _getTextColorForTheme(_profile!.homeTheme), width: 2),
      ),
      child: CircleAvatar(
        radius: 60,
        backgroundImage: _profile!.avatarUrl != null && _profile!.avatarUrl!.isNotEmpty
            ? CachedNetworkImageProvider(_profile!.avatarUrl!)
            : null,
        child: _profile!.avatarUrl == null || _profile!.avatarUrl!.isEmpty
            ? Text(_profile!.username[0].toUpperCase(), style: const TextStyle(fontSize: 40))
            : null,
      ),
    );
  }

  BoxDecoration _getBackgroundDecoration(String? themeName, ColorScheme colorScheme) {
    switch (themeName) {
      case 'forest':
        return const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        );
      case 'ocean':
        return const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF01579B), Color(0xFF03A9F4)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        );
      case 'sunset':
        return const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF6F00), Color(0xFFFFAB40)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        );
      case 'night':
        return const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1D24), Color(0xFF37474F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        );
      default:
        return BoxDecoration(
          color: colorScheme.surface,
        );
    }
  }

  Color _getTextColorForTheme(String? themeName) {
    if (themeName == null || themeName == 'default') {
      return Theme.of(context).colorScheme.onSurface;
    }
    return Colors.white;
  }

  void _showEditOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Customize Your Home', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 24),
              _buildThemeOption('Default', 'default'),
              _buildThemeOption('Forest', 'forest'),
              _buildThemeOption('Ocean', 'ocean'),
              _buildThemeOption('Sunset', 'sunset'),
              _buildThemeOption('Night', 'night'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(String label, String value) {
    return ListTile(
      title: Text(label),
      trailing: _profile!.homeTheme == value ? const Icon(Icons.check) : null,
      onTap: () {
        context.read<ProfileProvider>().updateHomeBase(
          userId: widget.userId,
          theme: value,
        );
        setState(() {
          _profile = _profile!.copyWith(homeTheme: value);
        });
        Navigator.pop(context);
      },
    );
  }
}
