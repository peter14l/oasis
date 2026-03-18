import 'dart:io';
import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:oasis_v2/providers/conversation_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:file_picker/file_picker.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

import 'dart:convert';
import 'package:oasis_v2/models/message.dart';
import 'package:oasis_v2/services/messaging_service.dart';
import 'package:oasis_v2/services/auth_service.dart';
import 'package:oasis_v2/services/media_download_service.dart';
import 'package:oasis_v2/services/encryption_service.dart';
import 'package:oasis_v2/services/signal/signal_service.dart';
import 'package:oasis_v2/screens/messages/image_preview_screen.dart';
import 'package:oasis_v2/screens/messages/chat_details_screen.dart';
import 'package:oasis_v2/screens/messages/encryption_setup_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oasis_v2/services/supabase_service.dart';
import 'package:oasis_v2/widgets/skeleton_container.dart';
import 'package:oasis_v2/widgets/messages/voice_message_player.dart';
import 'package:oasis_v2/services/vault_service.dart';
import 'package:oasis_v2/models/message_reaction.dart';
import 'package:oasis_v2/models/chat_theme.dart';
import 'package:oasis_v2/utils/haptic_utils.dart';
import 'package:oasis_v2/services/smart_reply_service.dart';
import 'package:oasis_v2/widgets/messages/message_reactions.dart';
import 'package:oasis_v2/widgets/messages/chat_theme_selector.dart';
import 'package:oasis_v2/widgets/messages/invite_bubble.dart';
import 'package:oasis_v2/widgets/gestures/gesture_widgets.dart';
import 'package:any_link_preview/any_link_preview.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:oasis_v2/services/call_service.dart';
import 'package:oasis_v2/screens/messages/incoming_call_overlay.dart';
import 'package:oasis_v2/models/call.dart';
import 'package:go_router/go_router.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String? otherUserName;
  final String? otherUserAvatar;
  final String? otherUserId;

  const ChatScreen({
    super.key,
    required this.conversationId,
    this.otherUserName,
    this.otherUserAvatar,
    this.otherUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final MessagingService _messagingService = MessagingService();
  final AuthService _authService = AuthService();
  final MediaDownloadService _mediaDownloadService = MediaDownloadService();
  final EncryptionService _encryptionService = EncryptionService();
  late final CallService _callService;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final FocusNode _focusNode = FocusNode();
  late VaultService _vaultService;

  // Track when the user opened this chat screen to manage "vanish on reopen" logic
  final DateTime _sessionStartTime = DateTime.now();

  List<Message> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  // SmartReplyService is static now
  List<String> _smartReplies = [];
  bool _showingSmartReplies = false;

  // Theme state
  ChatTheme? _activeTheme;

  bool _isWhisperMode = false;
  int _recordDuration = 0;
  Timer? _recordTimer;
  // Duplicate variable removed

  RealtimeChannel? _messageChannel;
  RealtimeChannel? _backgroundChannel;
  RealtimeChannel? _readReceiptChannel;
  StreamSubscription<List<Map<String, dynamic>>>? _callsSubscription;
  XFile? _selectedImage;
  File? _selectedVideo;
  PlatformFile? _selectedFile;
  String? _backgroundUrl;
  Color? _bubbleColorSent;
  Color? _bubbleColorReceived;
  Color? _textColorSent;
  Color? _textColorReceived;
  bool _encryptionReady = false;
  int _ephemeralDuration = 86400; // Default 24h

  // Whisper Mode pull-up gesture state
  double _whisperDragProgress = 0.0; // 0.0 → 1.0
  double _whisperDragOffset = 0.0; // pixels the input has been lifted
  bool _whisperTriggered = false; // one-shot: prevent re-triggering mid-drag
  static const double _whisperDragThreshold = 80.0; // px to pull to trigger

  @override
  void initState() {
    super.initState();
    _callService = context.read<CallService>();
    _loadPersistedSettings();
    _loadCachedMessages(); // Load cache immediately
    _initializeEncryption();
    _loadMessages();
    _subscribeToMessages();
    _subscribeToReadReceipts();
    _subscribeToBackgroundChanges();
    // Delay marking as read slightly so user can actually SEE the messages 
    // before they vanish (if they are ephemeral)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _markAsRead();
    });
    _subscribeToCalls();
    if (widget.otherUserId == null) {
      _fetchConversationDetails();
    }
  }

  /// Load messages from SharedPreferences cache
  Future<void> _loadCachedMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String cacheKey = 'chat_messages_${widget.conversationId}';
      final String? cachedData = prefs.getString(cacheKey);
      
      if (cachedData != null && _messages.isEmpty) {
        final List<dynamic> decoded = jsonDecode(cachedData);
        final List<Message> cachedMessages = decoded.map((json) => Message.fromJson(json)).toList();
        
        // Filter out expired ephemeral messages from cache
        final filtered = MessagingService.filterExpiredMessages(
          cachedMessages,
          sessionStart: _sessionStartTime,
        );
        
        if (mounted && filtered.isNotEmpty) {
          setState(() {
            _messages = filtered;
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint('Error loading cached messages: $e');
    }
  }

  /// Save current messages to SharedPreferences cache
  Future<void> _saveMessagesToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String cacheKey = 'chat_messages_${widget.conversationId}';
      
      // Don't cache ephemeral messages that have already been read 
      // or are about to vanish to avoid logic issues on reload
      final toCache = _messages.where((m) => !m.isEphemeral || m.readAt == null).take(50).toList();
      
      if (toCache.isNotEmpty) {
        final String encoded = jsonEncode(toCache.map((m) => m.toJson()).toList());
        await prefs.setString(cacheKey, encoded);
      }
    } catch (e) {
      debugPrint('Error saving messages to cache: $e');
    }
  }

  void _subscribeToBackgroundChanges() {
    _backgroundChannel = _messagingService.subscribeToBackgroundChanges(
      conversationId: widget.conversationId,
      onUpdate: (backgroundUrl) {
        if (mounted && backgroundUrl != _backgroundUrl) {
          setState(() {
            _backgroundUrl = backgroundUrl;
          });
          if (backgroundUrl != null) {
            _extractColorsFromBackground();
          } else {
            setState(() {
              _bubbleColorSent = null;
              _bubbleColorReceived = null;
              _textColorSent = null;
              _textColorReceived = null;
            });
          }
        }
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _vaultService = Provider.of<VaultService>(context, listen: false);
  }

  String? _otherUserName;
  String? _otherUserId;

  @override
  void dispose() {
    _recordTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _audioRecorder.dispose();

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
    _callsSubscription?.cancel();

    // Lock chat if interval is set to On Chat Close
    if (_vaultService.getLockInterval(widget.conversationId) == 'chat_close') {
      _vaultService.lockItem(widget.conversationId);
    }

    super.dispose();
  }

  Future<void> _fetchConversationDetails() async {
    try {
      final details = await _messagingService.getConversationDetails(
        widget.conversationId,
      );
      if (mounted) {
        setState(() {
          _otherUserName = details.otherUserName;
          _otherUserId = details.otherUserId;
        });
      }
    } catch (e) {
      debugPrint('Error fetching conversation details: $e');
    }
  }

  void _subscribeToCalls() {
    _callsSubscription = SupabaseService().client
        .from('calls')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', widget.conversationId)
        .listen((data) {
          if (data.isEmpty) return;
          final call = Call.fromJson(data.first);
          if (call.status == CallStatus.pinging &&
              call.hostId != _authService.currentUser?.id) {
            _showIncomingCallOverlay(call);
          }
        });
  }

  void _showIncomingCallOverlay(Call call) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: IncomingCallOverlay(call: call)),
    );
  }

  /// Load persisted chat settings (background, whisper mode) from SharedPreferences and Supabase
  Future<void> _loadPersistedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final bgKey = 'chat_bg_${widget.conversationId}';
    final whisperKey = 'chat_whisper_${widget.conversationId}';
    final durationKey = 'chat_duration_${widget.conversationId}';

    String? bgUrl = prefs.getString(bgKey);

    try {
      final userId = _authService.currentUser?.id;
      if (userId != null) {
        final data =
            await Supabase.instance.client
                .from('chat_themes')
                .select('background_image_url')
                .eq('conversation_id', widget.conversationId)
                .order('updated_at', ascending: false)
                .limit(1)
                .maybeSingle();

        if (data != null) {
          bgUrl = data['background_image_url'] as String?;
          // Update local cache
          if (bgUrl != null) {
            await prefs.setString(bgKey, bgUrl);
          } else {
            await prefs.remove(bgKey);
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading chat theme from Supabase: $e');
    }

    setState(() {
      _backgroundUrl = bgUrl;
      _isWhisperMode = prefs.getBool(whisperKey) ?? false;
      _ephemeralDuration = prefs.getInt(durationKey) ?? 86400;
    });

    if (_backgroundUrl != null) {
      _extractColorsFromBackground();
    } else {
      setState(() {
        _bubbleColorSent = null;
        _bubbleColorReceived = null;
        _textColorSent = null;
        _textColorReceived = null;
      });
    }
  }

  /// Save chat settings to SharedPreferences
  Future<void> _savePersistedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final bgKey = 'chat_bg_${widget.conversationId}';
    final whisperKey = 'chat_whisper_${widget.conversationId}';

    if (_backgroundUrl != null) {
      await prefs.setString(bgKey, _backgroundUrl!);
    } else {
      await prefs.remove(bgKey);
    }
    await prefs.setBool(whisperKey, _isWhisperMode);
  }

  Future<void> _initializeEncryption() async {
    if (!EncryptionService.isEnabled) return;

    if (!SignalService().isInitialized) {
      final success = await SignalService().init();
      if (!success) {
        debugPrint('Failed to initialize SignalService');
      }
    }

    final status = await _encryptionService.init();

    if (status == EncryptionStatus.needsSetup) {
      if (mounted) {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (context) => const EncryptionSetupScreen(isRestore: false),
          ),
        );
        final ready = result == true;
        setState(() => _encryptionReady = ready);
        // Re-decrypt any messages that were placeholders before keys were set up
        if (ready) _loadMessages();
      }
    } else if (status == EncryptionStatus.needsRestore) {
      if (mounted) {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (context) => const EncryptionSetupScreen(isRestore: true),
          ),
        );
        final ready = result == true;
        setState(() => _encryptionReady = ready);
        // Re-decrypt messages now that we have the restored keys
        if (ready) _loadMessages();
      }
    } else if (status == EncryptionStatus.ready) {
      setState(() => _encryptionReady = true);
    }
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);

    try {
      final messages = await _messagingService.getMessages(
        conversationId: widget.conversationId,
        sessionStart: _sessionStartTime,
      );

      // Decrypt messages
      final decryptedMessages = <Message>[];
      for (final message in messages) {
        // Yield to the event loop to prevent UI freezing during decryption
        await Future.delayed(Duration.zero);
        if (message.signalMessageType != null) {
          try {
            final isSender = message.senderId == _authService.currentUser?.id;
              
            if (isSender && message.signalSenderContent != null && message.encryptedKeys != null && message.iv != null) {
              // Sender copy is encrypted via RSA using `signalSenderContent` and the `encryptedKeys` payload
              final decrypted = await _encryptionService.decryptMessage(
                message.signalSenderContent!,
                message.encryptedKeys!,
                message.iv!,
              );
              decryptedMessages.add(message.copyWith(content: decrypted ?? '🔒 Message encrypted'));
            } else if (!isSender && message.signalMessageType != null) {
              // Recipient copy is encrypted via Signal using `content`
              String decrypted = await SignalService().decryptMessage(
                message.senderId,
                message.content,
                message.signalMessageType!,
              );
              
              // NEW: If Signal returns a failure placeholder, try RSA fallback immediately
              if (decrypted.contains('🔒 Message encrypted') && 
                  message.signalSenderContent != null && 
                  message.encryptedKeys != null && 
                  message.iv != null) {
                final rsaDecrypted = await _encryptionService.decryptMessage(
                  message.signalSenderContent!,
                  message.encryptedKeys!,
                  message.iv!,
                );
                if (rsaDecrypted != null) {
                   decrypted = rsaDecrypted;
                   debugPrint('[ChatScreen] Recovered message via RSA fallback.');
                }
              }
              decryptedMessages.add(message.copyWith(content: decrypted));
            } else {
               decryptedMessages.add(message.copyWith(content: '🔒 Message encrypted'));
            }
          } catch (e) {
            debugPrint('Decryption failed: $e');
            decryptedMessages.add(
              message.copyWith(content: '🔒 Message encrypted'),
            );
          }
        } else if (message.encryptedKeys != null && message.iv != null) {
          final decrypted = await _encryptionService.decryptMessage(
            message.content,
            message.encryptedKeys!,
            message.iv!,
          );

          if (decrypted != null) {
            decryptedMessages.add(message.copyWith(content: decrypted));
          } else {
            // Decryption failed - show placeholder
            decryptedMessages.add(
              message.copyWith(content: '🔒 Message encrypted'),
            );
          }
        } else {
          // Unencrypted message
          decryptedMessages.add(message);
        }
      }
      setState(() {
        _messages = decryptedMessages;
        _isLoading = false;
      });
      _scrollToBottom();
      _loadSmartReplies();
      _saveMessagesToCache();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  void _subscribeToMessages() {
    _messageChannel = _messagingService.subscribeToMessages(
      conversationId: widget.conversationId,
      onNewMessage: (message) async {
        if (mounted) {
          // Decrypt if encrypted
          Message finalMessage = message;
          if (message.signalMessageType != null) {
            try {
              final isSender = message.senderId == _authService.currentUser?.id;
              
              if (isSender && message.signalSenderContent != null && message.encryptedKeys != null && message.iv != null) {
                // Sender copy is encrypted via RSA using `signalSenderContent` and the `encryptedKeys` payload
                final decrypted = await _encryptionService.decryptMessage(
                  message.signalSenderContent!,
                  message.encryptedKeys!,
                  message.iv!,
                );
                finalMessage = message.copyWith(content: decrypted ?? '🔒 Message encrypted');
              } else if (!isSender && message.signalMessageType != null) {
                // Recipient copy is encrypted via Signal using `content`
                String decrypted = await SignalService().decryptMessage(
                  message.senderId,
                  message.content,
                  message.signalMessageType!,
                );

                // NEW: If Signal returns a failure placeholder, try RSA fallback immediately
                if (decrypted.contains('🔒 Message encrypted') && 
                    message.signalSenderContent != null && 
                    message.encryptedKeys != null && 
                    message.iv != null) {
                  final rsaDecrypted = await _encryptionService.decryptMessage(
                    message.signalSenderContent!,
                    message.encryptedKeys!,
                    message.iv!,
                  );
                  if (rsaDecrypted != null) {
                     decrypted = rsaDecrypted;
                     debugPrint('[ChatScreen] Recovered real-time message via RSA fallback.');
                  }
                }
                finalMessage = message.copyWith(content: decrypted);
              } else {
                 finalMessage = message.copyWith(content: '🔒 Message encrypted');
              }
            } catch (e) {
              debugPrint('Decryption failed: $e');
              finalMessage = message.copyWith(content: '🔒 Message encrypted');
            }
          } else if (message.encryptedKeys != null && message.iv != null) {
            final decrypted = await _encryptionService.decryptMessage(
              message.content,
              message.encryptedKeys!,
              message.iv!,
            );
            if (decrypted != null) {
              finalMessage = message.copyWith(content: decrypted);
            } else {
              finalMessage = message.copyWith(content: '🔒 Message encrypted');
            }
          }

          // Update state
          setState(() {
            _messages.add(finalMessage);
          });
          _scrollToBottom();
          _loadSmartReplies();
          _saveMessagesToCache();

          // Mark as read if message is from other user
          final currentUserId = _authService.currentUser?.id;
          if (finalMessage.senderId != currentUserId) {
            _markAsRead();
          }
        }
      },
    );
  }

  void _subscribeToReadReceipts() {
    _readReceiptChannel = _messagingService.subscribeToReadReceipts(
      conversationId: widget.conversationId,
      onUpdate: (messageId, userId, readAt) {
        if (mounted && userId == widget.otherUserId) {
          setState(() {
            final index = _messages.indexWhere((m) => m.id == messageId);
            if (index >= 0) {
              _messages[index] = _messages[index].copyWith(
                isRead: true,
                readAt: readAt,
              );
            }
          });
        }
      },
    );
  }

  Future<void> _markAsRead() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;
    await _messagingService.markConversationAsRead(
      widget.conversationId,
      userId,
    );

    // Also update local state for messages sent by the other user
    setState(() {
      for (int i = 0; i < _messages.length; i++) {
        if (_messages[i].senderId != userId && !_messages[i].isRead) {
          _messages[i] = _messages[i].copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
        }
      }
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (image != null) {
        setState(() => _selectedImage = image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result != null) {
        setState(() => _selectedFile = result.files.first);
      }
    } catch (e) {
      _showError('Error picking file: $e');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
      );
      if (video != null) {
        setState(() => _selectedVideo = File(video.path));
      }
    } catch (e) {
      _showError('Error picking video: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _showAttachmentOptions() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: colorScheme.onSurface.withValues(alpha: 0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 32,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Title row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                      child: Row(
                        children: [
                          Text(
                            'Share content',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded, size: 20),
                            style: IconButton.styleFrom(
                              backgroundColor: colorScheme.onSurface.withValues(alpha: 0.05),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Grid of options
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _AttachmentOption(
                            icon: Icons.image_rounded,
                            label: 'Photo',
                            iconColor: const Color(0xFF3D8BFF),
                            bgColor: const Color(0xFF3D8BFF).withValues(alpha: 0.1),
                            onTap: () {
                              Navigator.pop(context);
                              _pickImage();
                            },
                          ),
                          _AttachmentOption(
                            icon: Icons.videocam_rounded,
                            label: 'Video',
                            iconColor: const Color(0xFFFF6B6B),
                            bgColor: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                            onTap: () {
                              Navigator.pop(context);
                              _pickVideo();
                            },
                          ),
                          _AttachmentOption(
                            icon: Icons.insert_drive_file_rounded,
                            label: 'File',
                            iconColor: const Color(0xFF51CF66),
                            bgColor: const Color(0xFF51CF66).withValues(alpha: 0.1),
                            onTap: () {
                              Navigator.pop(context);
                              _pickFile();
                            },
                          ),
                          _AttachmentOption(
                            icon: Icons.mic_rounded,
                            label: 'Audio',
                            iconColor: const Color(0xFFFFD43B),
                            bgColor: const Color(0xFFFFD43B).withValues(alpha: 0.1),
                            onTap: () {
                              Navigator.pop(context);
                              _startRecording();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty &&
        _selectedImage == null &&
        _selectedVideo == null &&
        _selectedFile == null) {
      return;
    }

    if (EncryptionService.isEnabled && !_encryptionReady) {
      _showError('Encryption not ready. Please set up encryption first.');
      return;
    }

    final userId = _authService.currentUser?.id;
    if (userId == null) return;

    final content = _messageController.text.trim();
    final imageFile = _selectedImage;
    final videoFile = _selectedVideo;
    final docFile = _selectedFile;

    _messageController.clear();
    setState(() {
      _isSending = true;
      _selectedImage = null;
      _selectedVideo = null;
      _selectedFile = null;
    });

    try {
      String? finalContent;
      Map<String, String>? encryptedKeys;
      String? iv;
      int? signalMessageType;
      String? signalSenderContent; // RSA encrypted copy for sender
      bool usedSignal = false;

      if (EncryptionService.isEnabled) {
        // Validate otherUserId is not empty (group chats not yet supported for encryption)
        final recipientId = widget.otherUserId ?? _otherUserId;
        if (recipientId == null || recipientId.isEmpty) {
          throw Exception('Recipient ID is required for encryption');
        }

        if (SignalService().isInitialized) {
          try {
            final cipherMessage = await SignalService().encryptMessage(
              recipientId,
              content.isNotEmpty ? content : 'Sent attachment',
            );
            finalContent = base64Encode(cipherMessage.serialize());
            signalMessageType = cipherMessage.getType();
            usedSignal = true;
          } catch (e) {
            debugPrint('Signal encryption failed: $e, falling back to RSA');
          }
        }

        if (!usedSignal) {
          // Get recipient's public key
          final recipientProfile =
              await Supabase.instance.client
                  .from('profiles')
                  .select('public_key')
                  .eq('id', recipientId)
                  .single();

          final recipientPublicKey = recipientProfile['public_key'] as String?;
          if (recipientPublicKey == null) {
            throw Exception(
              'Recipient has not updated the app to support encrypted messaging yet',
            );
          }

          // Encrypt message content
          final encrypted = await _encryptionService.encryptMessage(
            content.isNotEmpty ? content : 'Sent attachment',
            [recipientPublicKey],
          );
          finalContent = encrypted.encryptedContent;
          encryptedKeys = encrypted.encryptedKeys;
          iv = encrypted.iv;
        }
      } else {
        finalContent = content;
      }

      String? mediaUrl;
      MessageType messageType = MessageType.text;
      String? fileName;
      int? fileSize;
      String? mimeType;

      if (imageFile != null) {
        mediaUrl = await _messagingService.uploadChatMedia(
          imageFile.path,
          folder: 'images',
        );
        messageType = MessageType.image;
      } else if (videoFile != null) {
        mediaUrl = await _messagingService.uploadChatMedia(
          videoFile.path,
          folder: 'videos',
        );
        messageType = MessageType.document;
        fileName = 'Video';
      } else if (docFile != null) {
        if (docFile.path != null) {
          mediaUrl = await _messagingService.uploadChatMedia(
            docFile.path!,
            folder: 'files',
          );
          messageType = MessageType.document;
          fileName = docFile.name;
          fileSize = docFile.size;
          mimeType = docFile.extension;
        }
      }

      // Always generate a fallback RSA encrypted copy for BOTH sender and recipient
      if (EncryptionService.isEnabled && content.isNotEmpty) {
        try {
          final recipientId = widget.otherUserId ?? _otherUserId;
          
          // Get both public keys
          final profilesResponse = await Supabase.instance.client
              .from('profiles')
              .select('id, public_key')
              .inFilter('id', [userId, recipientId]);

          final List<String> publicKeys = [];
          for (var profile in profilesResponse) {
            final pk = profile['public_key'] as String?;
            if (pk != null) publicKeys.add(pk);
          }

          if (publicKeys.isNotEmpty) {
            final fallbackEncryption = await _encryptionService.encryptMessage(
              content.isNotEmpty ? content : 'Sent attachment',
              publicKeys,
            );
            signalSenderContent = fallbackEncryption.encryptedContent;
            
            // If using Signal, we store the RSA-encrypted keys in the existing fields
            // so both users can use them as a fallback.
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
      await _messagingService.sendMessage(
        conversationId: widget.conversationId,
        senderId: userId,
        content: finalContent ?? 'Sent attachment',
        messageType: messageType,
        mediaUrl: mediaUrl,
        mediaFileName: fileName,
        mediaFileSize: fileSize,
        mediaMimeType: mimeType,
        encryptedKeys: encryptedKeys,
        iv: iv,
        signalMessageType: signalMessageType,
        signalSenderContent: signalSenderContent,
        isWhisperMode: _isWhisperMode,
        ephemeralDuration: _ephemeralDuration,
      );

      // Refresh DM list preview in provider
      if (mounted) {
        context.read<ConversationProvider>().refreshConversation(
          widget.conversationId,
        );
      }
      _saveMessagesToCache();
    } catch (e) {
      _showError('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _openChatDetails() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => ChatDetailsScreen(
              conversationId: widget.conversationId,
              otherUserName:
                  widget.otherUserName ?? _otherUserName ?? 'Unknown',
              otherUserAvatar: widget.otherUserAvatar ?? '',
              otherUserId: widget.otherUserId ?? _otherUserId ?? '',
              isWhisperMode: _isWhisperMode,
              currentBackground: _backgroundUrl,
            ),
      ),
    );

    // After returning from chat details screen, reload settings from Supabase/Prefs
    if (mounted) {
      await _loadPersistedSettings();
      setState(() {
        _encryptionReady = _encryptionService.isInitialized;
      });
      // Refresh messages if encryption became ready (to decrypt past ones)
      if (_encryptionReady) {
        _loadMessages();
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        final filePath =
            '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(const RecordConfig(), path: filePath);

        setState(() {
          _recordDuration = 0;
        });

        _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() {
              _recordDuration++;
            });
          }
        });
      }
    } catch (e) {
      _showError('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      _recordTimer?.cancel();
      final recordPath = await _audioRecorder.stop();

      if (recordPath != null && mounted) {
        setState(() {
          _recordDuration = 0;
        });

        // Send the audio message
        await _sendAudioMessage(recordPath);
      }
    } catch (e) {
      _showError('Error stopping recording: $e');
    }
  }

  Future<void> _sendAudioMessage(String audioPath) async {
    if (!mounted) return;

    setState(() {
      _isSending = true;
    });

    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) return;

      await _messagingService.sendMessage(
        conversationId: widget.conversationId,
        senderId: userId,
        content: 'Audio message',
        messageType: MessageType.voice,
        mediaUrl: audioPath,
        mediaFileName: 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a',
        voiceDuration: _recordDuration,
      );

      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        _showError('Error sending audio message: $e');
      }
    }
  }

  Future<void> _extractColorsFromBackground() async {
    if (_backgroundUrl == null) return;

    try {
      // Yield to avoid blocking screen transition
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      final imageProvider = CachedNetworkImageProvider(_backgroundUrl!);
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        imageProvider,
        maximumColorCount: 20,
      );

      setState(() {
        final sentColor = paletteGenerator.dominantColor?.color ?? Colors.blue;
        final receivedColor =
            paletteGenerator.lightVibrantColor?.color ?? Colors.grey;

        _bubbleColorSent = sentColor.withValues(alpha: 0.9);
        _bubbleColorReceived = receivedColor.withValues(alpha: 0.85);

        // Calculate contrasting text colors
        _textColorSent =
            sentColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
        _textColorReceived =
            receivedColor.computeLuminance() > 0.5
                ? Colors.black
                : Colors.white;
      });
    } catch (e) {
      debugPrint('Error extracting colors: $e');
    }
  }

  void _loadSmartReplies() {
    if (_messages.isEmpty) return;

    // Validating input: using the last received message
    final lastMessage = _messages.last;
    if (lastMessage.senderId == _authService.currentUser?.id) return;
    if (lastMessage.messageType != MessageType.text) return;

    // Use setState only if the widget is still mounted
    if (!mounted) return;

    try {
      final replies = SmartReplyService.getSuggestions(lastMessage.content);
      if (mounted) {
        setState(() {
          _smartReplies = replies;
          _showingSmartReplies = replies.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint('Error generating smart replies: $e');
    }
  }

  List<GroupedReaction> _groupReactions(List<MessageReactionModel> reactions) {
    final groups = <String, GroupedReaction>{};
    final currentUserId = _authService.currentUser?.id;

    for (final reaction in reactions) {
      if (groups.containsKey(reaction.reaction)) {
        final group = groups[reaction.reaction]!;
        groups[reaction.reaction] = GroupedReaction(
          emoji: group.emoji,
          count: group.count + 1,
          usernames: [...group.usernames, reaction.username],
          hasCurrentUserReacted:
              group.hasCurrentUserReacted || reaction.userId == currentUserId,
        );
      } else {
        groups[reaction.reaction] = GroupedReaction(
          emoji: reaction.reaction,
          count: 1,
          usernames: [reaction.username],
          hasCurrentUserReacted: reaction.userId == currentUserId,
        );
      }
    }
    return groups.values.toList();
  }

  Future<void> _onReactionSelected(Message message, String reaction) async {
    // Optimistic update
    final currentReactions = List<MessageReactionModel>.from(message.reactions);
    final user = _authService.currentUser;
    if (user == null) return;

    final userId = user.id;
    final username = user.username;

    final existingIndex = currentReactions.indexWhere(
      (r) => r.userId == userId && r.reaction == reaction,
    );

    // Also check if user has ANY reaction to replace it (if it's a different emoji)
    final anyReactionIndex = currentReactions.indexWhere(
      (r) => r.userId == userId,
    );

    if (existingIndex >= 0) {
      // Remove same reaction (toggle off)
      currentReactions.removeAt(existingIndex);
    } else {
      // If user has a different reaction, remove it first (standard behavior)
      if (anyReactionIndex >= 0) {
        currentReactions.removeAt(anyReactionIndex);
      }

      // Add new reaction
      currentReactions.add(
        MessageReactionModel(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          messageId: message.id,
          userId: userId,
          username: username,
          reaction: reaction,
          createdAt: DateTime.now(),
        ),
      );
    }

    setState(() {
      final index = _messages.indexWhere((m) => m.id == message.id);
      if (index >= 0) {
        _messages[index] = _messages[index].copyWith(
          reactions: currentReactions,
        );
      }
    });

    try {
      if (existingIndex >= 0) {
        // Toggle off: remove reaction from DB
        await Supabase.instance.client
            .from('message_reactions')
            .delete()
            .eq('message_id', message.id)
            .eq('user_id', userId)
            .eq('emoji', reaction);
      } else {
        // Upsert new reaction
        await Supabase.instance.client.from('message_reactions').upsert({
          'message_id': message.id,
          'user_id': userId,
          'emoji': reaction,
        });
      }
    } catch (e) {
      debugPrint('Error updating reaction: $e');
      _showError('Failed to update reaction');
      // Revert optimistic update here if needed
    }
  }

  void _handleThemeChange(ChatTheme theme) {
    setState(() => _activeTheme = theme);
    // Persist theme to DB or SharedPrefs
    _savePersistedSettings();
  }

  void _toggleWhisperMode() {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    setState(() => _isWhisperMode = !_isWhisperMode);
    _messagingService.toggleWhisperMode(widget.conversationId, _isWhisperMode);
    // Persist the whisper mode setting
    _savePersistedSettings();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isWhisperMode
              ? '✨ Whisper Mode enabled. Messages will vanish after being seen.'
              : 'Whisper Mode disabled.',
        ),
        backgroundColor: _isWhisperMode ? colorScheme.secondary : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userId = _authService.currentUser?.id;
    final isDesktop = MediaQuery.of(context).size.width >= 1200;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color:
                  _backgroundUrl != null
                      ? (_bubbleColorSent?.withValues(alpha: 0.15) ??
                          colorScheme.primary.withValues(alpha: 0.15))
                      : colorScheme.surface.withValues(alpha: 0.5),
            ),
          ),
        ),
        automaticallyImplyLeading: !isDesktop,
        title: InkWell(
          onTap: _openChatDetails,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage:
                    (widget.otherUserAvatar ?? '').isNotEmpty
                        ? CachedNetworkImageProvider(widget.otherUserAvatar!)
                        : null,
                child:
                    (widget.otherUserAvatar ?? '').isEmpty
                        ? Text(
                          (widget.otherUserName ?? _otherUserName ?? 'U')
                                  .isNotEmpty
                              ? (widget.otherUserName ??
                                      _otherUserName ??
                                      'U')[0]
                                  .toUpperCase()
                              : '',
                        )
                        : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.otherUserName ?? _otherUserName ?? 'Unknown',
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_encryptionReady || _encryptionService.isInitialized)
                      Row(
                        children: [
                          Icon(
                            Icons.lock,
                            size: 10,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Encrypted',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.call_outlined),
          //   onPressed: () => _initiateCall(CallType.voice),
          //   tooltip: 'Voice Call',
          // ),
          // IconButton(
          //   icon: const Icon(Icons.videocam_outlined),
          //   onPressed: () => _initiateCall(CallType.video),
          //   tooltip: 'Video Call',
          // ),
          if (isDesktop) ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Search coming soon')),
                );
              },
              tooltip: 'Search',
            ),
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: _openChatDetails,
              tooltip: 'Chat Details',
            ),
          ] else
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'details') {
                  _openChatDetails();
                } else if (value == 'theme') {
                  showModalBottomSheet(
                    context: context,
                    builder:
                        (context) => ChatThemeSelector(
                          selectedPreset: ChatThemePreset.values.firstWhere(
                            (p) =>
                                p.name.toLowerCase() ==
                                _activeTheme?.themeName.toLowerCase(),
                            orElse: () => ChatThemePreset.defaultTheme,
                          ),
                          onPresetSelected: (preset) {
                            _handleThemeChange(
                              ChatTheme.fromPreset(
                                preset,
                                'theme_${DateTime.now().millisecondsSinceEpoch}',
                                widget.conversationId,
                                _authService.currentUser?.id ?? '',
                              ),
                            );
                            Navigator.pop(context);
                          },
                        ),
                  );
                }
              },
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'details',
                      child: Row(
                        children: [
                          Icon(Icons.info_outline),
                          SizedBox(width: 12),
                          Text('Details'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'theme',
                      child: Row(
                        children: [
                          Icon(Icons.palette_outlined),
                          SizedBox(width: 12),
                          Text('Chat Theme'),
                        ],
                      ),
                    ),
                  ],
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Background Image
          if (_backgroundUrl != null)
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: _backgroundUrl!,
                fit: BoxFit.cover,
                color: Colors.black.withValues(alpha: 0.3),
                colorBlendMode: BlendMode.darken,
              ),
            ),

          // Main Content
          Column(
            children: [
              // Whisper Mode Indicator
              if (_isWhisperMode)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    top:
                        MediaQuery.of(context).padding.top + kToolbarHeight + 8,
                    bottom: 8,
                    left: 16,
                    right: 16,
                  ),
                  color: colorScheme.secondary.withValues(alpha: 0.2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.auto_delete,
                        size: 16,
                        color: colorScheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                       child: Text(
                         'Whisper Mode • Messages vanish ${_ephemeralDuration == 0 ? "instantly" : "24hrs"} after being seen',
                         style: theme.textTheme.bodySmall?.copyWith(
                           color: colorScheme.secondary,
                           fontWeight: FontWeight.w500,
                         ),
                         overflow: TextOverflow.ellipsis,
                       ),
                      ),                    ],
                  ),
                ),

              // Messages List
              Expanded(
                child:
                    _isLoading
                        ? ListView.builder(
                          reverse: true,
                          padding: EdgeInsets.only(
                            top:
                                _isWhisperMode
                                    ? 16
                                    : MediaQuery.of(context).padding.top +
                                        kToolbarHeight +
                                        16,
                            bottom: 16,
                            left: 16,
                            right: 16,
                          ),
                          itemCount: 8,
                          itemBuilder: (context, index) {
                            final isMe = index % 2 == 0;
                            return Align(
                              alignment:
                                  isMe
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: SkeletonContainer.rounded(
                                  width: 150 + (index % 3) * 50.0,
                                  height: 40 + (index % 2) * 20.0,
                                  borderRadius: BorderRadius.circular(
                                    16,
                                  ).copyWith(
                                    bottomRight:
                                        isMe ? const Radius.circular(4) : null,
                                    bottomLeft:
                                        !isMe ? const Radius.circular(4) : null,
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                        : _messages.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: colorScheme.onSurfaceVariant.withOpacity(
                                  0.6,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No messages yet',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start the conversation!',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          reverse: true,
                          controller: _scrollController,
                          padding: EdgeInsets.only(
                            top:
                                _isWhisperMode
                                    ? 16
                                    : MediaQuery.of(context).padding.top +
                                        kToolbarHeight +
                                        16,
                            bottom: 16,
                            left: 16,
                            right: 16,
                          ),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message =
                                _messages[_messages.length - 1 - index];
                            final isMe = message.senderId == userId;
                            return _buildMessageBubble(message, isMe);
                          },
                        ),
              ),

              // Previews (Image/File)
              if (_selectedImage != null) _buildImagePreview(),
              if (_selectedFile != null) _buildFilePreview(),
              if (_selectedVideo != null)
                _buildFilePreview(name: 'Video selected'),

              // Smart Replies
              if (_showingSmartReplies)
                SmartReplyBar(
                  suggestions: _smartReplies,
                  onSuggestionTap: (reply) {
                    _messageController.text = reply;
                    _sendMessage();
                    setState(() {
                      _showingSmartReplies = false;
                      _smartReplies = [];
                    });
                  },
                ),

              // Message Input
              Container(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  top: 8,
                ),
                decoration: const BoxDecoration(color: Colors.transparent),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Whisper Mode pull-up trigger ──
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onVerticalDragStart: (_) {
                          setState(() {
                            _whisperDragProgress = 0.0;
                            _whisperDragOffset = 0.0;
                            _whisperTriggered = false;
                          });
                        },
                        onVerticalDragUpdate: (details) {
                          final rawDelta = -details.delta.dy;
                          if (rawDelta <= 0 && _whisperDragOffset == 0) return;
                          setState(() {
                            _whisperDragOffset = (_whisperDragOffset + rawDelta)
                                .clamp(0.0, _whisperDragThreshold);
                            _whisperDragProgress =
                                _whisperDragOffset / _whisperDragThreshold;
                          });
                          if (_whisperDragProgress >= 1.0 &&
                              !_whisperTriggered) {
                            _whisperTriggered = true;
                            HapticUtils.heavyImpact();
                            _toggleWhisperMode();
                          }
                        },
                        onVerticalDragEnd: (_) {
                          setState(() {
                            _whisperDragProgress = 0.0;
                            _whisperDragOffset = 0.0;
                            _whisperTriggered = false;
                          });
                        },
                        onVerticalDragCancel: () {
                          setState(() {
                            _whisperDragProgress = 0.0;
                            _whisperDragOffset = 0.0;
                            _whisperTriggered = false;
                          });
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ── Circular progress ring (visible while dragging) ──
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 80),
                              height: _whisperDragProgress > 0 ? 52 : 0,
                              child:
                                  _whisperDragProgress > 0
                                      ? Center(
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: colorScheme.secondary
                                                    .withOpacity(0.08),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 40,
                                              height: 40,
                                              child: CircularProgressIndicator(
                                                value: _whisperDragProgress,
                                                strokeWidth: 3,
                                                backgroundColor: colorScheme
                                                    .secondary
                                                    .withValues(alpha: 0.15),
                                                valueColor: AlwaysStoppedAnimation<
                                                  Color
                                                >(
                                                  _whisperDragProgress >= 1.0
                                                      ? colorScheme.secondary
                                                      : colorScheme.secondary
                                                          .withOpacity(
                                                            0.4 +
                                                                _whisperDragProgress *
                                                                    0.6,
                                                          ),
                                                ),
                                              ),
                                            ),
                                            Icon(
                                              _whisperDragProgress >= 1.0
                                                  ? Icons.auto_delete
                                                  : Icons.arrow_upward_rounded,
                                              size: 18,
                                              color: colorScheme.secondary
                                                  .withOpacity(
                                                    0.5 +
                                                        _whisperDragProgress *
                                                            0.5,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      )
                                      : const SizedBox.shrink(),
                            ),
                            // ── Message input row (lifts slightly while dragging) ──
                            Transform.translate(
                              offset: Offset(0, -_whisperDragOffset * 0.3),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(32),
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                          sigmaX: 10,
                                          sigmaY: 10,
                                        ),
                                        child: const SizedBox.shrink(),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            _backgroundUrl != null
                                                ? (_bubbleColorSent?.withValues(
                                                      alpha: 0.15,
                                                    ) ??
                                                    colorScheme.primary
                                                        .withValues(
                                                          alpha: 0.15,
                                                        ))
                                                : colorScheme.surface
                                                    .withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(32),
                                        border: Border.all(
                                          color: Colors.black.withValues(
                                            alpha: 0.2,
                                          ),
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          IconButton(
                                            onPressed: _showAttachmentOptions,
                                            icon: Icon(
                                              Icons.add_circle_outline,
                                              color: colorScheme.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: CallbackShortcuts(
                                              bindings: {
                                                const SingleActivator(
                                                  LogicalKeyboardKey.enter,
                                                  includeRepeats: false,
                                                ): () {
                                                  final keys =
                                                      ServicesBinding
                                                          .instance
                                                          .keyboard
                                                          .logicalKeysPressed;
                                                  if (keys.contains(
                                                        LogicalKeyboardKey
                                                            .shiftLeft,
                                                      ) ||
                                                      keys.contains(
                                                        LogicalKeyboardKey
                                                            .shiftRight,
                                                      )) {
                                                    return;
                                                  }
                                                  if (_messageController.text
                                                      .trim()
                                                      .isNotEmpty) {
                                                    _sendMessage();
                                                  }
                                                },
                                              },
                                              child: TextField(
                                                controller: _messageController,
                                                onChanged: (val) {
                                                  setState(() {});
                                                },
                                                style: TextStyle(
                                                  color:
                                                      _backgroundUrl != null
                                                          ? (_textColorSent ??
                                                              Colors.white)
                                                          : colorScheme
                                                              .onSurface,
                                                ),
                                                decoration: InputDecoration(
                                                  hintText: 'Type a message...',
                                                  hintStyle: TextStyle(
                                                    color: (_backgroundUrl !=
                                                                null
                                                            ? (_textColorSent ??
                                                                Colors.white)
                                                            : colorScheme
                                                                .onSurface)
                                                        .withValues(alpha: 0.5),
                                                  ),
                                                  border: InputBorder.none,
                                                  enabledBorder:
                                                      InputBorder.none,
                                                  focusedBorder:
                                                      InputBorder.none,
                                                  errorBorder: InputBorder.none,
                                                  focusedErrorBorder:
                                                      InputBorder.none,
                                                  filled: false,
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 10,
                                                      ),
                                                ),
                                                minLines: 1,
                                                maxLines: 4,
                                                textCapitalization:
                                                    TextCapitalization
                                                        .sentences,
                                                onSubmitted: (_) {
                                                  if (_messageController.text
                                                      .trim()
                                                      .isNotEmpty) {
                                                    _sendMessage();
                                                  }
                                                },
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          GestureDetector(
                                            onLongPressStart: (details) {
                                              if (_messageController.text
                                                      .trim()
                                                      .isEmpty &&
                                                  !_isSending) {
                                                _startRecording();
                                              }
                                            },
                                            onLongPressEnd: (details) {
                                              if (_recordTimer != null) {
                                                _stopRecording();
                                              }
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color:
                                                    _isSending
                                                        ? colorScheme.onSurface
                                                            .withValues(
                                                              alpha: 0.12,
                                                            )
                                                        : colorScheme.primary,
                                                shape: BoxShape.circle,
                                              ),
                                              child: IconButton(
                                                onPressed:
                                                    _isSending
                                                        ? null
                                                        : () {
                                                          if (_messageController
                                                              .text
                                                              .trim()
                                                              .isNotEmpty) {
                                                            _sendMessage();
                                                          }
                                                        },
                                                icon:
                                                    _isSending
                                                        ? const SizedBox(
                                                          width: 20,
                                                          height: 20,
                                                          child:
                                                              CircularProgressIndicator(
                                                                strokeWidth: 2,
                                                                color:
                                                                    Colors
                                                                        .white,
                                                              ),
                                                        )
                                                        : Icon(
                                                          _messageController
                                                                  .text
                                                                  .trim()
                                                                  .isEmpty
                                                              ? Icons.mic
                                                              : Icons
                                                                  .send_rounded,
                                                          color: Colors.white,
                                                        ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ), // Row
                                    ), // Container
                                  ],
                                ), // Stack
                              ), // ClipRRect
                            ), // Transform.translate
                          ],
                        ), // Column (GestureDetector child)
                      ), // GestureDetector
                      // Dynamic hint — hidden while actively dragging
                      if (_whisperDragProgress == 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _isWhisperMode
                                ? '👻  Whisper on — pull up to disable'
                                : 'Pull up to enable Whisper Mode',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  _isWhisperMode
                                      ? colorScheme.secondary.withValues(
                                        alpha: 0.8,
                                      )
                                      : colorScheme.onSurfaceVariant
                                          .withOpacity(0.5),
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(8),
      color: colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(_selectedImage!.path),
              height: 80,
              width: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          const Text('Image selected'),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => setState(() => _selectedImage = null),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePreview({String? name}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.insert_drive_file, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name ?? 'File',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _selectedFile = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userId = _authService.currentUser?.id;

    // final bubbleColor = isMe
    //     ? (colorScheme.primary.withValues(alpha:  ))
    //     : (colorScheme.surfaceVariant);

    // final textColor = isMe
    //     ? colorScheme.onPrimary
    //     : colorScheme.onSurfaceVariant;

    // final bubbleColor = isMe
    //     ? (colorScheme.primary.withValues(alpha:  ))
    //     : (colorScheme.surfaceVariant);

    // final textColor = isMe
    //     ? colorScheme.onPrimary
    //     : colorScheme.onSurfaceVariant;

    Widget content;

    if (message.messageType == MessageType.image && message.mediaUrl != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (context) => ImagePreviewScreen(
                        imageUrl: message.mediaUrl!,
                        caption:
                            message.content != 'Sent attachment'
                                ? message.content
                                : null,
                      ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 300,
                  maxWidth: 300,
                ),
                child: CachedNetworkImage(
                  imageUrl: message.mediaUrl!,
                  placeholder:
                      (context, url) => const SizedBox(
                        height: 150,
                        width: 150,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          if (message.content.isNotEmpty &&
              message.content != 'Sent attachment' &&
              message.content != '🔒 Message encrypted')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                message.content.trim(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color:
                      isMe
                          ? (_textColorSent ?? colorScheme.onPrimaryContainer)
                          : (_textColorReceived ?? colorScheme.onSurface),
                ),
              ),
            ),
        ],
      );
    } else if (message.messageType == MessageType.document) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.insert_drive_file,
            color:
                isMe
                    ? (_textColorSent ?? colorScheme.onPrimaryContainer)
                    : (_textColorReceived ?? colorScheme.onSurface),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message.mediaFileName ?? 'Document',
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    isMe
                        ? (_textColorSent ?? colorScheme.onPrimaryContainer)
                        : (_textColorReceived ?? colorScheme.onSurface),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              Icons.download,
              size: 20,
              color:
                  isMe
                      ? (_textColorSent ?? colorScheme.onPrimaryContainer)
                      : (_textColorReceived ?? colorScheme.onSurface),
            ),
            onPressed: () async {
              if (message.mediaUrl != null) {
                try {
                  await _mediaDownloadService.downloadDocument(
                    message.mediaUrl!,
                    message.mediaFileName ?? 'document',
                    context,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Document downloaded'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Download failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
          ),
        ],
      );
    } else if (message.messageType == MessageType.voice) {
      content = VoiceMessagePlayer(
        audioUrl: message.mediaUrl ?? '',
        duration: message.voiceDuration,
        isMe: isMe,
        color:
            isMe
                ? (_textColorSent ?? colorScheme.onPrimaryContainer)
                : (_textColorReceived ?? colorScheme.onSurface),
      );
    } else if (message.messageType == MessageType.text &&
        message.content.startsWith('[INVITE:')) {
      content = InviteBubble(payload: message.content.trim(), isSender: isMe);
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message.content.trim(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color:
                  isMe
                      ? (_textColorSent ?? colorScheme.onPrimaryContainer)
                      : (_textColorReceived ?? colorScheme.onSurface),
              fontStyle:
                  message.content == '🔒 Message encrypted'
                      ? FontStyle.italic
                      : null,
            ),
          ),
          if (message.content != '🔒 Message encrypted' &&
              _containsUrl(message.content))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: AnyLinkPreview(
                link: _extractUrl(message.content),
                displayDirection: UIDirection.uiDirectionVertical,
                showMultimedia: true,
                bodyMaxLines: 3,
                bodyTextOverflow: TextOverflow.ellipsis,
                titleStyle: theme.textTheme.titleSmall?.copyWith(
                  color:
                      isMe
                          ? (_textColorSent ?? colorScheme.onPrimaryContainer)
                          : (_textColorReceived ?? colorScheme.onSurface),
                  fontWeight: FontWeight.bold,
                ),
                bodyStyle: theme.textTheme.bodySmall?.copyWith(
                  color:
                      isMe
                          ? (_textColorSent ?? colorScheme.onPrimaryContainer)
                              .withOpacity(0.8)
                          : (_textColorReceived ??
                              colorScheme.onSurfaceVariant),
                  fontSize: 12,
                ),
                backgroundColor:
                    isMe
                        ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                        : colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: 12,
                removeElevation: true,
                onTap: () async {
                  final url = _extractUrl(message.content);
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(Uri.parse(url));
                  }
                },
              ),
            ),
        ],
      );
    }

    // Use adaptive colors if background is set
    // Colors are handled in the Container decoration below

    final isDesktop = MediaQuery.of(context).size.width >= 1200;
    return SwipeableMessage(
      onSwipeReply: () {
        HapticUtils.selectionClick();
        _messageController.text = '@${message.senderName} ';
        // FocusScope.of(context).requestFocus(_focusNode);
      },
      isOwnMessage:
          isMe, // Add this parameter if SwipeableMessage supports it (it defaults to false)
      child: GestureDetector(
        onLongPress: () {
          HapticUtils.selectionClick();
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder:
                (context) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.outline.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'React to message',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      MessageReactionPicker(
                        onReactionSelected: (reaction) {
                          _onReactionSelected(message, reaction.emoji);
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
          );
        },
        onDoubleTap: () {
          HapticUtils.lightImpact();
          _onReactionSelected(message, '❤️');
        },
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            constraints: BoxConstraints(
              maxWidth:
                  isDesktop ? 400.0 : MediaQuery.of(context).size.width * 0.75,
            ),
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        isMe
                            ? (_bubbleColorSent ?? colorScheme.primary)
                            : (_bubbleColorReceived ??
                                colorScheme.surfaceContainerHighest),
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomRight: isMe ? const Radius.circular(4) : null,
                      bottomLeft: !isMe ? const Radius.circular(4) : null,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      content,
                      if (isMe)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Align(
                            alignment: Alignment.bottomRight,
                            child: Icon(
                              Icons.done_all,
                              size: 14,
                              color:
                                  message.isRead ? Colors.blue : Colors.black,
                            ),
                          ),
                        ),
                      if (isMe &&
                          message.isRead &&
                          message.readAt != null &&
                          _messages.indexOf(message) ==
                              _messages.lastIndexWhere(
                                (m) =>
                                    m.senderId == userId &&
                                    m.isRead &&
                                    m.readAt != null,
                              ))
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              _formatSeenTime(message.readAt!),
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 9,
                                fontStyle: FontStyle.italic,
                                color: (_textColorSent ?? colorScheme.onPrimary)
                                    .withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Reactions Display
                if (message.reactions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: MessageReactionDisplay(
                      reactions: _groupReactions(message.reactions),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder:
                              (context) => MessageReactionsSheet(
                                reactions: _groupReactions(message.reactions),
                              ),
                        );
                      },
                      // Remove currentUserId if not supported by MessageReactionDisplay or use it if updated
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _containsUrl(String text) {
    final urlRegExp = RegExp(
      r"(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/[^\s]+)",
      caseSensitive: false,
    );
    return urlRegExp.hasMatch(text);
  }

  String _extractUrl(String text) {
    final urlRegExp = RegExp(
      r"(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/[^\s]+)",
      caseSensitive: false,
    );
    return urlRegExp.firstMatch(text)?.group(0) ?? '';
  }

  String _formatSeenTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Seen just now';
    } else if (difference.inHours < 1) {
      return 'Seen ${difference.inMinutes} mins ago';
    } else if (difference.inDays < 1) {
      return 'Seen ${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return 'Seen ${difference.inDays} days ago';
    } else {
      return 'Seen on ${time.month}/${time.day}/${time.year}';
    }
  }
}

/// A single tappable icon + label card used in the attachment bottom sheet.
class _AttachmentOption extends StatelessWidget {
  const _AttachmentOption({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.bgColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final Color bgColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
