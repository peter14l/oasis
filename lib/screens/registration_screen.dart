import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DirectMessagesScreen extends StatefulWidget {
  const DirectMessagesScreen({super.key});

  @override
  State<DirectMessagesScreen> createState() => _DirectMessagesScreenState();
}

class _DirectMessagesScreenState extends State<DirectMessagesScreen> {
  final List<Map<String, dynamic>> _conversations = [
    {
      'id': '1',
      'user': {
        'name': 'Alex Johnson',
        'username': 'alexj',
        'avatar': 'https://randomuser.me/api/portraits/men/1.jpg',
      },
      'lastMessage': 'Hey, how are you doing?',
      'time': '2h ago',
      'unread': true,
    },
    {
      'id': '2',
      'user': {
        'name': 'Sarah Williams',
        'username': 'sarahw',
        'avatar': 'https://randomuser.me/api/portraits/women/2.jpg',
      },
      'lastMessage': 'Did you see the latest post?',
      'time': '5h ago',
      'unread': false,
    },
    {
      'id': '3',
      'user': {
        'name': 'Mike Chen',
        'username': 'mikec',
        'avatar': 'https://randomuser.me/api/portraits/men/3.jpg',
      },
      'lastMessage': 'Thanks for your help!',
      'time': '1d ago',
      'unread': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Search functionality
            },
          ),
        ],
      ),
      body: _conversations.isEmpty
          ? _buildEmptyState()
          : Padding(
              padding: EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset + 80 : 100),
              child: ListView.builder(
                itemCount: _conversations.length,
                itemBuilder: (context, index) {
                  final conversation = _conversations[index];
                  return _buildConversationItem(conversation);
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showNewMessageDialog();
        },
        backgroundColor: const Color(0xFF1152D4),
        child: const Icon(Icons.message, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset + 80 : 100),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF1E232D),
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.forum_outlined,
                size: 60,
                color: Color(0xFF9DA6B9),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No messages yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Start a conversation by messaging a friend or community member',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF9DA6B9),
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _showNewMessageDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1152D4),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'New Message',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationItem(Map<String, dynamic> conversation) {
    final user = conversation['user'] as Map<String, dynamic>;
    final isUnread = conversation['unread'] as bool;

    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(user['avatar']),
      ),
      title: Text(
        user['name'],
        style: TextStyle(
          fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
          color: Colors.white,
        ),
      ),
      subtitle: Text(
        conversation['lastMessage'],
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isUnread ? Colors.white : const Color(0xFF9DA6B9),
          fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            conversation['time'],
            style: const TextStyle(
              color: Color(0xFF9DA6B9),
              fontSize: 12,
            ),
          ),
          if (isUnread)
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Color(0xFF1152D4),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
      onTap: () {
        // Navigate to chat screen
        context.push('/messages/${conversation['id']}');
      },
    );
  }

  void _showNewMessageDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E232D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const NewMessageDialog(),
    );
  }
}

class NewMessageDialog extends StatefulWidget {
  const NewMessageDialog({super.key});

  @override
  State<NewMessageDialog> createState() => _NewMessageDialogState();
}

class _NewMessageDialogState extends State<NewMessageDialog> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _suggestedUsers = [
    {
      'name': 'Alex Johnson',
      'username': 'alexj',
      'avatar': 'https://randomuser.me/api/portraits/men/1.jpg',
    },
    {
      'name': 'Sarah Williams',
      'username': 'sarahw',
      'avatar': 'https://randomuser.me/api/portraits/women/2.jpg',
    },
    {
      'name': 'Mike Chen',
      'username': 'mikec',
      'avatar': 'https://randomuser.me/api/portraits/men/3.jpg',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'New Message',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          // Search Bar
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search for people',
              hintStyle: const TextStyle(color: Color(0xFF9DA6B9)),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF9DA6B9)),
              filled: true,
              fillColor: const Color(0xFF282E39),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
            onChanged: (value) {
              // Filter users based on search query
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Suggested',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _suggestedUsers.length,
              itemBuilder: (context, index) {
                final user = _suggestedUsers[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(user['avatar']),
                  ),
                  title: Text(
                    user['name'],
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    '@${user['username']}',
                    style: const TextStyle(color: Color(0xFF9DA6B9)),
                  ),
                  onTap: () {
                    // Start chat with selected user
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}