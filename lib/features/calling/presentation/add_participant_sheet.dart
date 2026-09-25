import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oasis/features/calling/call_controller.dart';
import 'package:oasis/features/profile/domain/models/user_profile_entity.dart';
import 'package:oasis/features/profile/presentation/providers/profile_provider.dart';

Future<void> showAddParticipantSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1A1A1A),
    isScrollControlled: true,
    builder: (_) => const AddParticipantSheet(),
  );
}

/// Search a user and add them to the active call's LiveKit room
/// (a second call_sessions row sharing the same room_name).
class AddParticipantSheet extends StatefulWidget {
  const AddParticipantSheet({super.key});

  @override
  State<AddParticipantSheet> createState() => _AddParticipantSheetState();
}

class _AddParticipantSheetState extends State<AddParticipantSheet> {
  final _controller = TextEditingController();
  List<UserProfileEntity> _results = const [];
  bool _searching = false;
  String _error = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = const [];
        _error = '';
      });
      return;
    }
    setState(() {
      _searching = true;
      _error = '';
    });
    try {
      final results = await context.read<ProfileProvider>().searchUsers(query);
      if (!mounted) return;
      setState(() => _results = results);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Search failed');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _invite(UserProfileEntity user) async {
    try {
      await context.read<CallController>().inviteUser(user.id);
    } catch (_) {}
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: 420,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 16, bottom: 12),
              child: Text(
                'Add participant',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _controller,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search by username',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon:
                      const Icon(Icons.search, color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: _search,
                onChanged: _search,
              ),
            ),
            const SizedBox(height: 8),
            if (_searching) const LinearProgressIndicator(),
            if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child:
                    Text(_error, style: const TextStyle(color: Colors.red)),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final user = _results[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[800],
                      backgroundImage: user.avatarUrl != null
                          ? CachedNetworkImageProvider(user.avatarUrl!)
                          : null,
                      child: user.avatarUrl == null
                          ? const Icon(Icons.person, color: Colors.white54)
                          : null,
                    ),
                    title: Text(
                      user.displayName.isNotEmpty
                          ? user.displayName
                          : user.username,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      '@${user.username}',
                      style: const TextStyle(color: Colors.white54),
                    ),
                    trailing: const Icon(Icons.add_call, color: Colors.green),
                    onTap: () => _invite(user),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
