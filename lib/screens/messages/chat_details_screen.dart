import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oasis_v2/services/messaging_service.dart';
import 'package:oasis_v2/services/vault_service.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class ChatDetailsScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserName;
  final String otherUserAvatar;
  final String otherUserId;
  final bool isWhisperMode;
  final String? currentBackground;

  const ChatDetailsScreen({
    super.key,
    required this.conversationId,
    required this.otherUserName,
    required this.otherUserAvatar,
    required this.otherUserId,
    required this.isWhisperMode,
    this.currentBackground,
  });

  @override
  State<ChatDetailsScreen> createState() => _ChatDetailsScreenState();
}

class _ChatDetailsScreenState extends State<ChatDetailsScreen> {
  final MessagingService _messagingService = MessagingService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isWhisperMode = false;
  bool _isLocked = false;
  int _ephemeralDuration = 86400; // Default to 24h
  String? _selectedBackground;

  @override
  void initState() {
    super.initState();
    _isWhisperMode = widget.isWhisperMode;
    _selectedBackground = widget.currentBackground;
    _loadPersistedSettings();
    _checkLockStatus();
  }

  Future<void> _checkLockStatus() async {
    try {
      final vaultService = Provider.of<VaultService>(context, listen: false);
      final isLocked = await vaultService.isInVault(widget.conversationId);
      if (mounted) {
        setState(() => _isLocked = isLocked);
      }
    } catch (e) {
      debugPrint('Error checking lock status: $e');
    }
  }

