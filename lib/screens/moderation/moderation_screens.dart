import 'package:flutter/material.dart';
import 'package:morrow_v2/models/moderation.dart';
import 'package:morrow_v2/services/moderation_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final _moderationService = ModerationService();
  List<BlockedUser> _blockedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _moderationService.getBlockedUsers();
      if (mounted) {
        setState(() {
          _blockedUsers = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading blocked users: $e')),
        );
      }
    }
  }

  Future<void> _unblockUser(String userId, String username) async {
    try {
      await _moderationService.unblockUser(userId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unblocked @$username')));
        _loadBlockedUsers(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error unblocking user: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blocked Users')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _blockedUsers.isEmpty
              ? const Center(child: Text('You haven\'t blocked anyone'))
              : ListView.builder(
                itemCount: _blockedUsers.length,
                itemBuilder: (context, index) {
                  final user = _blockedUsers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          user.avatarUrl != null
                              ? CachedNetworkImageProvider(user.avatarUrl!)
                              : null,
                      child:
                          user.avatarUrl == null
                              ? const Icon(Icons.person)
                              : null,
                    ),
                    title: Text(user.username ?? 'Unknown'),
                    subtitle: Text('Blocked on ${_formatDate(user.createdAt)}'),
                    trailing: TextButton(
                      onPressed:
                          () => _unblockUser(
                            user.blockedId,
                            user.username ?? 'Unknown',
                          ),
                      child: const Text('Unblock'),
                    ),
                  );
                },
              ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class MutedUsersScreen extends StatefulWidget {
  const MutedUsersScreen({super.key});

  @override
  State<MutedUsersScreen> createState() => _MutedUsersScreenState();
}

class _MutedUsersScreenState extends State<MutedUsersScreen> {
  final _moderationService = ModerationService();
  List<MutedUser> _mutedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMutedUsers();
  }

  Future<void> _loadMutedUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _moderationService.getMutedUsers();
      if (mounted) {
        setState(() {
          _mutedUsers = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading muted users: $e')),
        );
      }
    }
  }

  Future<void> _unmuteUser(String userId, String username) async {
    try {
      await _moderationService.unmuteUser(userId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unmuted @$username')));
        _loadMutedUsers(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error unmuting user: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Muted Users')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _mutedUsers.isEmpty
              ? const Center(child: Text('You haven\'t muted anyone'))
              : ListView.builder(
                itemCount: _mutedUsers.length,
                itemBuilder: (context, index) {
                  final user = _mutedUsers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          user.avatarUrl != null
                              ? CachedNetworkImageProvider(user.avatarUrl!)
                              : null,
                      child:
                          user.avatarUrl == null
                              ? const Icon(Icons.person)
                              : null,
                    ),
                    title: Text(user.username ?? 'Unknown'),
                    subtitle: Text(
                      user.expiresAt != null
                          ? 'Muted until ${_formatDate(user.expiresAt!)}'
                          : 'Muted indefinitely',
                    ),
                    trailing: TextButton(
                      onPressed:
                          () => _unmuteUser(
                            user.mutedId,
                            user.username ?? 'Unknown',
                          ),
                      child: const Text('Unmute'),
                    ),
                  );
                },
              ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
