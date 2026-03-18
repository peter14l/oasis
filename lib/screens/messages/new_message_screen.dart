import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:oasis_v2/models/user_profile.dart';
import 'package:oasis_v2/services/profile_service.dart';
import 'package:oasis_v2/services/messaging_service.dart';
import 'package:oasis_v2/services/auth_service.dart';

class NewMessageScreen extends StatefulWidget {
  const NewMessageScreen({super.key});

  @override
  State<NewMessageScreen> createState() => _NewMessageScreenState();
}

class _NewMessageScreenState extends State<NewMessageScreen> {
  final ProfileService _profileService = ProfileService();
  final MessagingService _messagingService = MessagingService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  List<UserProfile> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await _profileService.searchUsers(query: query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _startConversation(UserProfile user) async {
    final currentUserId = _authService.currentUser?.id;
    if (currentUserId == null) return;

    try {
      // Get or create conversation
      final conversationId = await _messagingService.getOrCreateConversation(
        user1Id: currentUserId,
        user2Id: user.id,
      );

      if (mounted) {
        // Navigate to chat screen
        context.go('/messages/$conversationId', extra: {
          'otherUserName': user.username,
          'otherUserAvatar': user.avatarUrl ?? '',
          'otherUserId': user.id,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Message'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchResults = []);
                        },
                      )
                    : null,
              ),
              onChanged: _searchUsers,
            ),
          ),

          // Search Results
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_search,
                              size: 64,
                              color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'Search for users to message'
                                  : 'No users found',
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final user = _searchResults[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                                    ? CachedNetworkImageProvider(user.avatarUrl!)
                                    : null,
                                child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                                    ? Text(user.username[0].toUpperCase())
                                    : null,
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    user.username,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (user.isVerified) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.verified,
                                      size: 16,
                                      color: colorScheme.primary,
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: user.fullName != null && user.fullName!.isNotEmpty
                                  ? Text(user.fullName!)
                                  : null,
                              onTap: () => _startConversation(user),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

