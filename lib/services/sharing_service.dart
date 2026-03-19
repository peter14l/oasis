import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:oasis_v2/models/message.dart';
import 'package:oasis_v2/models/conversation.dart';
import 'package:oasis_v2/services/messaging_service.dart';
import 'package:oasis_v2/services/auth_service.dart';
import 'package:oasis_v2/services/audio_compression_service.dart';
import 'package:oasis_v2/providers/conversation_provider.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class SharingService {
  static final SharingService _instance = SharingService._internal();
  factory SharingService() => _instance;
  SharingService._internal();

  StreamSubscription? _intentDataStreamSubscription;
  final MessagingService _messagingService = MessagingService();
  final AuthService _authService = AuthService();

  void init(BuildContext context) {
    // For sharing images coming from outside the app while the app is in the memory
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _handleSharedFiles(context, value);
      }
    }, onError: (err) {
      debugPrint("getIntentDataStream error: $err");
    });

    // For sharing images coming from outside the app while the app is closed
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _handleSharedFiles(context, value);
      }
    });
  }

  void dispose() {
    _intentDataStreamSubscription?.cancel();
  }

  void _handleSharedFiles(BuildContext context, List<SharedMediaFile> files) {
    if (_authService.currentUser == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareToChatModal(files: files),
    );
  }
}

class ShareToChatModal extends StatefulWidget {
  final List<SharedMediaFile> files;
  const ShareToChatModal({super.key, required this.files});

  @override
  State<ShareToChatModal> createState() => _ShareToChatModalState();
}

class _ShareToChatModalState extends State<ShareToChatModal> {
  String _searchQuery = '';
  bool _isSending = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final conversations = context.watch<ConversationProvider>().conversations;

    final filteredConversations = conversations.where((c) {
      return c.otherUserName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Share to...',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_isSending)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search people...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filteredConversations.isEmpty
                ? Center(
                    child: Text(
                      'No conversations found',
                      style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredConversations.length,
                    itemBuilder: (context, index) {
                      final conv = filteredConversations[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: conv.otherUserAvatar.isNotEmpty
                              ? NetworkImage(conv.otherUserAvatar)
                              : null,
                          child: conv.otherUserAvatar.isEmpty
                              ? Text(conv.otherUserName[0].toUpperCase())
                              : null,
                        ),
                        title: Text(conv.otherUserName),
                        onTap: _isSending ? null : () => _shareToConversation(conv),
                        trailing: const Icon(Icons.send_rounded),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareToConversation(Conversation conversation) async {
    setState(() => _isSending = true);

    try {
      final messagingService = MessagingService();
      final authService = AuthService();
      final userId = authService.currentUser?.id;
      if (userId == null) return;

      for (final sharedFile in widget.files) {
        String filePath = sharedFile.path;
        final file = File(filePath);
        final sizeInBytes = await file.length();
        final sizeInMb = sizeInBytes / (1024 * 1024);

        // Simple type detection
        final pathLower = sharedFile.path.toLowerCase();
        final isAudio = pathLower.endsWith('.mp3') || pathLower.endsWith('.m4a') || pathLower.endsWith('.wav');

        if (sizeInMb > 50) {
          if (isAudio) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Audio file is large. Compressing...')),
              );
            }
            final compressedPath = await AudioCompressionService().compressAudio(sharedFile.path);
            if (compressedPath != null) {
              filePath = compressedPath;
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('File ${sharedFile.path.split('/').last} is too large and compression failed.')),
                );
              }
              continue;
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('File ${sharedFile.path.split('/').last} is too large (Max 50MB for Free Plan). Skipping.'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            continue;
          }
        }

        String folder = 'files';
        MessageType type = MessageType.document;
        
        if (pathLower.endsWith('.jpg') || pathLower.endsWith('.jpeg') || pathLower.endsWith('.png')) {
          folder = 'images';
          type = MessageType.image;
        } else if (pathLower.endsWith('.mp4') || pathLower.endsWith('.mov')) {
          folder = 'videos';
          type = MessageType.document;
        } else if (isAudio) {
          folder = 'audio';
          type = MessageType.voice;
        }

        final mediaUrl = await messagingService.uploadChatMedia(
          filePath,
          folder: folder,
        );

        await messagingService.sendMessage(
          conversationId: conversation.id,
          senderId: userId,
          content: 'Shared a file',
          messageType: type,
          mediaUrl: mediaUrl,
          mediaFileName: filePath.split('/').last,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shared successfully!'), backgroundColor: Colors.green),
        );
        // Optionally navigate to the chat
        // context.push('/chat/${conversation.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }
}
