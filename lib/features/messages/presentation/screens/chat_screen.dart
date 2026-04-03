import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:oasis_v2/models/message.dart';
import 'package:oasis_v2/models/message_reaction.dart';
import 'package:oasis_v2/models/chat_theme.dart';
import 'package:oasis_v2/models/call.dart';
import 'package:oasis_v2/services/messaging_service.dart';
import 'package:oasis_v2/services/auth_service.dart';
import 'package:oasis_v2/core/network/supabase_client.dart';
import 'package:oasis_v2/services/vault_service.dart';
import 'package:oasis_v2/providers/conversation_provider.dart';
import 'package:oasis_v2/providers/typing_indicator_provider.dart';
import 'package:oasis_v2/providers/presence_provider.dart';
import 'package:oasis_v2/screens/messages/incoming_call_overlay.dart';
import 'package:oasis_v2/screens/messages/chat_details_screen.dart';
import 'package:oasis_v2/screens/messages/image_preview_screen.dart';
import 'package:oasis_v2/widgets/messages/forward_message_modal.dart';
import 'package:oasis_v2/widgets/messages/chat_theme_selector.dart';
import 'package:oasis_v2/widgets/dotted_border_painter.dart';
import 'package:oasis_v2/core/utils/haptic_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oasis_v2/features/messages/presentation/providers/providers.dart';
import 'package:oasis_v2/features/messages/presentation/widgets/chat/chat_app_bar.dart';
import 'package:oasis_v2/features/messages/presentation/widgets/chat/chat_background.dart';
import 'package:oasis_v2/features/messages/presentation/widgets/chat/chat_message_list.dart';
import 'package:oasis_v2/features/messages/presentation/widgets/chat/chat_typing_indicator.dart';
import 'package:oasis_v2/features/messages/presentation/widgets/chat/chat_input_area.dart';
import 'package:oasis_v2/features/messages/presentation/widgets/chat/chat_whisper_gesture.dart';
import 'package:oasis_v2/features/messages/presentation/widgets/previews/reply_preview.dart';
import 'package:oasis_v2/features/messages/presentation/widgets/previews/image_preview.dart';
import 'package:oasis_v2/features/messages/presentation/widgets/previews/video_preview.dart';
import 'package:oasis_v2/features/messages/presentation/widgets/previews/audio_preview.dart';
import 'package:oasis_v2/features/messages/presentation/widgets/previews/file_preview.dart';
import 'package:oasis_v2/features/messages/presentation/widgets/modals/attachment_options_sheet.dart';
import 'package:oasis_v2/features/messages/presentation/widgets/modals/message_options_sheet.dart';
import 'package:oasis_v2/features/messages/presentation/widgets/modals/message_options_menu.dart';
import 'package:oasis_v2/features/messages/presentation/widgets/shared/recording_dot.dart';
import 'package:oasis_v2/features/messages/data/datasources/chat_media_picker.dart';

