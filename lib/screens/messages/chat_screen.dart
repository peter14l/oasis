import 'package:universal_io/io.dart';
import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:oasis_v2/providers/conversation_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
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
import 'package:screen_protector/screen_protector.dart';
import 'package:oasis_v2/widgets/messages/message_reactions.dart';
import 'package:oasis_v2/widgets/messages/chat_theme_selector.dart';
import 'package:oasis_v2/widgets/messages/invite_bubble.dart';
import 'package:oasis_v2/widgets/gestures/gesture_widgets.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:any_link_preview/any_link_preview.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:oasis_v2/services/call_service.dart';
import 'package:oasis_v2/screens/messages/incoming_call_overlay.dart';
import 'package:oasis_v2/models/call.dart';
import 'package:oasis_v2/widgets/messages/forward_message_modal.dart';
import 'package:go_router/go_router.dart';
import 'package:oasis_v2/widgets/dotted_border_painter.dart';
import 'package:oasis_v2/widgets/messages/typing_indicator_widget.dart';
import 'package:oasis_v2/providers/typing_indicator_provider.dart';
import 'package:oasis_v2/providers/presence_provider.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String? otherUserName;
  final String? otherUserAvatar;
  final String? otherUserId;
  final VoidCallback? onDetailsToggle;
  final bool isDetailsOpen;
  final double? bgOpacity;
  final double? bgBrightness;

  const ChatScreen({
    super.key,
    required this.conversationId,
    this.otherUserName,
    this.otherUserAvatar,
    this.otherUserId,
    this.onDetailsToggle,
    this.isDetailsOpen = false,
    this.bgOpacity,
    this.bgBrightness,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final MessagingService _messagingService = MessagingService();
  final AuthService _authService = AuthService();
  final MediaDownloadService _mediaDownloadService = MediaDownloadService();
  final EncryptionService _encryptionService = EncryptionService();
  late final CallService _callService;
  final TextEditingController _messageController = TextEditingController();
  final ValueNotifier<String> _textNotifier = ValueNotifier<String>('');
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _durationPlayer = AudioPlayer();
  final FocusNode _focusNode = FocusNode();
  late VaultService _vaultService;

  // Track when the user opened this chat screen to manage "vanish on reopen" logic
  final DateTime _sessionStartTime = DateTime.now();

  List<Message> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  bool _isRecording = false;
  Message? _replyMessage;
  // SmartReplyService is static now
  List<String> _smartReplies = [];
  bool _showingSmartReplies = false;

  // Theme state
  ChatTheme? _activeTheme;

  int _isWhisperMode = 0;
  int _lastActiveWhisperMode = 1; // Default to Instant
  int _recordDuration = 0;
  Timer? _recordTimer;

  RealtimeChannel? _messageChannel;
  RealtimeChannel? _backgroundChannel;
  RealtimeChannel? _readReceiptChannel;
  RealtimeChannel? _conversationChannel;
  StreamSubscription<List<Map<String, dynamic>>>? _callsSubscription;
  XFile? _selectedImage;
  File? _selectedVideo;
  File? _selectedAudio;
  PlatformFile? _selectedFile;
  String? _backgroundUrl;
  String _mediaViewMode = 'unlimited'; // 'unlimited', 'once', 'twice'
  Color? _bubbleColorSent;
  Color? _bubbleColorReceived;
  Color? _textColorSent;
  Color? _textColorReceived;
  bool _encryptionReady = false;
  int _ephemeralDuration = 86400; // Default 24h
  double _bgOpacity = 1.0;
  double _bgBrightness = 0.7;

  // Whisper Mode pull-up gesture state
  double _whisperDragProgress = 0.0; // 0.0 → 1.0
  double _whisperDragOffset = 0.0; // pixels the input has been lifted
  bool _whisperTriggered = false; // one-shot: prevent re-triggering mid-drag
  static const double _whisperDragThreshold = 80.0; // px to pull to trigger

  // Cache for public keys to avoid redundant network calls
  final Map<String, String> _publicKeyCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _callService = context.read<CallService>();
    
    _messageController.addListener(() {
      _textNotifier.value = _messageController.text;
      
      // Update typing status
      final userId = _authService.currentUser?.id;
      if (userId != null && _messageController.text.isNotEmpty) {
        context.read<TypingIndicatorProvider>().setTyping(
          widget.conversationId,
          userId,
          true,
        );
      }
    });

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
    _fetchConversationDetails();

    // Subscribe to presence
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final otherId = widget.otherUserId ?? _otherUserId;
      if (otherId != null) {
        context.read<PresenceProvider>().subscribeToUserPresence(otherId);
      }
    });

    // Subscribe to typing status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = _authService.currentUser?.id;
      if (userId != null) {
        context.read<TypingIndicatorProvider>().subscribeToTypingStatus(
          widget.conversationId,
          userId,
        );
      }
    });
  }

  DateTime? _lastResumeTime;

  @override
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.bgOpacity != oldWidget.bgOpacity || 
        widget.bgBrightness != oldWidget.bgBrightness) {
      _loadPersistedSettings(silent: true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final now = DateTime.now();
      // On desktop, rapid window switching shouldn't trigger full reloads
      if (_lastResumeTime != null && 
          now.difference(_lastResumeTime!).inSeconds < 5) {
        return;
      }
      _lastResumeTime = now;

      // Reload messages and re-subscribe when app comes back to foreground
      // Use silent load to avoid flickering skeleton loader
      _loadMessages(silent: true);
      _reconnectRealtime();
      _fetchConversationDetails();
    }
  }

  void _reconnectRealtime() {
    if (_messageChannel != null) {
      _messagingService.unsubscribeFromMessages(_messageChannel!);
    }
    _subscribeToMessages();
    
    if (_readReceiptChannel != null) {
      SupabaseService().client.removeChannel(_readReceiptChannel!);
    }
    _subscribeToReadReceipts();

    if (_conversationChannel != null) {
      SupabaseService().client.removeChannel(_conversationChannel!);
    }
    _subscribeToConversationUpdates();
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
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
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
          });
        }
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _vaultService = Provider.of<VaultService>(context, listen: false);
    _typingIndicatorProvider = Provider.of<TypingIndicatorProvider>(context, listen: false);
    _presenceProvider = Provider.of<PresenceProvider>(context, listen: false);
  }

  String? _otherUserName;
  String? _otherUserId;

  // Cached provider references for safe use in dispose()
  TypingIndicatorProvider? _typingIndicatorProvider;
  PresenceProvider? _presenceProvider;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recordTimer?.cancel();
    _messageController.dispose();
    _textNotifier.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _audioRecorder.dispose();
    _publicKeyCache.clear();

    // Clean up Instagram-style vanish mode messages when closing chat
    _messagingService.cleanupVanishModeMessages(widget.conversationId);

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
    _callsSubscription?.cancel();

    // Unsubscribe from typing status
    _typingIndicatorProvider?.unsubscribeFromTypingStatus(widget.conversationId);

    // Unsubscribe from presence
    final otherId = widget.otherUserId ?? _otherUserId;
    if (otherId != null) {
      _presenceProvider?.unsubscribeFromUserPresence(otherId);
    }

    // Lock chat if interval is set to On Chat Close
    if (_vaultService.getLockInterval(widget.conversationId) == 'chat_close') {
      _vaultService.lockItem(widget.conversationId);
    }

    // Ensure screen protection is disabled when leaving
    if (_isWhisperMode > 0) {
      _disableScreenProtection();
    }

    super.dispose();
  }

  void _enableScreenProtection() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await ScreenProtector.preventScreenshotOn();
      }
    } catch (e) {
      debugPrint('Error enabling screen protection: $e');
    }
  }

  void _disableScreenProtection() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await ScreenProtector.preventScreenshotOff();
      }
    } catch (e) {
      debugPrint('Error disabling screen protection: $e');
    }
  }

  void _insertSystemMessage(String content) {
    if (!mounted) return;
    setState(() {
      _messages.add(Message(
        id: 'system_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: widget.conversationId,
        senderId: 'system',
        senderName: 'System',
        senderAvatar: '',
        content: content,
        timestamp: DateTime.now(),
        messageType: MessageType.system,
        isRead: true,
      ));
    });
  }

  void _subscribeToConversationUpdates() {
    _conversationChannel = _messagingService.subscribeToConversation(
      conversationId: widget.conversationId,
      onUpdate: (int whisperMode) {
        if (mounted && whisperMode != _isWhisperMode) {
          final int oldMode = _isWhisperMode;
          setState(() {
            _isWhisperMode = whisperMode;
            _ephemeralDuration = whisperMode == 1 ? 0 : 86400;
          });

          // Manage screen protection on remote toggle
          if (whisperMode > 0 && oldMode == 0) {
            _enableScreenProtection();
          } else if (whisperMode == 0 && oldMode > 0) {
            _disableScreenProtection();
          }
          
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                whisperMode > 0
                    ? '✨ Whisper Mode enabled by other participant.'
                    : 'Whisper Mode disabled by other participant.',
              ),
              backgroundColor: whisperMode > 0 ? Theme.of(context).colorScheme.secondary : Colors.blue,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
    );
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
          _isWhisperMode = details.whisperMode;
          _ephemeralDuration = details.whisperMode == 1 ? 0 : 86400;
        });

        // Enable protection if we started in whisper mode
        if (_isWhisperMode > 0) {
          _enableScreenProtection();
        }
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

  /// Load persisted chat settings (background) from SharedPreferences and Supabase
  Future<void> _loadPersistedSettings({bool silent = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final bgKey = 'chat_bg_${widget.conversationId}';

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
      _bgOpacity = widget.bgOpacity ?? (prefs.getDouble('chat_bg_opacity_${widget.conversationId}') ?? 1.0);
      _bgBrightness = widget.bgBrightness ?? (prefs.getDouble('chat_bg_brightness_${widget.conversationId}') ?? 0.7);
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

    if (_backgroundUrl != null) {
      await prefs.setString(bgKey, _backgroundUrl!);
    } else {
      await prefs.remove(bgKey);
    }
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

  Future<Message> _decryptSingleMessage(Message message) async {
    final currentUserId = _authService.currentUser?.id;
    Message decryptedMessage = message;

    // 1. Decrypt main content
    if (message.signalMessageType != null) {
      try {
        final isSender = currentUserId != null &&
            message.senderId.toLowerCase() == currentUserId.toLowerCase();

        if (isSender &&
            message.signalSenderContent != null &&
            message.encryptedKeys != null &&
            message.iv != null) {
          final decrypted = await _encryptionService.decryptMessage(
            message.signalSenderContent!,
            message.encryptedKeys!,
            message.iv!,
          );
          decryptedMessage = decryptedMessage.copyWith(
            content: decrypted ?? '🔒 Message encrypted',
          );
        } else if (!isSender) {
          String decrypted = await SignalService().decryptMessage(
            message.senderId,
            message.content,
            message.signalMessageType!,
          );

          if ((decrypted.contains('🔒') ||
                  decrypted.contains('Optimizing secure connection')) &&
              message.signalSenderContent != null &&
              message.encryptedKeys != null &&
              message.iv != null) {
            final rsaDecrypted = await _encryptionService.decryptMessage(
              message.signalSenderContent!,
              message.encryptedKeys!,
              message.iv!,
            );
            if (rsaDecrypted != null) decrypted = rsaDecrypted;
          }
          decryptedMessage = decryptedMessage.copyWith(content: decrypted);
        }
      } catch (e) {
        debugPrint('Decryption failed: $e');
        decryptedMessage = decryptedMessage.copyWith(
          content: '🔒 Message encrypted',
        );
      }
    } else if (message.encryptedKeys != null && message.iv != null) {
      final decrypted = await _encryptionService.decryptMessage(
        message.content,
        message.encryptedKeys!,
        message.iv!,
      );
      decryptedMessage = decryptedMessage.copyWith(
        content: decrypted ?? '🔒 Message encrypted',
      );
    }

    // 2. Decrypt reply content if available
    if (decryptedMessage.replyToId != null &&
        decryptedMessage.replyToData != null) {
      final replyData = decryptedMessage.replyToData!;
      final replySenderId = replyData['sender_id'] as String?;
      final replyEncryptedKeys =
          replyData['encrypted_keys'] as Map<String, dynamic>?;
      final replyIv = replyData['iv'] as String?;
      final replySignalType = replyData['signal_message_type'] as int?;
      final replyContent = replyData['content'] as String?;
      final replySenderContent = replyData['signal_sender_content'] as String?;

      if (replySenderId != null && replyContent != null) {
        String? decryptedReply;
        try {
          if (replySignalType != null) {
            final isSender = currentUserId != null &&
                replySenderId.toLowerCase() == currentUserId.toLowerCase();

            if (isSender &&
                replySenderContent != null &&
                replyEncryptedKeys != null &&
                replyIv != null) {
              decryptedReply = await _encryptionService.decryptMessage(
                replySenderContent,
                Map<String, String>.from(replyEncryptedKeys),
                replyIv,
              );
            } else if (!isSender) {
              decryptedReply = await SignalService().decryptMessage(
                replySenderId,
                replyContent,
                replySignalType,
              );

              if (decryptedReply.contains('🔒') &&
                  replySenderContent != null &&
                  replyEncryptedKeys != null &&
                  replyIv != null) {
                decryptedReply = await _encryptionService.decryptMessage(
                  replySenderContent,
                  Map<String, String>.from(replyEncryptedKeys),
                  replyIv,
                );
              }
            }
          } else if (replyEncryptedKeys != null && replyIv != null) {
            decryptedReply = await _encryptionService.decryptMessage(
              replyContent,
              Map<String, String>.from(replyEncryptedKeys),
              replyIv,
            );
          }

          if (decryptedReply != null && !decryptedReply.contains('🔒')) {
            decryptedMessage = decryptedMessage.copyWith(
              replyToContent: decryptedReply,
            );
          } else {
            debugPrint('Reply decryption resulted in placeholder or null for msg ${message.id}');
          }
        } catch (e) {
          debugPrint('Failed to decrypt reply context for msg ${message.id}: $e');
        }
      } else {
        debugPrint('Missing sender_id or content in replyToData for msg ${message.id}');
      }
    }

    return decryptedMessage;
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (!silent && _messages.isEmpty) {
      setState(() => _isLoading = true);
    }

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
        final decrypted = await _decryptSingleMessage(message);
        decryptedMessages.add(decrypted);
      }
      
      if (mounted) {
        setState(() {
          _messages = MessagingService.filterExpiredMessages(
            decryptedMessages,
            sessionStart: _sessionStartTime,
          );
          _isLoading = false;
        });
        _scrollToBottom();
        _loadSmartReplies();
        _saveMessagesToCache();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
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
        if (!mounted) return;
        final decryptedMessage = await _decryptSingleMessage(message);

        // Apply client-side filtering for new messages
        final filtered = MessagingService.filterExpiredMessages(
          [decryptedMessage],
          sessionStart: _sessionStartTime,
        );
        if (filtered.isEmpty) {
          debugPrint('Whisper Mode: New message ${decryptedMessage.id} filtered out immediately');
          return;
        }

        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            // Avoid duplicates (especially from optimistic updates if implemented)
            final index = _messages.indexWhere((m) => m.id == decryptedMessage.id);
            if (index == -1) {
              _messages.add(decryptedMessage);
            } else {
              _messages[index] = decryptedMessage;
            }
          });
          _scrollToBottom();
          _loadSmartReplies();
          _saveMessagesToCache();

          // Mark as read if message is from other user
          final currentUserId = _authService.currentUser?.id;
          if (decryptedMessage.senderId != currentUserId) {
            _markAsRead();
          }
        });
      },
      onDeleteMessage: (messageId) {
        if (!mounted) return;
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _messages.removeWhere((m) => m.id == messageId);
          });
          _saveMessagesToCache();
        });
      },
    );
  }

  void _subscribeToReadReceipts() {
    _readReceiptChannel = _messagingService.subscribeToReadReceipts(
      conversationId: widget.conversationId,
      onUpdate: (messageId, userId, readAt) {
        if (!mounted) return;
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            final index = _messages.indexWhere((m) => m.id == messageId);
            if (index >= 0) {
              final senderId = _messages[index].senderId;
              final isMe = _authService.currentUser?.id == senderId;
              
              // Only consider it "read" for vanish logic if the person reading is NOT the sender
              if (userId != senderId) {
                DateTime? currentAnyReadAt = _messages[index].anyReadAt;
                if (currentAnyReadAt == null || readAt.isBefore(currentAnyReadAt)) {
                  currentAnyReadAt = readAt;
                }

                _messages[index] = _messages[index].copyWith(
                  anyReadAt: currentAnyReadAt,
                  isRead: isMe ? true : _messages[index].isRead,
                );
                
                // NEW: Instant Vanish - if Whisper Mode and receiver read it, immediately remove from screen for both users
                if (_messages[index].isEphemeral && _messages[index].ephemeralDuration == 0) {
                  debugPrint('Whisper Mode: Instant vanish triggered for message $messageId');
                  _messages.removeAt(index);
                  return; // Don't do further processing on this removed item
                }
              }

              // Also update my own read status if I'm the one who read it
              if (userId == _authService.currentUser?.id) {
                _messages[index] = _messages[index].copyWith(
                  readAt: readAt,
                  isRead: !isMe ? true : _messages[index].isRead,
                );
              }
            }
          });
        });
      },
    );
  }

  Future<void> _markAsRead() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;
    
    // Find explicitly unread messages from the other user
    final unreadMessageIds = _messages
        .where((m) => m.senderId != userId && !m.isRead)
        .map((m) => m.id)
        .toList();

    if (unreadMessageIds.isEmpty) return;

    // Optimistically update UI
    setState(() {
      for (int i = 0; i < _messages.length; i++) {
        if (unreadMessageIds.contains(_messages[i].id)) {
          _messages[i] = _messages[i].copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
        }
      }
    });

    try {
      await _messagingService.markMessagesAsRead(
        widget.conversationId,
        unreadMessageIds,
        userId,
      );
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  Future<String?> _getInitialDirectory() async {
    if (Platform.isWindows) {
      try {
        final dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
        return dir.path;
      } catch (_) {}
    }
    return null;
  }

  Future<void> _pickImage() async {
    try {
      if (Platform.isWindows) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          initialDirectory: await _getInitialDirectory(),
        );
        if (result != null && result.files.single.path != null) {
          setState(() => _selectedImage = XFile(result.files.single.path!));
        }
      } else {
        final XFile? image = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 70,
        );
        if (image != null) {
          setState(() => _selectedImage = image);
        }
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
      final result = await FilePicker.platform.pickFiles(
        initialDirectory: await _getInitialDirectory(),
      );
      if (result != null) {
        setState(() => _selectedFile = result.files.first);
        _sendMessage();
      }
    } catch (e) {
      _showError('Error picking file: $e');
    }
  }

  Future<void> _pickVideo() async {
    try {
      if (Platform.isWindows) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.video,
          initialDirectory: await _getInitialDirectory(),
        );
        if (result != null && result.files.single.path != null) {
          setState(() => _selectedVideo = File(result.files.single.path!));
        }
      } else {
        final XFile? video = await _imagePicker.pickVideo(
          source: ImageSource.gallery,
        );
        if (video != null) {
          setState(() => _selectedVideo = File(video.path));
        }
      }
    } catch (e) {
      _showError('Error picking video: $e');
    }
  }

  Future<void> _pickAudio() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        initialDirectory: await _getInitialDirectory(),
      );
      if (result != null && result.files.single.path != null) {
        File audioFile = File(result.files.single.path!);
        
        final sizeInBytes = await audioFile.length();
        final sizeInMb = sizeInBytes / (1024 * 1024);

        if (sizeInMb > 50) {
          _showError('File too large (Max 50MB).');
          return;
        }

        setState(() => _selectedAudio = audioFile);
      }
    } catch (e) {
      _showError('Error picking audio: $e');
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
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
      useRootNavigator: true,
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
                            icon: Icons.audio_file_rounded,
                            label: 'Audio',
                            iconColor: const Color(0xFFFFD43B),
                            bgColor: const Color(0xFFFFD43B).withValues(alpha: 0.1),
                            onTap: () {
                              Navigator.pop(context);
                              _pickAudio();
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
    final String content = _messageController.text.trim();
    final imageFile = _selectedImage;
    final videoFile = _selectedVideo;
    final audioFile = _selectedAudio;
    final docFile = _selectedFile;

    if (content.isEmpty &&
        imageFile == null &&
        videoFile == null &&
        audioFile == null &&
        docFile == null) {
      return;
    }

    if (EncryptionService.isEnabled && !_encryptionReady) {
      _showError('Encryption not ready. Please set up encryption first.');
      return;
    }

    final userId = _authService.currentUser?.id;
    if (userId == null) return;

    // Reset attachments and controller immediately for responsive feel
    _messageController.clear();

    // Optimistic UI for text-only messages
    Message? optimisticMessage;
    if (content.isNotEmpty && imageFile == null && videoFile == null && audioFile == null && docFile == null) {
      optimisticMessage = Message(
        id: 'optimistic_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: widget.conversationId,
        senderId: userId,
        senderName: _authService.currentUser?.username ?? 'Me',
        senderAvatar: _authService.currentUser?.photoUrl ?? '',
        content: content,
        timestamp: DateTime.now(),
        isRead: false,
        messageType: MessageType.text,
        isEphemeral: _isWhisperMode > 0,
        ephemeralDuration: _ephemeralDuration,
      );
      
      setState(() {
        _messages.add(optimisticMessage!);
      });
      _scrollToBottom();
    }

    setState(() {
      _selectedImage = null;
      _selectedVideo = null;
      _selectedAudio = null;
      _selectedFile = null;
      // ONLY show loading for media, text should be instant
      if (imageFile != null || videoFile != null || audioFile != null || docFile != null) {
        _isSending = true;
      }
    });

    try {
      String? finalContent;
      Map<String, String>? encryptedKeys;
      String? iv;
      int? signalMessageType;
      String? signalSenderContent; // RSA encrypted copy for sender
      bool usedSignal = false;

      if (EncryptionService.isEnabled) {
        final recipientId = widget.otherUserId ?? _otherUserId;
        if (recipientId == null || recipientId.isEmpty) {
          throw Exception('Recipient ID is required for encryption');
        }

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

        if (!usedSignal) {
          // Check cache for public key first
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

          // Encrypt message content
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

      // Always generate a fallback RSA encrypted copy for BOTH sender and recipient
      if (EncryptionService.isEnabled && content.isNotEmpty) {
        try {
          final recipientId = widget.otherUserId ?? _otherUserId;
          final List<String> publicKeys = [];

          // Try cache first
          final cachedRecipientPk = _publicKeyCache[recipientId];
          final cachedSenderPk = _publicKeyCache[userId];

          if (cachedRecipientPk != null) publicKeys.add(cachedRecipientPk);
          if (cachedSenderPk != null) publicKeys.add(cachedSenderPk);

          // If either is missing, fetch and update cache
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
        conversationId: widget.conversationId,
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
        whisperMode: _isWhisperMode,
        replyToId: _replyMessage?.id,
        mediaViewMode: _mediaViewMode,
      );

      // Reset view mode after sending
      setState(() {
        _mediaViewMode = 'unlimited';
      });

      // Replace optimistic message with the real one to avoid double-showing and ensure correct ID
      if (optimisticMessage != null && mounted) {
        setState(() {
          _messages.removeWhere((m) => m.id == optimisticMessage!.id);
          if (!_messages.any((m) => m.id == sentMessage.id)) {
            _decryptSingleMessage(sentMessage).then((decrypted) {
              if (mounted) {
                setState(() {
                  _messages.add(decrypted);
                });
              }
            });
          }
        });
      }

      // Clear reply state
      setState(() {
        _replyMessage = null;
      });

      // Refresh DM list preview in provider
      if (mounted) {
        final conversationProvider = context.read<ConversationProvider>();
        conversationProvider.onMessageSent(
          widget.conversationId, 
          content,
          messageType.name,
        );
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) conversationProvider.refreshConversation(widget.conversationId);
        });
      }
      _saveMessagesToCache();
    } catch (e) {
      // Remove optimistic message on failure
      if (optimisticMessage != null && mounted) {
        setState(() {
          _messages.removeWhere((m) => m.id == optimisticMessage!.id);
        });
      }
      _showError('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        _focusNode.requestFocus();
      }
    }

  }

  Future<void> _unsendMessage(Message message) async {
    try {
      // Optimistic update
      setState(() {
        _messages.removeWhere((m) => m.id == message.id);
      });
      _saveMessagesToCache();

      await _messagingService.deleteMessage(message.id);
    } catch (e) {
      debugPrint('Error unsending message: $e');
      _showError('Failed to unsend message');
      // Reload messages to restore state if delete failed
      _loadMessages();
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
              whisperMode: _isWhisperMode,
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

  Widget _buildDesktopAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 22,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }

  void _showSearchModal() {
    // Search is handled in ChatDetailsScreen for now or we can implement a local one
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Search is being perfected and will be available soon!')),
    );
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        final filePath =
            '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 32000, // 32kbps is perfect for voice
            numChannels: 1, // Mono
          ),
          path: filePath,
        );

        setState(() {
          _isRecording = true;
          _recordDuration = 0;
        });

        _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() {
              _recordDuration++;
            });
          }
        });
        HapticUtils.lightImpact();
      }
    } catch (e) {
      _showError('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      _recordTimer?.cancel();
      _recordTimer = null;
      final recordPath = await _audioRecorder.stop();

      if (mounted) {
        setState(() {
          _isRecording = false;
          _recordDuration = 0;
        });

        if (recordPath != null) {
          // Send the audio message
          await _sendAudioMessage(recordPath);
        }
      }
      HapticUtils.lightImpact();
    } catch (e) {
      _showError('Error stopping recording: $e');
      if (mounted) setState(() => _isRecording = false);
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
    final int oldMode = _isWhisperMode;
    
    // Cycle logic: 
    // If OFF -> Toggle to Last Active (Instant or 24h)
    // If ON -> Toggle to OFF
    // To change BETWEEN Instant and 24h, user can use the "Change" button in the info message
    int newMode;
    if (oldMode == 0) {
      newMode = _lastActiveWhisperMode;
    } else {
      newMode = 0;
    }
    
    setState(() {
      _isWhisperMode = newMode;
      _ephemeralDuration = newMode == 1 ? 0 : 86400;
      if (newMode > 0) {
        _lastActiveWhisperMode = newMode;
      }
    });

    // Manage screen protection
    if (newMode > 0 && oldMode == 0) {
      _enableScreenProtection();
    } else if (newMode == 0 && oldMode > 0) {
      _disableScreenProtection();
    }

    _insertSystemMessage(
      newMode > 0
          ? (newMode == 1
              ? '✨ You enabled Whisper Mode (Instant). Messages vanish after being seen.'
              : '🕒 You enabled Whisper Mode (24h). Messages vanish after 24 hours.')
          : 'You disabled Whisper Mode.',
    );

    _messagingService.toggleWhisperMode(widget.conversationId, newMode);
    // Persist the whisper mode setting
    _savePersistedSettings();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newMode > 0
              ? '✨ Whisper Mode enabled.'
              : 'Whisper Mode disabled.',
        ),
        backgroundColor: newMode > 0 ? colorScheme.secondary : Colors.green,
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
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: _backgroundUrl != null
                  ? (_bubbleColorSent?.withValues(alpha: 0.1) ?? colorScheme.primary.withValues(alpha: 0.1))
                  : colorScheme.surface.withValues(alpha: 0.7),
            ),
          ),
        ),
        automaticallyImplyLeading: !isDesktop,
        titleSpacing: isDesktop ? 24 : 0,
        title: InkWell(
          onTap: isDesktop ? null : _openChatDetails, // Disable navigation on Desktop
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: isDesktop ? 18 : 16,
                      backgroundColor: colorScheme.primaryContainer,
                      backgroundImage: (widget.otherUserAvatar ?? '').isNotEmpty
                          ? CachedNetworkImageProvider(widget.otherUserAvatar!)
                          : null,
                      child: (widget.otherUserAvatar ?? '').isEmpty
                          ? Text(
                              (widget.otherUserName ?? _otherUserName ?? 'U').isNotEmpty
                                  ? (widget.otherUserName ?? _otherUserName ?? 'U')[0].toUpperCase()
                                  : '',
                              style: TextStyle(color: colorScheme.onPrimaryContainer, fontSize: 14),
                            )
                          : null,
                    ),
                    Consumer<PresenceProvider>(
                      builder: (context, presenceProvider, child) {
                        final otherId = widget.otherUserId ?? _otherUserId;
                        final isOnline = otherId != null && presenceProvider.isUserOnline(otherId);
                        return Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: isOnline ? Colors.green : Colors.grey,
                              shape: BoxShape.circle,
                              border: Border.all(color: colorScheme.surface, width: 1.5),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.otherUserName ?? _otherUserName ?? 'Unknown',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: isDesktop ? 15 : 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Consumer<PresenceProvider>(
                      builder: (context, presenceProvider, child) {
                        final otherId = widget.otherUserId ?? _otherUserId;
                        final presence = otherId != null ? presenceProvider.getUserPresence(otherId) : null;
                        final bool isOnline = presence?.status == 'online';
                        
                        return Row(
                          children: [
                            if (_encryptionReady || _encryptionService.isInitialized) ...[
                              Icon(
                                FluentIcons.lock_closed_12_filled,
                                size: 10,
                                color: colorScheme.primary.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              isOnline ? 'Online' : (presence?.lastSeen != null ? 'Last seen ${_formatSeenTime(presence!.lastSeen!)}' : 'Offline'),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isOnline ? Colors.green.withValues(alpha: 0.8) : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (isDesktop) ...[
            _buildDesktopAction(
              icon: FluentIcons.call_24_regular,
              tooltip: 'Voice call',
              onTap: () {}, // _initiateCall(CallType.voice)
            ),
            _buildDesktopAction(
              icon: FluentIcons.video_24_regular,
              tooltip: 'Video call',
              onTap: () {}, // _initiateCall(CallType.video)
            ),
            const VerticalDivider(width: 32, indent: 16, endIndent: 16, thickness: 1),
            _buildDesktopAction(
              icon: FluentIcons.search_24_regular,
              tooltip: 'Search in chat',
              onTap: () => _showSearchModal(),
            ),
            _buildDesktopAction(
              icon: widget.isDetailsOpen ? FluentIcons.info_24_filled : FluentIcons.info_24_regular,
              tooltip: 'Chat details',
              onTap: widget.onDetailsToggle ?? _openChatDetails,
            ),
            const SizedBox(width: 12),
          ] else
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'details') {
                  _openChatDetails();
                } else if (value == 'theme') {
                  showModalBottomSheet(
                    context: context,
                    useRootNavigator: true,
                    builder:
                        (context) => SafeArea(
                          child: ChatThemeSelector(
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
              child: Opacity(
                opacity: _bgOpacity,
                child: CachedNetworkImage(
                  imageUrl: _backgroundUrl!,
                  fit: BoxFit.cover,
                  color: Colors.black.withValues(alpha: 1.0 - _bgBrightness),
                  colorBlendMode: BlendMode.darken,
                ),
              ),
            ),

          // Main Content
          Column(
            children: [
              // Messages List
              Expanded(
                child:
                    _isLoading
                        ? ListView.builder(
                          reverse: true,
                          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: EdgeInsets.only(
                            top:
                                MediaQuery.of(context).padding.top +
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
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 
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
                          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: EdgeInsets.only(
                            top:
                                MediaQuery.of(context).padding.top +
                                        kToolbarHeight +
                                        16,
                            bottom: 16,
                            left: 16,
                            right: 16,
                          ),
                          itemCount: _messages.length + 1, // Add 1 for the Whisper Mode info message
                          itemBuilder: (context, index) {
                            if (index == _messages.length) {
                              // Display Whisper Mode info message at the top of the history or wherever appropriate.
                              // For now, let's show it only if Whisper Mode is ON.
                              if (_isWhisperMode == 0) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                                child: Column(
                                  children: [
                                    Text(
                                      'You turned on disappearing messages. New messages and reactions will disappear ${_ephemeralDuration == 0 ? "instantly" : "24 hours"} after everyone has seen them.',
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    GestureDetector(
                                      onTap: _toggleWhisperMode,
                                      child: Text(
                                        'Change',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final message =
                                _messages[_messages.length - 1 - index];
                            final isMe = message.senderId == userId;
                            
                            switch (message.messageType) {
                              case MessageType.ripple:
                                return _buildRippleBubble(message, isMe);
                              case MessageType.post_share:
                                return _buildPostShareBubble(message, isMe);
                              case MessageType.story_reply:
                                return _buildStoryReplyBubble(message, isMe);
                              case MessageType.system:
                                return _buildSystemMessage(message);
                              default:
                                return _buildMessageBubble(message, isMe);
                            }
                          },
                        ),
              ),

              // Reply Preview
              if (_replyMessage != null) _buildReplyPreview(),

              // Previews (Image/File)
              if (_selectedImage != null) _buildImagePreview(),
              if (_selectedFile != null) _buildFilePreview(),
              if (_selectedAudio != null) _buildAudioPreview(),
              if (_selectedVideo != null)
                _buildVideoPreview(),
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
                      // Typing Indicator
                      Consumer<TypingIndicatorProvider>(
                        builder: (context, provider, child) {
                          if (provider.isUserTyping(widget.conversationId)) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8, left: 8),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: TypingIndicatorWidget(
                                  username: widget.otherUserName ?? _otherUserName ?? 'Someone',
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
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
                                                    .withValues(alpha: 0.08),
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
                                                          .withValues(alpha: 
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
                                                  .withValues(alpha: 
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
                                    _buildInputDecoration(
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
                                            child: _isRecording
                                                ? Row(
                                                  children: [
                                                    const SizedBox(width: 12),
                                                    const _RecordingDot(),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Recording...',
                                                      style: TextStyle(
                                                        color: _backgroundUrl != null ? Colors.white : Colors.red[700],
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    const Spacer(),
                                                    Text(
                                                      _formatDuration(Duration(seconds: _recordDuration)),
                                                      style: TextStyle(
                                                        color: _backgroundUrl != null ? Colors.white70 : Colors.red[700],
                                                        fontFeatures: const [FontFeature.tabularFigures()],
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                  ],
                                                )
                                                : CallbackShortcuts(
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
                                                focusNode: _focusNode,
                                                onChanged: (val) {                                                  // Optimized: Only send typing indicator to DB, no full screen rebuild
                                                  final userId = _authService.currentUser?.id;
                                                  if (userId != null && val.isNotEmpty) {
                                                    context.read<TypingIndicatorProvider>().setTyping(
                                                      widget.conversationId,
                                                      userId,
                                                      true,
                                                    );
                                                  }
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
                                                  hintText: _isWhisperMode > 0 ? 'Disappearing message...' : 'Type a message...',
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
                                          ValueListenableBuilder<String>(
                                            valueListenable: _textNotifier,
                                            builder: (context, text, child) {
                                              final bool isEmpty = text.trim().isEmpty && 
                                                                  _selectedImage == null && 
                                                                  _selectedVideo == null && 
                                                                  _selectedAudio == null && 
                                                                  _selectedFile == null;
                                              return Container(
                                                decoration: BoxDecoration(
                                                  color:
                                                      _isSending
                                                          ? colorScheme.onSurface
                                                              .withValues(
                                                                alpha: 0.12,
                                                              )
                                                          : (_isRecording ? Colors.red : colorScheme.primary),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: IconButton(
                                                  onPressed:
                                                      _isSending
                                                          ? null
                                                          : (isEmpty ? _toggleRecording : _sendMessage),
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
                                                            isEmpty
                                                                ? (_isRecording ? Icons.stop_rounded : Icons.mic)
                                                                : Icons
                                                                    .send_rounded,
                                                            color: Colors.white,
                                                          ),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ), // Row
                                    ), // _buildInputDecoration
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
                            _isWhisperMode > 0
                                ? '👻  Whisper on — pull up to disable'
                                : 'Pull up to enable Whisper Mode',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  _isWhisperMode > 0
                                      ? colorScheme.secondary.withValues(
                                        alpha: 0.8,
                                      )
                                      : colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.5),
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

  Widget _buildReplyPreview() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _replyMessage!.senderName,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _replyMessage!.content == 'Sent attachment'
                          ? (_replyMessage!.messageType == MessageType.voice
                              ? '🎤 Voice Message'
                              : '📷 Image')
                          : _replyMessage!.content,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () => setState(() => _replyMessage = null),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(8),
      color: colorScheme.surfaceContainerHighest,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
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
          const SizedBox(height: 8),
          _buildMediaViewModeSelector(),
        ],
      ),
    );
  }

  Widget _buildMediaViewModeSelector() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ViewModeButton(
          label: 'Keep in Chat',
          icon: Icons.chat_bubble_outline,
          isActive: _mediaViewMode == 'unlimited',
          onTap: () => setState(() => _mediaViewMode = 'unlimited'),
        ),
        const SizedBox(width: 12),
        _ViewModeButton(
          label: 'Allow Replay',
          icon: Icons.refresh_rounded,
          isActive: _mediaViewMode == 'twice',
          onTap: () => setState(() => _mediaViewMode = 'twice'),
        ),
        const SizedBox(width: 12),
        _ViewModeButton(
          label: 'View Once',
          icon: Icons.looks_one_rounded,
          isActive: _mediaViewMode == 'once',
          onTap: () => setState(() => _mediaViewMode = 'once'),
        ),
      ],
    );
  }

  Widget _buildVideoPreview() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(8),
      color: colorScheme.surfaceContainerHighest,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.videocam_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Text('Video selected'),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _selectedVideo = null),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildMediaViewModeSelector(),
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

  Widget _buildAudioPreview() {
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
          Icon(
            Icons.audio_file_rounded,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Audio selected',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _selectedAudio = null;
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

    Widget content;

    // Check if media is restricted and viewed
    final isRestricted = message.mediaViewMode == 'once' || message.mediaViewMode == 'twice';
    final viewLimit = message.mediaViewMode == 'once' ? 1 : 2;
    final isViewed = isRestricted && message.currentUserViewCount >= viewLimit;

    if (message.messageType == MessageType.image && message.mediaUrl != null) {
      if (isRestricted) {
        content = GestureDetector(
          onTap: isViewed
              ? null
              : () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (context) => ImagePreviewScreen(
                            imageUrl: message.mediaUrl!,
                            caption:
                                _isDisplayableCaption(message.content)
                                    ? message.content
                                    : null,
                            messageId: message.id,
                            mediaViewMode: message.mediaViewMode,
                          ),
                    ),
                  );
                  _loadMessages(); // Refresh to update view counts
                },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isMe
                      ? Colors.white.withValues(alpha: 0.2)
                      : colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  size: 20,
                  color: isViewed
                      ? (isMe ? Colors.white54 : Colors.grey)
                      : (isMe ? Colors.white : colorScheme.primary),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isViewed ? 'Opened' : 'Photo',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isViewed
                      ? (isMe ? Colors.white54 : Colors.grey)
                      : (isMe ? Colors.white : colorScheme.onSurface),
                  fontWeight: isViewed ? FontWeight.normal : FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        );
      } else {
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
                              _isDisplayableCaption(message.content)
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
            if (_isDisplayableCaption(message.content))
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
      }
    } else if (message.messageType == MessageType.document && (message.mediaUrl?.contains('videos') ?? false)) {
       if (isRestricted) {
        content = GestureDetector(
          onTap: isViewed
              ? null
              : () async {
                  // Video viewer would go here, using image preview for now
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (context) => ImagePreviewScreen(
                            imageUrl: message.mediaUrl!,
                            caption:
                                _isDisplayableCaption(message.content)
                                    ? message.content
                                    : null,
                            messageId: message.id,
                            mediaViewMode: message.mediaViewMode,
                          ),
                    ),
                  );
                  _loadMessages();
                },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isMe
                      ? Colors.white.withValues(alpha: 0.2)
                      : colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.videocam_rounded,
                  size: 20,
                  color: isViewed
                      ? (isMe ? Colors.white54 : Colors.grey)
                      : (isMe ? Colors.white : colorScheme.primary),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isViewed ? 'Opened' : 'Video',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isViewed
                      ? (isMe ? Colors.white54 : Colors.grey)
                      : (isMe ? Colors.white : colorScheme.onSurface),
                  fontWeight: isViewed ? FontWeight.normal : FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        );
      } else {
        // ... existing video preview code ...
        content = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.videocam_rounded,
              color:
                  isMe
                      ? (_textColorSent ?? colorScheme.onPrimaryContainer)
                      : (_textColorReceived ?? colorScheme.onSurface),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message.mediaFileName ?? 'Video',
                overflow: TextOverflow.ellipsis,
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
      }
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
                              .withValues(alpha: 0.8)
                          : (_textColorReceived ??
                              colorScheme.onSurfaceVariant),
                  fontSize: 12,
                ),
                backgroundColor:
                    isMe
                        ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
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

    final isDesktop = MediaQuery.of(context).size.width >= 1000;
    final borderRadius = BorderRadius.circular(24).copyWith(
      bottomRight: isMe ? const Radius.circular(8) : null,
      bottomLeft: !isMe ? const Radius.circular(8) : null,
    );

    final bubbleDecoration = BoxDecoration(
      color:
          isMe
              ? (_bubbleColorSent ?? colorScheme.primary)
              : (_bubbleColorReceived ??
                  colorScheme.surfaceContainerHighest),
      borderRadius: borderRadius,
      border: (isMe && !message.isEphemeral) 
        ? Border.all(color: Colors.white.withValues(alpha: 0.7), width: 0.8) 
        : null,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );

    Widget bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: bubbleDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.replyToId != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IntrinsicHeight(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 3,
                      decoration: BoxDecoration(
                        color: isMe ? Colors.white70 : colorScheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.replyToSenderName ?? 'Unknown',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isMe ? Colors.white : colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            message.replyToContent ?? 'Original message',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isMe 
                                  ? Colors.white.withValues(alpha: 0.7) 
                                  : colorScheme.onSurface.withValues(alpha: 0.6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                      message.isRead ? Colors.blue : Colors.black, // Solid Black
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
    );

    if (message.isEphemeral) {
      bubble = DottedBorder(
        borderRadius: borderRadius,
        color: isMe ? Colors.white.withValues(alpha: 0.6) : colorScheme.primary.withValues(alpha: 0.6),
        strokeWidth: 1.5,
        gap: 4,
        dash: 4,
        child: bubble,
      );
    }

    return SwipeableMessage(
      onSwipeReply: () {
        HapticUtils.selectionClick();
        setState(() {
          _replyMessage = message;
        });
        _focusNode.requestFocus();
      },
      isOwnMessage: isMe,
      child: GestureDetector(
        onLongPress: () => _showMessageOptions(context, message),
        onSecondaryTap: () => _showMessageOptions(context, message),
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
                IntrinsicWidth(
                  child: bubble,
                ),
                if (message.reactions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: MessageReactionDisplay(
                      reactions: _groupReactions(message.reactions),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          useRootNavigator: true,
                          builder: (context) => SafeArea(
                            child: MessageReactionsSheet(
                              reactions: _groupReactions(message.reactions),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Specialised bubble builders
  // ---------------------------------------------------------------------------

  /// Shared post card bubble – shows thumbnail + author + caption snippet.
  Widget _buildPostShareBubble(Message message, bool isMe) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final shareData = message.shareData;
    
    final username = shareData?['username'] ?? 'User';
    final userAvatar = shareData?['user_avatar'];
    final postContent = shareData?['content'] ?? message.content;
    final mediaUrl = message.mediaUrl ?? shareData?['image_url'];

    Widget card = Container(
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(
        color: isMe ? (colorScheme.primary.withValues(alpha: 0.15)) : (colorScheme.surface.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: InkWell(
        onTap: () {
          if (message.postId != null) {
            context.push('/post/${message.postId}');
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Author Info Header
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundImage: (userAvatar != null && userAvatar.isNotEmpty) 
                      ? NetworkImage(userAvatar) 
                      : null,
                    child: (userAvatar == null || userAvatar.isEmpty) 
                      ? Text(username[0].toUpperCase(), style: const TextStyle(fontSize: 8)) 
                      : null,
                  ),
                  const SizedBox(width: 8),
                  Text(username, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            if (mediaUrl != null)
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  child: CachedNetworkImage(imageUrl: mediaUrl, fit: BoxFit.cover),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.grid_view_rounded, size: 14, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Post shared', style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (postContent.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      postContent, 
                      style: theme.textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return GestureDetector(
      onLongPress: () => _showMessageOptions(context, message),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: card,
        ),
      ),
    );
  }

  /// Ripple bubble – shows a wave preview card.
  Widget _buildRippleBubble(Message message, bool isMe) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final shareData = message.shareData;

    final username = shareData?['username'] ?? 'User';
    final userAvatar = shareData?['user_avatar'];
    final caption = shareData?['caption'] ?? message.content;
    final mediaUrl = message.mediaUrl ?? shareData?['thumbnail_url'];

    Widget card = Container(
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(
        color: isMe ? (colorScheme.primary.withValues(alpha: 0.15)) : (colorScheme.surface.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: InkWell(
        onTap: () {
          if (message.rippleId != null) {
            context.push('/ripples', extra: {'initialRippleId': message.rippleId});
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Author Info Header
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundImage: (userAvatar != null && userAvatar.isNotEmpty) 
                        ? NetworkImage(userAvatar) 
                        : null,
                      child: (userAvatar == null || userAvatar.isEmpty) 
                        ? Text(username[0].toUpperCase(), style: const TextStyle(fontSize: 8)) 
                        : null,
                    ),
                    const SizedBox(width: 8),
                    Text(username, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              AspectRatio(
                aspectRatio: 9/16,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (mediaUrl != null)
                      CachedNetworkImage(imageUrl: mediaUrl, fit: BoxFit.cover)
                    else
                      Container(color: Colors.grey.withValues(alpha: 0.2)),
                    const Center(child: Icon(Icons.play_circle_outline, color: Colors.white, size: 48)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.waves_rounded, size: 14, color: colorScheme.secondary),
                        const SizedBox(width: 8),
                        Text('Ripple shared', style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.secondary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    if (caption.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(caption, style: theme.textTheme.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return GestureDetector(
      onLongPress: () => _showMessageOptions(context, message),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: card,
        ),
      ),
    );
  }

  /// Story reply bubble – shows a muted story thumbnail with a quote reply.
  Widget _buildStoryReplyBubble(Message message, bool isMe) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final borderRadius = BorderRadius.circular(20).copyWith(
      bottomRight: isMe ? const Radius.circular(4) : null,
      bottomLeft: !isMe ? const Radius.circular(4) : null,
    );

    final hasMedia = message.mediaUrl != null && message.mediaUrl!.isNotEmpty;

    Widget card = Container(
      constraints: const BoxConstraints(maxWidth: 260),
      decoration: BoxDecoration(
        color: isMe
            ? colorScheme.primary.withValues(alpha: 0.12)
            : colorScheme.surfaceContainerHighest,
        borderRadius: borderRadius,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasMedia)
            ClipRRect(
              borderRadius: borderRadius.copyWith(
                bottomLeft: Radius.zero,
                bottomRight: Radius.zero,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CachedNetworkImage(
                    imageUrl: message.mediaUrl!,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    color: Colors.black.withValues(alpha: 0.3),
                    colorBlendMode: BlendMode.darken,
                  ),
                  Icon(Icons.auto_stories_rounded,
                      color: Colors.white.withValues(alpha: 0.9), size: 36),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_stories_rounded,
                        size: 14,
                        color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      'Replied to a story',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (message.content.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    message.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colorScheme.onSurface),
                  ),
                ],
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    _formatTime(message.timestamp),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      onLongPress: () => _showMessageOptions(context, message),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: card,
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _showMessageOptions(BuildContext context, Message message, [Offset? position]) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userId = _authService.currentUser?.id;
    final isMe = message.senderId == userId;
    final isDesktop = MediaQuery.of(context).size.width >= 1000;

    HapticUtils.selectionClick();

    if (isDesktop && position != null) {
      showMenu(
        context: context,
        position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        elevation: 8,
        items: <PopupMenuEntry>[
          PopupMenuItem(
            onTap: () {
              setState(() => _replyMessage = message);
              _focusNode.requestFocus();
            },
            child: const Row(
              children: [
                Icon(FluentIcons.arrow_reply_24_regular, size: 20),
                SizedBox(width: 12),
                Text('Reply'),
              ],
            ),
          ),
          PopupMenuItem(
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                useRootNavigator: true,
                builder: (context) => SafeArea(
                  child: ForwardMessageModal(message: message),
                ),
              );
            },
            child: const Row(
              children: [
                Icon(FluentIcons.share_24_regular, size: 20),
                SizedBox(width: 12),
                Text('Forward'),
              ],
            ),
          ),
          if (message.messageType == MessageType.text && message.content != '🔒 Message encrypted')
            PopupMenuItem(
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.content));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
              child: const Row(
                children: [
                  Icon(FluentIcons.copy_24_regular, size: 20),
                  SizedBox(width: 12),
                  Text('Copy Text'),
                ],
              ),
            ),
          const PopupMenuDivider(),
          if (isMe)
            PopupMenuItem(
              onTap: () => _unsendMessage(message),
              child: Row(
                children: [
                  Icon(FluentIcons.delete_24_regular, size: 20, color: colorScheme.error),
                  const SizedBox(width: 12),
                  Text('Unsend', style: TextStyle(color: colorScheme.error)),
                ],
              ),
            ),
        ],
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder:
          (context) => SafeArea(
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
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
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: MessageReactionPicker(
                          onReactionSelected: (emoji) {
                            _onReactionSelected(message, emoji);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, indent: 24, endIndent: 24),
                      const SizedBox(height: 8),
                      _buildModalAction(
                        context,
                        icon: Icons.reply_rounded,
                        label: 'Reply',
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _replyMessage = message;
                          });
                          _focusNode.requestFocus();
                        },
                      ),
                      _buildModalAction(
                        context,
                        icon: Icons.shortcut_rounded,
                        label: 'Forward',
                        onTap: () {
                          Navigator.pop(context);
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            useRootNavigator: true,
                            builder: (context) => SafeArea(
                              child: ForwardMessageModal(message: message),
                            ),
                          );
                        },
                      ),
                      if (message.messageType == MessageType.text && message.content != '🔒 Message encrypted')
                        _buildModalAction(
                          context,
                          icon: Icons.copy_rounded,
                          label: 'Copy Text',
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: message.content));
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Copied to clipboard')),
                            );
                          },
                        ),
                      if (isMe)
                        _buildModalAction(
                          context,
                          icon: Icons.delete_outline_rounded,
                          label: 'Unsend',
                          isDestructive: true,
                          onTap: () {
                            Navigator.pop(context);
                            _unsendMessage(message);
                          },
                        ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildModalAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final color = isDestructive ? Colors.red : theme.colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: color.withValues(alpha: 0.8), size: 22),
            const SizedBox(width: 16),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isDisplayableCaption(String text) {
    if (text.isEmpty) return false;
    if (text == 'Sent attachment') return false;
    if (text.contains('🔒')) return false;
    // Heuristic: if it looks like ciphertext (no spaces, long, and starts with ey or ends with =)
    if (text.length > 30 && !text.contains(' ')) {
      if (text.startsWith('ey') || text.endsWith('=')) return false;
    }
    return true;
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

  Widget _buildInputDecoration({required Widget child}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderRadius = BorderRadius.circular(32);

    final decoration = BoxDecoration(
      color: _backgroundUrl != null
          ? (_bubbleColorSent?.withValues(alpha: 0.15) ??
              colorScheme.primary.withValues(alpha: 0.15))
          : colorScheme.surface.withValues(alpha: 0.5),
      borderRadius: borderRadius,
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.2),
        width: 1.0,
      ),
    );

    if (_isWhisperMode > 0) {
      return DottedBorder(
        borderRadius: borderRadius,
        color: Colors.white.withValues(alpha: 0.4),
        strokeWidth: 1.5,
        gap: 4,
        dash: 4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: decoration.copyWith(border: null),
          child: child,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: decoration,
      child: child,
    );
  }
}

class _ViewModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ViewModeButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isActive ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                fontWeight: isActive ? FontWeight.bold : null,
              ),
            ),
          ],
        ),
      ),
    );
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

class _RecordingDot extends StatefulWidget {
  const _RecordingDot();

  @override
  State<_RecordingDot> createState() => _RecordingDotState();
}

class _RecordingDotState extends State<_RecordingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