  Future<void> _loadPersistedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _ephemeralDuration =
            prefs.getInt('chat_duration_${widget.conversationId}') ?? 86400;
      });
    }
  }

  Future<void> _toggleChatLock(bool value) async {
    final vaultService = Provider.of<VaultService>(context, listen: false);

    // Check if vault is enabled first
    final isVaultEnabled = await vaultService.isVaultEnabled();
    if (!isVaultEnabled && value) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enable Vault in Settings first'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    try {
      if (value) {
        await vaultService.addToVault(
          itemId: widget.conversationId,
          type: VaultItemType.conversation,
        );
      } else {
        await vaultService.removeFromVault(widget.conversationId);
      }

      setState(() => _isLocked = value);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value ? 'Chat locked to Vault' : 'Chat unlocked'),
            backgroundColor: value ? Colors.indigo : Colors.grey,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating vault: $e')));
      }
    }
  }

  Future<void> _toggleWhisperMode(bool value) async {
    try {
      await _messagingService.toggleWhisperMode(widget.conversationId, value);
      setState(() => _isWhisperMode = value);

      // Persist the whisper mode setting
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('chat_whisper_${widget.conversationId}', value);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value ? '✨ Whisper Mode enabled' : 'Whisper Mode disabled',
            ),
            backgroundColor:
                value ? Theme.of(context).colorScheme.secondary : Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _setEphemeralDuration(int duration) async {
    setState(() => _ephemeralDuration = duration);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('chat_duration_${widget.conversationId}', duration);
  }

  Future<void> _pickBackground() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image != null) {
        final backgroundUrl = await _messagingService.uploadChatMedia(
          image.path,
          folder: 'backgrounds',
        );

        setState(() => _selectedBackground = backgroundUrl);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('chat_bg_${widget.conversationId}', backgroundUrl);

        try {
          await _messagingService.updateChatBackground(
            widget.conversationId,
            backgroundUrl,
          );
        } catch (e) {
          debugPrint('Failed to sync chat theme to Supabase: $e');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking background: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _removeBackground() async {
    setState(() => _selectedBackground = null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_bg_${widget.conversationId}');

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await Supabase.instance.client.from('chat_themes').upsert({
          'conversation_id': widget.conversationId,
          'user_id': userId,
          'background_image_url': null,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'conversation_id, user_id');
      }
    } catch (e) {
      debugPrint('Failed to sync chat theme removal to Supabase: $e');
    }
  }

  Future<void> _clearChat() async {
    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear Chat?'),
            content: const Text(
              'This will remove all messages from this conversation.',
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop('me'),
                child: const Text('Clear for me'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop('everyone'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Clear for everyone'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );

    if (result != null) {
      try {
        if (result == 'everyone') {
          await _messagingService.clearConversationMessages(
            widget.conversationId,
          );
        } else {
          await _messagingService.clearChatForMe(widget.conversationId);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result == 'everyone'
                    ? 'Chat cleared for everyone'
                    : 'Chat cleared for you',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error clearing chat: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Chat Details'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // Profile Header Card
          _buildProfileHeader(theme, colorScheme),

          const SizedBox(height: 24),

          // Customization Section
          _buildSectionTitle(theme, 'Personalization'),
          _buildDetailCard(
            colorScheme,
            child: Column(
              children: [
                _buildActionTile(
                  icon: Icons.palette_outlined,
                  title: 'Chat Background',
                  subtitle: 'Custom image for this chat',
                  trailing:
                      _selectedBackground != null
                          ? const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          )
                          : null,
                  onTap: _pickBackground,
                ),
                if (_selectedBackground != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          CachedNetworkImage(
                            imageUrl: _selectedBackground!,
                            height: 100,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: IconButton(
                              icon: const Icon(
                                Icons.close,
                                size: 18,
                                color: Colors.white,
                              ),
                              onPressed: _removeBackground,
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black45,
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(28, 28),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                _buildActionTile(
                  icon: Icons.photo_library_outlined,
                  title: 'Media, Files & Links',
                  subtitle: 'Shared content',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Coming soon'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Privacy Section
          _buildSectionTitle(theme, 'Privacy & Safety'),
          _buildDetailCard(
            colorScheme,
            child: Column(
              children: [
                _buildSwitchTile(
                  icon: _isLocked ? Icons.lock : Icons.lock_open_outlined,
                  title: 'Vault Lock',
                  subtitle: 'Hide and protect this chat',
                  value: _isLocked,
                  activeColor: Colors.indigo,
                  onChanged: _toggleChatLock,
                ),
                if (_isLocked)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(56, 0, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lock Interval',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildCompactRadio(
                          'App close',
                          'app_close',
                          colorScheme,
                        ),
                        _buildCompactRadio(
                          'Chat close',
                          'chat_close',
                          colorScheme,
                        ),
                        _buildCompactRadio('5 mins', '5mins', colorScheme),
                      ],
                    ),
                  ),
                const Divider(indent: 56),
                _buildSwitchTile(
                  icon: Icons.auto_delete_outlined,
                  title: 'Whisper Mode',
                  subtitle: 'Self-vanishing messages',
                  value: _isWhisperMode,
                  activeColor: colorScheme.secondary,
                  onChanged: _toggleWhisperMode,
                ),
                if (_isWhisperMode)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(56, 0, 16, 16),
                    child: SegmentedButton<int>(
                      segments: const [
                        ButtonSegment<int>(
                          value: 86400,
                          label: Text('24h'),
                          icon: Icon(Icons.timer_outlined, size: 16),
                        ),
                        ButtonSegment<int>(
                          value: 0,
                          label: Text('Instant'),
                          icon: Icon(Icons.flash_on_outlined, size: 16),
                        ),
                      ],
                      selected: {_ephemeralDuration},
                      onSelectionChanged: (Set<int> newSelection) {
                        _setEphemeralDuration(newSelection.first);
                      },
                      style: SegmentedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Actions Section
          _buildSectionTitle(theme, 'Manage'),
          _buildDetailCard(
            colorScheme,
            child: Column(
              children: [
                _buildActionTile(
                  icon: Icons.notifications_none_rounded,
                  title: 'Mute Notifications',
                  onTap: () {},
                ),
                _buildActionTile(
                  icon: Icons.delete_sweep_outlined,
                  title: 'Clear Chat',
                  titleColor: colorScheme.error,
                  iconColor: colorScheme.error,
                  onTap: _clearChat,
                ),
                _buildActionTile(
                  icon: Icons.block_flipped,
                  title: 'Block ${widget.otherUserName}',
                  titleColor: colorScheme.error,
                  iconColor: colorScheme.error,
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
            backgroundImage:
                widget.otherUserAvatar.isNotEmpty
                    ? CachedNetworkImageProvider(widget.otherUserAvatar)
                    : null,
            child:
                widget.otherUserAvatar.isEmpty
                    ? Text(
                      widget.otherUserName[0].toUpperCase(),
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: colorScheme.primary,
                      ),
                    )
                    : null,
          ),
          const SizedBox(height: 16),
          Text(
            widget.otherUserName,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user, size: 14, color: colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  'End-to-End Encrypted',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDetailCard(ColorScheme colorScheme, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: child,
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? titleColor,
    Color? iconColor,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? titleColor),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Color activeColor,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: value ? activeColor : null),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
      ),
      subtitle: Text(subtitle),
      value: value,
      activeColor: activeColor,
      onChanged: onChanged,
    );
  }

  Widget _buildCompactRadio(String label, String value, ColorScheme colorScheme) {
    final vault = context.watch<VaultService>();
    final current = vault.getLockInterval(widget.conversationId);
    final isSelected = current == value;

    return GestureDetector(
      onTap: () => context.read<VaultService>().setLockInterval(widget.conversationId, value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Radio<String>(
                value: value,
                groupValue: current,
                activeColor: Colors.indigo,
                onChanged: (val) {
                  if (val != null) {
                    context.read<VaultService>().setLockInterval(widget.conversationId, val);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? Colors.indigo : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
