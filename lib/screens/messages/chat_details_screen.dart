import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oasis_v2/services/messaging_service.dart';
import 'package:oasis_v2/services/vault_service.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
        // Require auth to unlock? For now assume open since we are in details
        await vaultService.removeFromVault(widget.conversationId);
      }

      setState(() => _isLocked = value);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value ? 'Chat locked to Vault' : 'Chat unlocked'),
            backgroundColor: value ? Colors.indigo : Colors.grey,
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
              value ? 'Whisper Mode enabled.' : 'Whisper Mode disabled.',
            ),
            backgroundColor: value ? Theme.of(context).colorScheme.secondary : Colors.green,
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
        // Upload background and save to conversation settings
        final backgroundUrl = await _messagingService.uploadChatMedia(
          image.path,
          folder: 'backgrounds',
        );

        setState(() => _selectedBackground = backgroundUrl);

        // Persist the background setting locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'chat_bg_${widget.conversationId}',
          backgroundUrl,
        );

        // Sync with Supabase so it applies to both participants
        try {
          final userId = Supabase.instance.client.auth.currentUser?.id;
          if (userId != null) {
            await Supabase.instance.client.from('chat_themes').upsert({
              'conversation_id': widget.conversationId,
              'user_id': userId,
              'background_image_url': backgroundUrl,
              'updated_at': DateTime.now().toIso8601String(),
            }, onConflict: 'conversation_id, user_id');
          }
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
    // Remove persisted background setting locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_bg_${widget.conversationId}');
    
    // Sync removal with Supabase
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = MediaQuery.of(context).size.width >= 1200;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Details'),
        centerTitle: isDesktop,
        automaticallyImplyLeading: !isDesktop,
        actions:
            isDesktop
                ? [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                ]
                : null,
      ),
      body: ListView(
        children: [
          // User Info Section
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage:
                      widget.otherUserAvatar.isNotEmpty
                          ? CachedNetworkImageProvider(widget.otherUserAvatar)
                          : null,
                  child:
                      widget.otherUserAvatar.isEmpty
                          ? Text(
                            widget.otherUserName[0].toUpperCase(),
                            style: const TextStyle(fontSize: 32),
                          )
                          : null,
                ),
                const SizedBox(height: 16),
                Text(
                  widget.otherUserName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock,
                        size: 16,
                        color: colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'End-to-End Encrypted',
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // Theme Section
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Theme'),
            subtitle: const Text('Customize chat background'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                if (_selectedBackground != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        CachedNetworkImage(
                          imageUrl: _selectedBackground!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton.filled(
                            onPressed: _removeBackground,
                            icon: const Icon(Icons.close),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                OutlinedButton.icon(
                  onPressed: _pickBackground,
                  icon: const Icon(Icons.image),
                  label: Text(
                    _selectedBackground != null
                        ? 'Change Background'
                        : 'Set Background',
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // Privacy & Safety Section
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Privacy & Safety'),
          ),
          SwitchListTile(
            secondary: Icon(
              _isLocked ? Icons.lock : Icons.lock_open,
              color: _isLocked ? Colors.indigo : null,
            ),
            title: const Text('Lock Chat'),
            subtitle: Text(
              _isLocked
                  ? 'Chat is protected by Vault'
                  : 'Hide this chat in Vault',
            ),
            value: _isLocked,
            activeColor: Colors.indigo,
            onChanged: _toggleChatLock,
          ),
          if (_isLocked) ...[
            const Divider(indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'LOCK INTERVAL',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildIntervalOption(
              context,
              'App close',
              'Lock when app is minimized',
              'app_close',
            ),
            _buildIntervalOption(
              context,
              'On Chat Close',
              'Lock immediately when leaving',
              'chat_close',
            ),
            _buildIntervalOption(
              context,
              'After 5mins',
              'Lock after 5 minutes of inactivity',
              '5mins',
            ),
            const SizedBox(height: 16),
          ],
          SwitchListTile(
            secondary: Icon(
              Icons.auto_delete,
              color: _isWhisperMode ? Theme.of(context).colorScheme.secondary : null,
            ),
            title: const Text('Whisper Mode'),
            subtitle: Text(
              _isWhisperMode
                  ? 'Messages vanish 24hrs after being seen'
                  : 'Messages are saved permanently',
            ),
            value: _isWhisperMode,
            activeColor: Theme.of(context).colorScheme.secondary,
            onChanged: _toggleWhisperMode,
          ),
          if (_isWhisperMode)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment<int>(
                    value: 86400,
                    label: Text('24 Hours'),
                    icon: Icon(Icons.timer),
                  ),
                  ButtonSegment<int>(
                    value: 0,
                    label: Text('Immediate'),
                    icon: Icon(Icons.flash_on),
                  ),
                ],
                selected: {_ephemeralDuration},
                onSelectionChanged: (Set<int> newSelection) {
                  _setEphemeralDuration(newSelection.first);
                },
                style: ButtonStyle(visualDensity: VisualDensity.compact),
              ),
            ),

          const Divider(),

          // Media, Files & Links Section
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Media, Files & Links'),
            subtitle: const Text('View shared content'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to media gallery
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Coming soon')));
            },
          ),

          const Divider(),

          // Additional Options
          ListTile(
            leading: const Icon(Icons.notifications_off_outlined),
            title: const Text('Mute Notifications'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Implement mute
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Coming soon')));
            },
          ),
          ListTile(
            leading: Icon(Icons.block, color: colorScheme.error),
            title: Text(
              'Block User',
              style: TextStyle(color: colorScheme.error),
            ),
            onTap: () {
              // TODO: Implement block
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Coming soon')));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIntervalOption(
    BuildContext context,
    String title,
    String subtitle,
    String value,
  ) {
    final vault = context.watch<VaultService>();
    final current = vault.getLockInterval(widget.conversationId);
    final isSelected = current == value;

    return RadioListTile<String>(
      title: Text(title),
      subtitle: Text(subtitle),
      selected: isSelected,
      value: value,
      groupValue: current,
      onChanged: (newValue) {
        if (newValue != null) {
          context.read<VaultService>().setLockInterval(widget.conversationId, newValue);
        }
      },
    );
  }
}
