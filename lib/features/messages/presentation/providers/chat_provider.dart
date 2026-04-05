import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:file_picker/file_picker.dart' show PlatformFile;
import 'package:oasis/features/messages/domain/models/message.dart';
import 'package:oasis/features/messages/domain/models/message_reaction.dart';
import 'package:oasis/services/messaging_service.dart';
import 'package:oasis/services/auth_service.dart';
import 'package:oasis/core/network/supabase_client.dart';
import 'package:oasis/services/encryption_service.dart';
import 'package:oasis/services/signal/signal_service.dart';
import 'package:oasis/services/smart_reply_service.dart';
import 'package:oasis/features/messages/presentation/providers/chat_state.dart';
import 'package:oasis/features/messages/presentation/providers/chat_encryption_provider.dart';
import 'package:oasis/features/messages/presentation/providers/chat_settings_provider.dart';

/// Main chat provider managing message list, sending, receiving, and UI state.
/// Fully migrated from _ChatScreenState in chat_screen.dart.
class ChatProvider with ChangeNotifier {
  final String conversationId;
  final String? otherUserId;
  final ChatEncryptionProvider encryptionProvider;
  final ChatSettingsProvider settingsProvider;

  ChatState _state = const ChatState();
  ChatState get state => _state;

  // Services
  final MessagingService _messagingService = MessagingService();
  final AuthService _authService = AuthService();
  final EncryptionService _encryptionService = EncryptionService();

  // Realtime subscriptions (managed here, not in ChatState)
  RealtimeChannel? _messageChannel;
  RealtimeChannel? _readReceiptChannel;
  RealtimeChannel? _conversationChannel;
  RealtimeChannel? _reactionsChannel;
  RealtimeChannel? _backgroundChannel;
  StreamSubscription<List<Map<String, dynamic>>>? _callsSubscription;

  // Scroll controller reference
  final ScrollController? scrollController;

  // Session tracking
  final DateTime _sessionStartTime = DateTime.now();
  DateTime? _lastResumeTime;

  // Public key cache for encryption
  final Map<String, String> _publicKeyCache = {};

  // Callbacks for UI actions
  VoidCallback? onReloadRequested;
  Function(String)? onError;
  Function(EncryptionStatus)? onEncryptionNeeded;

  ChatProvider({
    required this.conversationId,
    this.otherUserId,
    this.scrollController,
    ChatEncryptionProvider? encryptionProvider,
    ChatSettingsProvider? settingsProvider,
  }) : encryptionProvider = encryptionProvider ?? ChatEncryptionProvider(),
       settingsProvider =
           settingsProvider ??
           ChatSettingsProvider(conversationId: conversationId);

  /// Helper to update state immutably and notify listeners.
  void setState(ChatState Function(ChatState state) update) {
    _state = update(_state);
    notifyListeners();
  }

  // =========================================================================
  // Initialization
  // =========================================================================