/// Fully wired ChatScreen — thin orchestrator composing extracted widgets.
/// Replaces the 4,682-line legacy chat_screen.dart.
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
  late ChatProvider _chatProvider;
  late ChatEncryptionProvider _encryptionProvider;
  late ChatSettingsProvider _settingsProvider;
  late ChatRecordingProvider _recordingProvider;
  late ChatReactionsProvider _reactionsProvider;

  final TextEditingController _messageController = TextEditingController();
  final ValueNotifier<String> _textNotifier = ValueNotifier<String>('');
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final ChatMediaPicker _mediaPicker = ChatMediaPicker();

  Timer? _recordTimer;
  int _recordDuration = 0;

  // Whisper mode drag state
  double _whisperDragProgress = 0.0;
  double _whisperDragOffset = 0.0;
  bool _whisperTriggered = false;
  static const double _whisperDragThreshold = 80.0;

  DateTime? _lastResumeTime;
  late VaultService _vaultService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Create providers
    _encryptionProvider = ChatEncryptionProvider();
    _settingsProvider = ChatSettingsProvider(
      conversationId: widget.conversationId,
    );
    _recordingProvider = ChatRecordingProvider();
    _reactionsProvider = ChatReactionsProvider();

    _chatProvider = ChatProvider(
      conversationId: widget.conversationId,
      otherUserId: widget.otherUserId,
      scrollController: _scrollController,
      encryptionProvider: _encryptionProvider,
      settingsProvider: _settingsProvider,
    );

    _chatProvider.onError = (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    };

    _chatProvider.onReloadRequested = () {
      if (mounted) _chatProvider.loadMessages(silent: true);
    };

    _messageController.addListener(() {
      _textNotifier.value = _messageController.text;
      final userId = AuthService().currentUser?.id;
      if (userId != null && _messageController.text.isNotEmpty) {
        context.read<TypingIndicatorProvider>().setTyping(
          widget.conversationId,
          userId,
          true,
        );
      }
    });

    _chatProvider.initialize();

    // Subscribe to presence
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final otherId = widget.otherUserId ?? _chatProvider.state.otherUserId;
      if (otherId != null) {
        context.read<PresenceProvider>().subscribeToUserPresence(otherId);
      }
      final userId = AuthService().currentUser?.id;
      if (userId != null) {
        context.read<TypingIndicatorProvider>().subscribeToTypingStatus(
          widget.conversationId,
          userId,
        );
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _vaultService = Provider.of<VaultService>(context, listen: false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _chatProvider.onAppResumed();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recordTimer?.cancel();
    _messageController.dispose();
    _textNotifier.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _audioRecorder.dispose();

    // Unsubscribe from typing and presence
    final otherId = widget.otherUserId ?? _chatProvider.state.otherUserId;
    if (otherId != null) {
      context.read<PresenceProvider>().unsubscribeFromUserPresence(otherId);
    }
    context.read<TypingIndicatorProvider>().unsubscribeFromTypingStatus(
      widget.conversationId,
    );

    // Lock chat if interval is set to On Chat Close
    if (_vaultService.getLockInterval(widget.conversationId) == 'chat_close') {
      _vaultService.lockItem(widget.conversationId);
    }

    _chatProvider.dispose();
    _encryptionProvider.dispose();
    _settingsProvider.dispose();
    _recordingProvider.dispose();
    super.dispose();
  }

  // =========================================================================
  // Media Picking
  // =========================================================================

  Future<void> _pickImage() async {
    try {
      if (Platform.isWindows) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          initialDirectory: await _mediaPicker.getInitialDirectory(),
        );
        if (result != null && result.files.single.path != null) {
          _chatProvider.setState(
            (s) => s.copyWith(selectedImage: XFile(result.files.single.path!)),
          );
        }
      } else {
        final image = await _mediaPicker.pickImage();
        if (image != null) {
          _chatProvider.setState((s) => s.copyWith(selectedImage: image));
        }
      }
    } catch (e) {
      _showError('Error picking image: $e');
    }
  }

  Future<void> _pickVideo() async {
    try {
      if (Platform.isWindows) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.video,
          initialDirectory: await _mediaPicker.getInitialDirectory(),
        );
        if (result != null && result.files.single.path != null) {
          _chatProvider.setState(
            (s) => s.copyWith(selectedVideo: File(result.files.single.path!)),
          );
        }
      } else {
        final video = await _mediaPicker.pickVideo();
        if (video != null) {
          _chatProvider.setState(
            (s) => s.copyWith(selectedVideo: File(video.path)),
          );
        }
      }
    } catch (e) {
      _showError('Error picking video: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await _mediaPicker.pickFile();
      if (result != null) {
        _chatProvider.setState((s) => s.copyWith(selectedFile: result));
      }
    } catch (e) {
      _showError('Error picking file: $e');
    }
  }

  Future<void> _pickAudio() async {
    try {
      final result = await _mediaPicker.pickAudio();
      if (result != null) {
        _chatProvider.setState((s) => s.copyWith(selectedAudio: result));
      }
    } catch (e) {
      _showError('Error picking audio: $e');
    }
  }

  // =========================================================================
  // Recording
  // =========================================================================

  Future<void> _toggleRecording() async {
    if (_recordingProvider.isRecording) {
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
            bitRate: 32000,
            numChannels: 1,
          ),
          path: filePath,
        );

        setState(() {
          _chatProvider.setState((s) => s.copyWith(isRecording: true));
          _recordDuration = 0;
        });

        _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() => _recordDuration++);
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

      final duration = _recordDuration;
      setState(() {
        _chatProvider.setState(
          (s) => s.copyWith(isRecording: false, recordDuration: 0),
        );
        _recordDuration = 0;
      });

      if (recordPath != null) {
        final userId = AuthService().currentUser?.id;
        if (userId != null) {
          await _recordingProvider.sendAudioMessage(
            audioPath: recordPath,
            conversationId: widget.conversationId,
            userId: userId,
            recordDuration: duration,
          );
        }
      }
      HapticUtils.lightImpact();
    } catch (e) {
      _showError('Error stopping recording: $e');
      setState(() {
        _chatProvider.setState((s) => s.copyWith(isRecording: false));
      });
    }
  }

  // =========================================================================
  // Message Actions
  // =========================================================================

  void _sendMessage() async {
    final content = _messageController.text.trim();
    final state = _chatProvider.state;

    await _chatProvider.sendMessage(
      content: content,
      imageFile: state.selectedImage,
      videoFile: state.selectedVideo,
      audioFile: state.selectedAudio,
      docFile: state.selectedFile,
      replyMessage: state.replyMessage,
      mediaViewMode: state.mediaViewMode,
    );

    _messageController.clear();
  }

  Future<void> _unsendMessage(Message message) async {
    await _chatProvider.unsendMessage(message);
  }

  void _showMessageOptions(Message message, Offset? position) {
    final currentUserId = AuthService().currentUser?.id;
    final isOwn = message.senderId == currentUserId;

    if (MediaQuery.of(context).size.width >= 1000 && position != null) {
      MessageOptionsMenu(
        message: message,
        isOwnMessage: isOwn,
        position: position,
        onReply: () => _setReplyMessage(message),
        onForward: () {},
        onCopy: () {
          Clipboard.setData(ClipboardData(text: message.content));
        },
        onUnsend: () => _unsendMessage(message),
      );
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        useRootNavigator: true,
        builder:
            (context) => MessageOptionsSheet(
              message: message,
              isOwnMessage: isOwn,
              onReply: () => _setReplyMessage(message),
              onForward: () {},
              onCopy: () {
                Clipboard.setData(ClipboardData(text: message.content));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                }
              },
              onUnsend: () => _unsendMessage(message),
              onReactionSelected: (emoji) async {
                await _reactionsProvider.onReactionSelected(
                  message: message,
                  reaction: emoji,
                  userId: currentUserId ?? '',
                  username: AuthService().currentUser?.username ?? 'Unknown',
                  currentReactions: message.reactions,
                  onReactionsUpdated: (updatedReactions) {
                    _chatProvider.updateMessageReactions(
                      message.id,
                      updatedReactions,
                    );
                  },
                );
              },
            ),
      );
    }
  }

  void _setReplyMessage(Message message) {
    _chatProvider.setState((s) => s.copyWith(replyMessage: message));
    _focusNode.requestFocus();
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder:
          (context) => AttachmentOptionsSheet(
            onPhotoSelected: _pickImage,
            onVideoSelected: _pickVideo,
            onFileSelected: _pickFile,
            onAudioSelected: _pickAudio,
          ),
    );
  }

  void _openChatDetails() {
    final state = _chatProvider.state;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ChatDetailsScreen(
              conversationId: widget.conversationId,
              otherUserName:
                  widget.otherUserName ?? state.otherUserName ?? 'Unknown',
              otherUserAvatar: widget.otherUserAvatar ?? '',
              otherUserId: widget.otherUserId ?? state.otherUserId ?? '',
              whisperMode: state.whisperMode,
              currentBackground: state.backgroundUrl,
              onBackgroundSettingsChanged: (opacity, brightness) {
                _chatProvider.setState(
                  (s) =>
                      s.copyWith(bgOpacity: opacity, bgBrightness: brightness),
                );
              },
            ),
      ),
    );
  }

  void _showIncomingCallOverlay(Call call) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: IncomingCallOverlay(call: call)),
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  // =========================================================================
  // Build
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1000;

    return ChangeNotifierProvider.value(
      value: _chatProvider,
      child: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          final state = chatProvider.state;
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;

          return PopScope(
            canPop: !_focusNode.hasFocus,
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop && _focusNode.hasFocus) {
                _focusNode.unfocus();
              }
            },
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.translucent,
              child: Scaffold(
                extendBodyBehindAppBar: true,
                body: Stack(
                  children: [
                    // Background
                    ChatBackground(
                      backgroundUrl: state.backgroundUrl,
                      bgOpacity: state.bgOpacity,
                      bgBrightness: state.bgBrightness,
                    ),

                    // Main content
                    Column(
                      children: [
                        // Message list
                        Expanded(
                          child: ChatMessageList(
                            messages: state.messages,
                            isLoading: state.isLoading,
                            currentUserId: AuthService().currentUser?.id,
                            onMessageLongPress: _showMessageOptions,
                            onMessageDoubleTap: (message) async {
                              final currentUserId =
                                  AuthService().currentUser?.id;
                              if (currentUserId != null) {
                                await _reactionsProvider.onReactionSelected(
                                  message: message,
                                  reaction: '❤️',
                                  userId: currentUserId,
                                  username:
                                      AuthService().currentUser?.username ??
                                      'Unknown',
                                  currentReactions: message.reactions,
                                  onReactionsUpdated: (updatedReactions) {
                                    _chatProvider.updateMessageReactions(
                                      message.id,
                                      updatedReactions,
                                    );
                                  },
                                );
                              }
                            },
                            bubbleColorSent: state.bubbleColorSent,
                            bubbleColorReceived: state.bubbleColorReceived,
                            textColorSent: state.textColorSent,
                            textColorReceived: state.textColorReceived,
                            scrollController: _scrollController,
                          ),
                        ),

                        // Reply preview
                        if (state.replyMessage != null)
                          ReplyPreview(
                            message: state.replyMessage!,
                            onDismiss:
                                () => chatProvider.setState(
                                  (s) => s.copyWith(replyMessage: null),
                                ),
                          ),

                        // Media previews
                        if (state.selectedImage != null)
                          ImagePreview(
                            imagePath: state.selectedImage!.path,
                            mediaViewMode: state.mediaViewMode,
                            onDismiss:
                                () => chatProvider.setState(
                                  (s) => s.copyWith(selectedImage: null),
                                ),
                            onViewModeChanged:
                                (mode) => chatProvider.setState(
                                  (s) => s.copyWith(mediaViewMode: mode),
                                ),
                          ),
                        if (state.selectedVideo != null)
                          VideoPreview(
                            mediaViewMode: state.mediaViewMode,
                            onDismiss:
                                () => chatProvider.setState(
                                  (s) => s.copyWith(selectedVideo: null),
                                ),
                            onViewModeChanged:
                                (mode) => chatProvider.setState(
                                  (s) => s.copyWith(mediaViewMode: mode),
                                ),
                          ),
                        if (state.selectedAudio != null)
                          AudioPreview(
                            onDismiss:
                                () => chatProvider.setState(
                                  (s) => s.copyWith(selectedAudio: null),
                                ),
                          ),
                        if (state.selectedFile != null)
                          FilePreview(
                            file: state.selectedFile!,
                            onDismiss:
                                () => chatProvider.setState(
                                  (s) => s.copyWith(selectedFile: null),
                                ),
                          ),

                        // Smart replies
                        if (state.showingSmartReplies)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children:
                                  state.smartReplies.map((reply) {
                                    return ActionChip(
                                      label: Text(reply),
                                      onPressed: () {
                                        _messageController.text = reply;
                                        _chatProvider.setState(
                                          (s) => s.copyWith(
                                            smartReplies: [],
                                            showingSmartReplies: false,
                                          ),
                                        );
                                        _sendMessage();
                                      },
                                    );
                                  }).toList(),
                            ),
                          ),

                        // Typing indicator + Input area
                        Container(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            bottom: 16,
                            top: 8,
                          ),
                          child: SafeArea(
                            top: false,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Typing indicator
                                ChatTypingIndicator(
                                  conversationId: widget.conversationId,
                                ),

                                // Whisper mode drag gesture
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
                                    if (rawDelta <= 0 &&
                                        _whisperDragOffset == 0)
                                      return;
                                    setState(() {
                                      _whisperDragOffset = (_whisperDragOffset +
                                              rawDelta)
                                          .clamp(0.0, _whisperDragThreshold);
                                      _whisperDragProgress =
                                          _whisperDragOffset /
                                          _whisperDragThreshold;
                                    });
                                    if (_whisperDragProgress >= 1.0 &&
                                        !_whisperTriggered) {
                                      _whisperTriggered = true;
                                      HapticUtils.heavyImpact();
                                      _settingsProvider.toggleWhisperMode(
                                        currentWhisperMode: state.whisperMode,
                                        currentLastActive:
                                            state.lastActiveWhisperMode,
                                        onModeChanged: (
                                          newMode,
                                          ephemeralDuration,
                                        ) {
                                          chatProvider.setState(
                                            (s) => s.copyWith(
                                              whisperMode: newMode,
                                              ephemeralDuration:
                                                  ephemeralDuration,
                                            ),
                                          );
                                        },
                                      );
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
                                      // Circular progress ring
                                      AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 80,
                                        ),
                                        height:
                                            _whisperDragProgress > 0 ? 52 : 0,
                                        child:
                                            _whisperDragProgress > 0
                                                ? Center(
                                                  child: Stack(
                                                    alignment: Alignment.center,
                                                    children: [
                                                      Container(
                                                        width: 40,
                                                        height: 40,
                                                        decoration:
                                                            BoxDecoration(
                                                              shape:
                                                                  BoxShape
                                                                      .circle,
                                                              color: colorScheme
                                                                  .secondary
                                                                  .withValues(
                                                                    alpha: 0.08,
                                                                  ),
                                                            ),
                                                      ),
                                                      SizedBox(
                                                        width: 40,
                                                        height: 40,
                                                        child: CircularProgressIndicator(
                                                          value:
                                                              _whisperDragProgress,
                                                          strokeWidth: 3,
                                                          backgroundColor:
                                                              colorScheme
                                                                  .secondary
                                                                  .withValues(
                                                                    alpha: 0.15,
                                                                  ),
                                                          valueColor: AlwaysStoppedAnimation<
                                                            Color
                                                          >(
                                                            _whisperDragProgress >=
                                                                    1.0
                                                                ? colorScheme
                                                                    .secondary
                                                                : colorScheme
                                                                    .secondary
                                                                    .withValues(
                                                                      alpha:
                                                                          0.4 +
                                                                          _whisperDragProgress *
                                                                              0.6,
                                                                    ),
                                                          ),
                                                        ),
                                                      ),
                                                      Icon(
                                                        _whisperDragProgress >=
                                                                1.0
                                                            ? Icons.auto_delete
                                                            : Icons
                                                                .arrow_upward_rounded,
                                                        size: 18,
                                                        color: colorScheme
                                                            .secondary
                                                            .withValues(
                                                              alpha:
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
                                      // Input row
                                      Transform.translate(
                                        offset: Offset(
                                          0,
                                          -_whisperDragOffset * 0.3,
                                        ),
                                        child: ChatInputArea(
                                          controller: _messageController,
                                          focusNode: _focusNode,
                                          onSend: _sendMessage,
                                          onAttachment: _showAttachmentOptions,
                                          isRecording: state.isRecording,
                                          isSending: state.isSending,
                                          isWhisperMode: state.whisperMode,
                                          onToggleRecording: _toggleRecording,
                                          textNotifier: _textNotifier,
                                          backgroundUrl: state.backgroundUrl,
                                          textColor:
                                              state.textColorSent ??
                                              (state.backgroundUrl != null
                                                  ? Colors.white
                                                  : null),
                                          hintText:
                                              state.whisperMode > 0
                                                  ? 'Disappearing message...'
                                                  : 'Type a message...',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_whisperDragProgress == 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      state.whisperMode > 0
                                          ? '👻  Whisper on — pull up to disable'
                                          : 'Pull up to enable Whisper Mode',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color:
                                                state.whisperMode > 0
                                                    ? colorScheme.secondary
                                                        .withValues(alpha: 0.8)
                                                    : colorScheme
                                                        .onSurfaceVariant
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

                    // Floating Header - 3 containers (on top for hit testing)
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 12,
                      left: 16,
                      right: 16,
                      child: Row(
                        children: [
                          // Left: Back button (mobile only)
                          if (!isDesktop)
                            _buildFloatingContainer(
                              context,
                              isCircular: true,
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back, size: 20),
                                onPressed: () {
                                  final keyboardHeight =
                                      MediaQuery.of(context).viewInsets.bottom;
                                  if (keyboardHeight > 0) {
                                    FocusScope.of(context).unfocus();
                                  } else {
                                    if (context.mounted) context.pop();
                                  }
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ),
                          if (!isDesktop) const SizedBox(width: 8),

                          // Middle: Avatar, name, status
                          Expanded(
                            child: GestureDetector(
                              onTap: isDesktop ? null : _openChatDetails,
                              behavior: HitTestBehavior.opaque,
                              child: _buildFloatingContainer(
                                context,
                                isCircular: false,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      Stack(
                                        children: [
                                          CircleAvatar(
                                            radius: isDesktop ? 18 : 16,
                                            backgroundColor:
                                                colorScheme.primaryContainer,
                                            backgroundImage:
                                                (widget.otherUserAvatar ?? '')
                                                        .isNotEmpty
                                                    ? CachedNetworkImageProvider(
                                                      widget.otherUserAvatar!,
                                                    )
                                                    : null,
                                            child:
                                                (widget.otherUserAvatar ?? '')
                                                        .isEmpty
                                                    ? Text(
                                                      (widget.otherUserName ??
                                                                  state
                                                                      .otherUserName ??
                                                                  'U')
                                                              .isNotEmpty
                                                          ? (widget.otherUserName ??
                                                                  state
                                                                      .otherUserName ??
                                                                  'U')[0]
                                                              .toUpperCase()
                                                          : '',
                                                      style: TextStyle(
                                                        color:
                                                            colorScheme
                                                                .onPrimaryContainer,
                                                        fontSize: 14,
                                                      ),
                                                    )
                                                    : null,
                                          ),
                                          Consumer<PresenceProvider>(
                                            builder: (
                                              context,
                                              presenceProvider,
                                              child,
                                            ) {
                                              final otherId =
                                                  widget.otherUserId ??
                                                  state.otherUserId;
                                              final isOnline =
                                                  otherId != null &&
                                                  presenceProvider.isUserOnline(
                                                    otherId,
                                                  );
                                              return Positioned(
                                                right: 0,
                                                bottom: 0,
                                                child: Container(
                                                  width: 10,
                                                  height: 10,
                                                  decoration: BoxDecoration(
                                                    color:
                                                        isOnline
                                                            ? Colors.green
                                                            : Colors.grey,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color:
                                                          colorScheme.surface,
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              widget.otherUserName ??
                                                  state.otherUserName ??
                                                  'Unknown',
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                    fontSize:
                                                        isDesktop ? 15 : 14,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: -0.2,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Consumer<PresenceProvider>(
                                              builder: (
                                                context,
                                                presenceProvider,
                                                child,
                                              ) {
                                                final otherId =
                                                    widget.otherUserId ??
                                                    state.otherUserId;
                                                final presence =
                                                    otherId != null
                                                        ? presenceProvider
                                                            .getUserPresence(
                                                              otherId,
                                                            )
                                                        : null;
                                                final bool isOnline =
                                                    presence?.status ==
                                                    'online';

                                                return Row(
                                                  children: [
                                                    if (state
                                                        .encryptionReady) ...[
                                                      Icon(
                                                        FluentIcons
                                                            .lock_closed_12_filled,
                                                        size: 10,
                                                        color: colorScheme
                                                            .primary
                                                            .withValues(
                                                              alpha: 0.7,
                                                            ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                    ],
                                                    Text(
                                                      isOnline
                                                          ? 'Online'
                                                          : (presence?.lastSeen !=
                                                                  null
                                                              ? 'Last seen ${_formatSeenTime(presence!.lastSeen!)}'
                                                              : 'Offline'),
                                                      style: theme.textTheme.bodySmall?.copyWith(
                                                        color:
                                                            isOnline
                                                                ? Colors.green
                                                                    .withValues(
                                                                      alpha:
                                                                          0.8,
                                                                    )
                                                                : colorScheme
                                                                    .onSurfaceVariant
                                                                    .withValues(
                                                                      alpha:
                                                                          0.7,
                                                                    ),
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                );
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
                          ),

                          const SizedBox(width: 8),

                          // Right: Action buttons
                          _buildFloatingContainer(
                            context,
                            isCircular: true,
                            child:
                                isDesktop
                                    ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            FluentIcons.call_24_regular,
                                            size: 20,
                                          ),
                                          onPressed: () {},
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          icon: const Icon(
                                            FluentIcons.video_24_regular,
                                            size: 20,
                                          ),
                                          onPressed: () {},
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          icon: Icon(
                                            widget.isDetailsOpen
                                                ? FluentIcons.info_24_filled
                                                : FluentIcons.info_24_regular,
                                            size: 20,
                                          ),
                                          onPressed: _openChatDetails,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    )
                                    : PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'details')
                                          _openChatDetails();
                                      },
                                      icon: const Icon(
                                        Icons.more_vert,
                                        size: 20,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
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
                                          ],
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatSeenTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inMinutes < 1) return 'just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  Widget _buildFloatingContainer(
    BuildContext context, {
    required Widget child,
    required bool isCircular,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.6),
        borderRadius:
            isCircular ? BorderRadius.circular(20) : BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius:
            isCircular ? BorderRadius.circular(20) : BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: child,
        ),
      ),
    );
  }
}