  /// Initialize all chat subsystems. Call this from the screen's initState.
  Future<void> initialize() async {
    // Load settings and cached messages
    await settingsProvider.loadPersistedSettings(
      currentUserId: _authService.currentUser?.id,
      onSettingsLoaded: (bgUrl, bgOpacity, bgBrightness, _, __, ___, ____) {
        setState(
          (s) => s.copyWith(
            backgroundUrl: bgUrl,
            bgOpacity: bgOpacity,
            bgBrightness: bgBrightness,
          ),
        );
        if (bgUrl != null) {
          encryptionProvider.extractColorsFromBackground(bgUrl, (
            bubbleSent,
            bubbleReceived,
            textSent,
            textReceived,
          ) {
            setState(
              (s) => s.copyWith(
                bubbleColorSent: bubbleSent,
                bubbleColorReceived: bubbleReceived,
                textColorSent: textSent,
                textColorReceived: textReceived,
              ),
            );
          });
        }
      },
    );

    await settingsProvider.loadCachedMessages(
      sessionStart: _sessionStartTime,
      onMessagesLoaded: (cached) {
        setState((s) => s.copyWith(messages: cached));
        scrollToBottom();
      },
    );

    // Initialize encryption
    await _initializeEncryption();

    // Fetch conversation details
    await fetchConversationDetails();

    // Load messages
    await loadMessages();

    // Subscribe to realtime
    subscribeToMessages();
    subscribeToReadReceipts();
    subscribeToReactions();
    subscribeToBackgroundChanges();

    // Mark as read after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      markAsRead();
    });
  }

  // =========================================================================
  // Encryption
  // =========================================================================

  Future<void> _initializeEncryption() async {
    // Always call init() to check/restore keys - don't return early if not initialized
    // This ensures _encryptionReady is properly set based on actual key status

    if (!SignalService().isInitialized) {
      final success = await SignalService().init();
      if (!success) {
        debugPrint('Failed to initialize SignalService');
      }
    }

    final status = await _encryptionService.init();

    if (status == EncryptionStatus.ready) {
      setState((s) => s.copyWith(encryptionReady: true));
      // Re-decrypt messages
      await loadMessages(silent: true);
    } else if (status == EncryptionStatus.needsSecurityUpgrade) {
      // For security upgrade, we can still decrypt messages with v1 keys
      setState((s) => s.copyWith(encryptionReady: true));
      await loadMessages(silent: true);
      // But we still need to prompt for upgrade
      onEncryptionNeeded?.call(status);
    } else {
      // Notify the screen that PIN-based setup/restore/upgrade is needed
      onEncryptionNeeded?.call(status);
    }
  }

  Future<Message> _decryptSingleMessage(Message message) async {
    return encryptionProvider.decryptSingleMessage(
      message,
      _authService.currentUser?.id,
    );
  }

  // =========================================================================
  // Messages
  // =========================================================================

  /// Load messages from the server and decrypt them.
  Future<void> loadMessages({bool silent = false}) async {
    if (!silent && state.messages.isEmpty) {
      setState((s) => s.copyWith(isLoading: true));
    }

    try {
      final messages = await _messagingService.getMessages(
        conversationId: conversationId,
        sessionStart: _sessionStartTime,
      );

      // Decrypt messages (yield to event loop to prevent UI freeze)
      final decryptedMessages = <Message>[];
      for (final message in messages) {
        await Future.delayed(Duration.zero);
        final decrypted = await _decryptSingleMessage(message);
        decryptedMessages.add(decrypted);
      }

      // Filter expired ephemeral messages
      final now = DateTime.now();
      final filtered =
          decryptedMessages.where((m) {
            if (!m.isEphemeral) return true;
            if (m.ephemeralDuration == 0 && m.readAt != null) return false;
            if (m.expiresAt != null && now.isAfter(m.expiresAt!)) return false;
            return true;
          }).toList();

      setState((s) => s.copyWith(messages: filtered, isLoading: false));
      scrollToBottom();
      loadSmartReplies();
      await settingsProvider.saveMessagesToCache(filtered);
    } catch (e) {
      debugPrint('Error loading messages: $e');
      setState((s) => s.copyWith(isLoading: false));
      onError?.call('Error loading messages: $e');
    }
  }

  /// Subscribe to new messages and deletions via Supabase Realtime.
  void subscribeToMessages() {
    _messageChannel = _messagingService.subscribeToMessages(
      conversationId: conversationId,
      onNewMessage: (message) async {
        final decryptedMessage = await _decryptSingleMessage(message);

        // Apply client-side filtering for whisper mode
        final now = DateTime.now();
        final isExpired =
            decryptedMessage.isEphemeral &&
            ((decryptedMessage.ephemeralDuration == 0 &&
                    decryptedMessage.readAt != null) ||
                (decryptedMessage.expiresAt != null &&
                    now.isAfter(decryptedMessage.expiresAt!)));
        if (isExpired) return;

        SchedulerBinding.instance.addPostFrameCallback((_) {
          // Avoid duplicates (especially from optimistic updates)
          final index = state.messages.indexWhere(
            (m) => m.id == decryptedMessage.id,
          );

          List<Message> updatedMessages;
          if (index == -1) {
            updatedMessages = [...state.messages, decryptedMessage];
          } else {
            updatedMessages = List<Message>.from(state.messages);
            updatedMessages[index] = decryptedMessage;
          }

          setState((s) => s.copyWith(messages: updatedMessages));
          scrollToBottom();
          loadSmartReplies();
          settingsProvider.saveMessagesToCache(updatedMessages);

          // Mark as read if message is from other user
          final currentUserId = _authService.currentUser?.id;
          if (decryptedMessage.senderId != currentUserId) {
            markAsRead();
          }
        });
      },
      onDeleteMessage: (messageId) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          setState(
            (s) => s.copyWith(
              messages: s.messages.where((m) => m.id != messageId).toList(),
            ),
          );
          settingsProvider.saveMessagesToCache(state.messages);
        });
      },
    );
  }

  /// Subscribe to read receipt updates via Supabase Realtime.
  void subscribeToReadReceipts() {
    _readReceiptChannel = _messagingService.subscribeToReadReceipts(
      conversationId: conversationId,
      onUpdate: (messageId, userId, readAt) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          final index = state.messages.indexWhere((m) => m.id == messageId);
          if (index < 0) return;

          final msg = state.messages[index];
          final senderId = msg.senderId;
          final isMe = _authService.currentUser?.id == senderId;

          // Only consider it "read" for vanish logic if the person reading is NOT the sender
          if (userId != senderId) {
            DateTime? currentAnyReadAt = msg.anyReadAt;
            if (currentAnyReadAt == null || readAt.isBefore(currentAnyReadAt)) {
              currentAnyReadAt = readAt;
            }

            final updatedMsg = msg.copyWith(
              anyReadAt: currentAnyReadAt,
              isRead: isMe ? true : msg.isRead,
            );

            // Instant vanish: if Whisper Mode and receiver read it, remove immediately
            if (updatedMsg.isEphemeral && updatedMsg.ephemeralDuration == 0) {
              setState(
                (s) => s.copyWith(
                  messages: List<Message>.from(s.messages)..removeAt(index),
                ),
              );
              return;
            }

            final updatedMessages = List<Message>.from(state.messages);
            updatedMessages[index] = updatedMsg;
            setState((s) => s.copyWith(messages: updatedMessages));
          }
        });
      },
    );
  }

  /// Subscribe to reaction updates.
  void subscribeToReactions() {
    _reactionsChannel = _messagingService.subscribeToReactions(
      conversationId: conversationId,
      onUpdate: (messageId, reactions) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          final index = state.messages.indexWhere((m) => m.id == messageId);
          if (index < 0) return;

          final updatedMessages = List<Message>.from(state.messages);
          updatedMessages[index] = updatedMessages[index].copyWith(
            reactions: reactions,
          );
          setState((s) => s.copyWith(messages: updatedMessages));
        });
      },
    );
  }

  /// Subscribe to background image changes.
  void subscribeToBackgroundChanges() {
    _backgroundChannel = _messagingService.subscribeToBackgroundChanges(
      conversationId: conversationId,
      onUpdate: (backgroundUrl) {
        if (backgroundUrl != state.backgroundUrl) {
          setState((s) => s.copyWith(backgroundUrl: backgroundUrl));
          if (backgroundUrl != null) {
            encryptionProvider.extractColorsFromBackground(backgroundUrl, (
              bubbleSent,
              bubbleReceived,
              textSent,
              textReceived,
            ) {
              setState(
                (s) => s.copyWith(
                  bubbleColorSent: bubbleSent,
                  bubbleColorReceived: bubbleReceived,
                  textColorSent: textSent,
                  textColorReceived: textReceived,
                ),
              );
            });
          } else {
            setState(
              (s) => s.copyWith(
                bubbleColorSent: null,
                bubbleColorReceived: null,
                textColorSent: null,
                textColorReceived: null,
              ),
            );
          }
        }
      },
    );
  }

  /// Mark unread messages as read.
  Future<void> markAsRead() async {
    final currentUserId = _authService.currentUser?.id;
    if (currentUserId == null) return;

    final unreadMessageIds =
        state.messages
            .where((m) => m.senderId != currentUserId && !m.isRead)
            .map((m) => m.id)
            .toList();

    if (unreadMessageIds.isEmpty) return;

    // Optimistically update
    final updatedMessages =
        state.messages.map((m) {
          if (unreadMessageIds.contains(m.id)) {
            return m.copyWith(isRead: true, readAt: DateTime.now());
          }
          return m;
        }).toList();

    setState((s) => s.copyWith(messages: updatedMessages));

    try {
      await _messagingService.markMessagesAsRead(
        conversationId,
        unreadMessageIds,
        currentUserId,
      );
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  // =========================================================================
  // Sending Messages
  // =========================================================================

  /// Send a text or media message.
  Future<void> sendMessage({
    required String content,
    XFile? imageFile,
    File? videoFile,
    File? audioFile,
    PlatformFile? docFile,
    Message? replyMessage,
    String mediaViewMode = 'unlimited',
  }) async {
    if (content.isEmpty &&
        imageFile == null &&
        videoFile == null &&
        audioFile == null &&
        docFile == null) {
      return;
    }

    if (_encryptionService.isInitialized && !state.encryptionReady) {
      onError?.call('Encryption not ready. Please set up encryption first.');
      return;
    }

    final userId = _authService.currentUser?.id;
    if (userId == null) return;

    // Optimistic UI for text-only messages
    Message? optimisticMessage;
    if (content.isNotEmpty &&
        imageFile == null &&
        videoFile == null &&
        audioFile == null &&
        docFile == null) {
      optimisticMessage = Message(
        id: 'optimistic_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: conversationId,
        senderId: userId,
        senderName: _authService.currentUser?.username ?? 'Me',
        senderAvatar: _authService.currentUser?.photoUrl ?? '',
        content: content,
        timestamp: DateTime.now(),
        isRead: false,
        messageType: MessageType.text,
        isEphemeral: state.whisperMode > 0,
        ephemeralDuration: state.ephemeralDuration,
        replyToId: replyMessage?.id,
        replyToContent: replyMessage?.content,
        replyToSenderName: replyMessage?.senderName,
      );

      setState(
        (s) => s.copyWith(
          messages: [...s.messages, optimisticMessage!],
          isSending: false,
          replyMessage: null,
        ),
      );
      scrollToBottom();
    } else {
      setState(
        (s) => s.copyWith(
          isSending: true,
          selectedImage: null,
          selectedVideo: null,
          selectedAudio: null,
          selectedFile: null,
          replyMessage: null,
        ),
      );
    }

    try {
      String? finalContent;
      Map<String, String>? encryptedKeys;
      String? iv;
      int? signalMessageType;
      String? signalSenderContent;
      bool usedSignal = false;

      if (_encryptionService.isInitialized) {
        final recipientId = otherUserId ?? state.otherUserId;
        if (recipientId == null || recipientId.isEmpty) {
          throw Exception('Recipient ID is required for encryption');
        }

        // Try Signal encryption first
        if (SignalService().isInitialized) {
          try {
            final cipherMessage = await SignalService().encryptMessage(
              recipientId,
              content.isNotEmpty ? content : '',
            );
            finalContent = base64Encode(cipherMessage.serialize());
            signalMessageType = cipherMessage.getType();
            usedSignal = true;
          } catch (e) {
            debugPrint('Signal encryption failed: $e, falling back to RSA');
          }
        }

        // Fallback to RSA
        if (!usedSignal) {
          String? recipientPublicKey = _publicKeyCache[recipientId];

          if (recipientPublicKey == null) {
            final recipientProfile =
                await Supabase.instance.client
                    .from('profiles')
                    .select('public_key')
                    .eq('id', recipientId)
                    .single();

            recipientPublicKey = recipientProfile['public_key'] as String?;
            if (recipientPublicKey != null) {
              _publicKeyCache[recipientId] = recipientPublicKey;
            }
          }

          if (recipientPublicKey == null) {
            throw Exception(
              'Recipient has not updated the app to support encrypted messaging yet',
            );
          }

          final encrypted = await _encryptionService.encryptMessage(
            content.isNotEmpty ? content : '',
            [recipientPublicKey],
          );
          finalContent = encrypted.encryptedContent;
          encryptedKeys = encrypted.encryptedKeys;
          iv = encrypted.iv;
        }
      } else {
        finalContent = content;
      }

      // Upload media if present
      String? mediaUrl;
      MessageType messageType = MessageType.text;
      String? fileName;
      int? fileSize;
      String? mimeType;

      if (imageFile != null) {
        fileName = imageFile.name;
        mediaUrl = await _messagingService.uploadChatMedia(
          imageFile.path,
          folder: 'images',
        );
        messageType = MessageType.image;
      } else if (videoFile != null) {
        fileName = videoFile.path.split(Platform.pathSeparator).last;
        mediaUrl = await _messagingService.uploadChatMedia(
          videoFile.path,
          folder: 'videos',
        );
        messageType = MessageType.document;
      } else if (docFile != null) {
        if (docFile.path != null) {
          fileName = docFile.name;
          mediaUrl = await _messagingService.uploadChatMedia(
            docFile.path!,
            folder: 'files',
          );
          messageType = MessageType.document;
          fileSize = docFile.size;
          mimeType = docFile.extension;
        }
      } else if (audioFile != null) {
        fileName = audioFile.path.split(Platform.pathSeparator).last;
        mediaUrl = await _messagingService.uploadChatMedia(
          audioFile.path,
          folder: 'audio',
        );
        messageType = MessageType.voice;
      }

      // Generate dual-layer fallback (RSA encrypted copy for both sender and recipient)
      if (_encryptionService.isInitialized && content.isNotEmpty) {
        try {
          final recipientId = otherUserId ?? state.otherUserId;
          final List<String> publicKeys = [];

          final cachedRecipientPk = _publicKeyCache[recipientId];
          final cachedSenderPk = _publicKeyCache[userId];

          if (cachedRecipientPk != null) publicKeys.add(cachedRecipientPk);
          if (cachedSenderPk != null) publicKeys.add(cachedSenderPk);

          if (publicKeys.length < 2) {
            final idsToFetch = <String>[];
            if (cachedRecipientPk == null) idsToFetch.add(recipientId!);
            if (cachedSenderPk == null) idsToFetch.add(userId);

            if (idsToFetch.isNotEmpty) {
              final profilesResponse = await Supabase.instance.client
                  .from('profiles')
                  .select('id, public_key')
                  .inFilter('id', idsToFetch);

              for (var profile in profilesResponse) {
                final pk = profile['public_key'] as String?;
                final id = profile['id'] as String;
                if (pk != null) {
                  _publicKeyCache[id] = pk;
                  if (!publicKeys.contains(pk)) publicKeys.add(pk);
                }
              }
            }
          }

          if (publicKeys.isNotEmpty) {
            final fallbackEncryption = await _encryptionService.encryptMessage(
              content.isNotEmpty ? content : '',
              publicKeys,
            );
            signalSenderContent = fallbackEncryption.encryptedContent;

            if (usedSignal) {
              encryptedKeys = fallbackEncryption.encryptedKeys;
              iv = fallbackEncryption.iv;
            }
          }
        } catch (e) {
          debugPrint('Failed to generate dual-layer fallback: $e');
        }
      }

      // Send message
      final sentMessage = await _messagingService.sendMessage(
        conversationId: conversationId,
        senderId: userId,
        content: finalContent ?? '',
        messageType: messageType,
        mediaUrl: mediaUrl,
        mediaFileName: fileName,
        mediaFileSize: fileSize,
        mediaMimeType: mimeType,
        encryptedKeys: encryptedKeys,
        iv: iv,
        signalMessageType: signalMessageType,
        signalSenderContent: signalSenderContent,
        whisperMode: state.whisperMode,
        replyToId: replyMessage?.id,
        mediaViewMode: mediaViewMode,
      );

      // Replace optimistic message with the real one
      if (optimisticMessage != null) {
        final decrypted = await _decryptSingleMessage(sentMessage);
        setState(
          (s) => s.copyWith(
            messages: [
              ...s.messages.where((m) => m.id != optimisticMessage!.id),
              decrypted,
            ],
            isSending: false,
          ),
        );
      } else {
        setState((s) => s.copyWith(isSending: false));
      }

      await settingsProvider.saveMessagesToCache(state.messages);
    } catch (e) {
      debugPrint('Error sending message: $e');
      // Remove optimistic message on failure
      if (optimisticMessage != null) {
        setState(
          (s) => s.copyWith(
            messages:
                s.messages.where((m) => m.id != optimisticMessage!.id).toList(),
            isSending: false,
          ),
        );
      } else {
        setState((s) => s.copyWith(isSending: false));
      }
      onError?.call('Failed to send message: $e');
    }
  }

  /// Delete a sent message (unsend).
  Future<void> unsendMessage(Message message) async {
    // Optimistically remove
    setState(
      (s) => s.copyWith(
        messages: s.messages.where((m) => m.id != message.id).toList(),
      ),
    );

    try {
      await _messagingService.deleteMessage(message.id);
    } catch (e) {
      debugPrint('Error unsending message: $e');
      onError?.call('Failed to unsend message');
      // Reload on failure
      onReloadRequested?.call();
    }
  }

  /// Update reactions on a specific message (optimistic UI update).
  void updateMessageReactions(
    String messageId,
    List<MessageReactionModel> reactions,
  ) {
    setState(
      (s) => s.copyWith(
        messages:
            s.messages.map((m) {
              if (m.id == messageId) {
                return m.copyWith(reactions: reactions);
              }
              return m;
            }).toList(),
      ),
    );
  }

  // =========================================================================
  // Conversation Details
  // =========================================================================

  /// Fetch conversation details (other user info, whisper mode).
  Future<void> fetchConversationDetails() async {
    try {
      final details = await _messagingService.getConversationDetails(
        conversationId,
      );
      setState(
        (s) => s.copyWith(
          otherUserName: details.otherUserName,
          otherUserId: details.otherUserId,
          otherUserAvatar: details.otherUserAvatar,
          whisperMode: 0, // Forced to 0 to disable Whisper Mode
          ephemeralDuration: details.whisperMode == 1 ? 0 : 86400,
        ),
      );
    } catch (e) {
      debugPrint('Error fetching conversation details: $e');
    }
  }

  // =========================================================================
  // Smart Replies
  // =========================================================================

  /// Load smart reply suggestions for the last received message.
  void loadSmartReplies() {
    final messages = state.messages;
    if (messages.isEmpty) {
      setState((s) => s.copyWith(smartReplies: [], showingSmartReplies: false));
      return;
    }

    // Find last message from other user
    final currentUserId = _authService.currentUser?.id;
    Message? lastOtherMessage;
    for (int i = messages.length - 1; i >= 0; i--) {
      if (messages[i].senderId != currentUserId &&
          messages[i].messageType == MessageType.text) {
        lastOtherMessage = messages[i];
        break;
      }
    }

    if (lastOtherMessage == null ||
        lastOtherMessage.content == 'Sent attachment' ||
        lastOtherMessage.content.contains('🔒')) {
      setState((s) => s.copyWith(smartReplies: [], showingSmartReplies: false));
      return;
    }

    // Get suggestions (SmartReplyService is static)
    final suggestions = SmartReplyService.getSuggestions(
      lastOtherMessage.content,
    );
    setState(
      (s) => s.copyWith(
        smartReplies: suggestions,
        showingSmartReplies: suggestions.isNotEmpty,
      ),
    );
  }

  // =========================================================================
  // Scroll
  // =========================================================================

  /// Scroll the message list to the bottom (latest messages).
  void scrollToBottom() {
    if (scrollController != null && scrollController!.hasClients) {
      scrollController!.animateTo(
        0.0, // reverse list: 0 is bottom
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // =========================================================================
  // Lifecycle
  // =========================================================================

  /// Called when the app comes back to foreground.
  Future<void> onAppResumed() async {
    final now = DateTime.now();
    if (_lastResumeTime != null &&
        now.difference(_lastResumeTime!).inSeconds < 5) {
      return; // rapid switching, skip reload
    }
    _lastResumeTime = now;

    // Reload messages silently, reconnect realtime
    await loadMessages(silent: true);
    _reconnectRealtime();
    await fetchConversationDetails();
  }

  void _reconnectRealtime() {
    if (_messageChannel != null) {
      _messagingService.unsubscribeFromMessages(_messageChannel!);
    }
    subscribeToMessages();

    if (_readReceiptChannel != null) {
      SupabaseService().client.removeChannel(_readReceiptChannel!);
    }
    subscribeToReadReceipts();

    if (_reactionsChannel != null) {
      SupabaseService().client.removeChannel(_reactionsChannel!);
    }
    subscribeToReactions();
  }

  /// Insert a system message (e.g., "Encryption enabled").
  void insertSystemMessage(String content) {
    setState(
      (s) => s.copyWith(
        messages: [
          ...s.messages,
          Message(
            id: 'system_${DateTime.now().millisecondsSinceEpoch}',
            conversationId: conversationId,
            senderId: 'system',
            senderName: 'System',
            senderAvatar: '',
            content: content,
            timestamp: DateTime.now(),
            messageType: MessageType.system,
            isRead: true,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Clean up Realtime subscriptions
    if (_messageChannel != null) {
      _messagingService.unsubscribeFromMessages(_messageChannel!);
    }
    if (_backgroundChannel != null) {
      SupabaseService().client.removeChannel(_backgroundChannel!);
    }
    if (_readReceiptChannel != null) {
      SupabaseService().client.removeChannel(_readReceiptChannel!);
    }
    if (_conversationChannel != null) {
      SupabaseService().client.removeChannel(_conversationChannel!);
    }
    if (_reactionsChannel != null) {
      SupabaseService().client.removeChannel(_reactionsChannel!);
    }
    _callsSubscription?.cancel();
    _publicKeyCache.clear();

    scrollController?.dispose();
    encryptionProvider.dispose();
    settingsProvider.dispose();
    super.dispose();
  }
}
