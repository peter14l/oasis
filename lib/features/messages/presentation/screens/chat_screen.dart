import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:oasis/features/messages/domain/models/message.dart';
import 'package:oasis/services/auth_service.dart';
import 'package:oasis/services/vault_service.dart';
import 'package:oasis/providers/typing_indicator_provider.dart';
import 'package:oasis/providers/presence_provider.dart';
import 'package:oasis/features/messages/presentation/screens/chat_details_screen.dart';
import 'package:oasis/providers/conversation_provider.dart';
import 'package:oasis/widgets/security_pin_sheet.dart';
import 'package:oasis/features/messages/data/encryption_service.dart';
import 'package:oasis/core/utils/haptic_utils.dart';
import 'package:go_router/go_router.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:oasis/features/messages/presentation/providers/providers.dart';
import 'package:oasis/features/messages/presentation/widgets/chat/chat_app_bar.dart';
import 'package:oasis/features/messages/presentation/widgets/chat/chat_background.dart';
import 'package:oasis/features/messages/presentation/widgets/chat/chat_message_list.dart';
import 'package:oasis/features/messages/presentation/widgets/chat/chat_typing_indicator.dart';
import 'package:oasis/features/messages/presentation/widgets/chat/chat_input_area.dart';
import 'package:oasis/features/messages/presentation/widgets/chat/chat_whisper_gesture.dart';
import 'package:oasis/features/messages/presentation/widgets/previews/reply_preview.dart';
import 'package:oasis/features/messages/presentation/widgets/previews/image_preview.dart';
import 'package:oasis/features/messages/presentation/widgets/previews/video_preview.dart';
import 'package:oasis/features/messages/presentation/widgets/previews/audio_preview.dart';
import 'package:oasis/features/messages/presentation/widgets/previews/file_preview.dart';
import 'package:oasis/features/messages/presentation/widgets/modals/attachment_options_sheet.dart';
import 'package:oasis/features/messages/presentation/widgets/modals/attachment_options_menu.dart';
import 'package:oasis/features/messages/presentation/widgets/modals/message_options_sheet.dart';
import 'package:oasis/features/messages/presentation/widgets/modals/message_options_menu.dart';
import 'package:oasis/features/messages/data/datasources/chat_media_picker.dart';
import 'package:oasis/features/messages/presentation/widgets/modals/giphy_picker_sheet.dart';
import 'package:oasis/features/messages/presentation/widgets/modals/location_duration_sheet.dart';

import 'package:oasis/features/calling/presentation/providers/call_provider.dart';
import 'package:oasis/features/calling/domain/models/call_entity.dart';

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
  final ChatMediaPicker _mediaPicker = ChatMediaPicker();

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

    _recordingProvider.addListener(() {
      if (mounted) {
        _chatProvider.setState(
          (s) => s.copyWith(
            isRecording: _recordingProvider.isRecording,
            recordDuration: _recordingProvider.recordDuration,
          ),
        );
      }
    });

    _recordingProvider.onRecordingComplete = (path, duration) async {
      final userId = AuthService().currentUser?.id;
      if (userId != null) {
        await _recordingProvider.sendAudioMessage(
          audioPath: path,
          conversationId: widget.conversationId,
          userId: userId,
          recordDuration: duration,
        );
      }
    };

    _recordingProvider.onError = (error) => _showError(error);

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

    _chatProvider.onEncryptionNeeded = (status) {
      if (mounted) _handleEncryptionNeeded(status);
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

    _focusNode.addListener(() {
      if (mounted) setState(() {});
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
      // Immediately reset unread badge in the inbox — no delay needed
      context.read<ConversationProvider>().markAsRead(widget.conversationId);

      // Check if vault needs to be unlocked on entry
      _checkVaultOnEntry();
    });
  }

  Future<void> _checkVaultOnEntry() async {
    if (_vaultService.isInVaultSync(widget.conversationId) &&
        !_vaultService.isItemUnlocked(widget.conversationId)) {
      final authenticated = await _vaultService.authenticate(
        itemId: widget.conversationId,
        context: context,
      );
      if (!authenticated && mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _vaultService = Provider.of<VaultService>(context);
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
    _messageController.dispose();
    _textNotifier.dispose();
    _scrollController.dispose();
    _focusNode.dispose();

    // Capture provider references before super.dispose() tears down the tree.
    // context.read() is safe here because we call it BEFORE super.dispose().
    final otherId = widget.otherUserId ?? _chatProvider.state.otherUserId;
    final convId = widget.conversationId;
    final presenceProvider = context.read<PresenceProvider>();
    final typingProvider = context.read<TypingIndicatorProvider>();

    if (otherId != null) {
      presenceProvider.unsubscribeFromUserPresence(otherId);
    }
    typingProvider.unsubscribeFromTypingStatus(convId);

    // Lock chat if interval is set to On Chat Close
    _vaultService.lockOnChatClose(widget.conversationId);

    _chatProvider.dispose();
    _encryptionProvider.dispose();
    _settingsProvider.dispose();
    _recordingProvider.dispose();
    super.dispose();
  }

  // =========================================================================
  // Encryption
  // =========================================================================

  Future<void> _handleEncryptionNeeded(EncryptionStatus status) async {
    final success = await SecurityPinSheet.show(context, status);
    if (success == true) {
      // Encryption is now ready, reinitialize the provider
      _chatProvider.setState((s) => s.copyWith(encryptionReady: true));
      await _chatProvider.loadMessages(silent: true);
    }
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
    await _recordingProvider.toggleRecording();
  }

  // =========================================================================
  // Message Actions
  // =========================================================================

  void _showGiphyPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder:
          (context) => GiphyPickerSheet(
            onSelected: (url, isSticker) {
              Navigator.pop(context);
              if (isSticker) {
                _chatProvider.sendSticker(
                  url,
                  replyMessage: _chatProvider.state.replyMessage,
                );
              } else {
                _chatProvider.sendGif(
                  url,
                  replyMessage: _chatProvider.state.replyMessage,
                );
              }
            },
          ),
    );
  }

  void _sendMessage() async {
    final content = _messageController.text.trim();
    final state = _chatProvider.state;

    // Capture media state locally before clearing for a snappy UX
    final imageFile = state.selectedImage;
    final videoFile = state.selectedVideo;
    final audioFile = state.selectedAudio;
    final docFile = state.selectedFile;
    final replyMessage = state.replyMessage;
    final mediaViewMode = state.mediaViewMode;

    if (content.isEmpty &&
        imageFile == null &&
        videoFile == null &&
        audioFile == null &&
        docFile == null) {
      return;
    }

    // Clear UI state immediately — eliminates the 1-1.5s lag where text persists
    _messageController.clear();
    _textNotifier.value = '';
    _chatProvider.setState(
      (s) => s.copyWith(
        selectedImage: null,
        selectedVideo: null,
        selectedAudio: null,
        selectedFile: null,
        replyMessage: null,
      ),
    );

    try {
      await _chatProvider.sendMessage(
        content: content,
        imageFile: imageFile,
        videoFile: videoFile,
        audioFile: audioFile,
        docFile: docFile,
        replyMessage: replyMessage,
        mediaViewMode: mediaViewMode,
      );
    } catch (e) {
      _showError('Error sending message: $e');
    }
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
            onLocationSelected: _showLocationDurationOptions,
          ),
    );
  }

  void _showLocationDurationOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder:
          (context) => LocationDurationSheet(
            onDurationSelected: (duration) async {
               try {
                 await _chatProvider.shareLiveLocation(duration);
               } catch (e) {
                 _showError('Failed to share location: $e');
               }
            },
          ),
    );
  }

  void _openChatDetails() {
    final state = _chatProvider.state;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ChangeNotifierProvider.value(
              value: _chatProvider,
              child: ChatDetailsScreen(
                conversationId: widget.conversationId,
                otherUserName:
                    widget.otherUserName ?? state.otherUserName ?? 'Unknown',
                otherUserAvatar: widget.otherUserAvatar ?? '',
                otherUserId: widget.otherUserId ?? state.otherUserId ?? '',
                whisperMode: state.whisperMode,
                currentBackground: state.backgroundUrl,
                onBackgroundSettingsChanged: (opacity, brightness) {
                  _chatProvider.setState(
                    (s) => s.copyWith(
                      bgOpacity: opacity,
                      bgBrightness: brightness,
                    ),
                  );
                },
              ),
            ),
      ),
    );
  }

  Future<void> _initiateCall(CallType type) async {
    final callProvider = context.read<CallProvider>();
    final currentUserId = AuthService().currentUser?.id;
    final otherUserId = widget.otherUserId ?? _chatProvider.state.otherUserId;

    if (currentUserId == null || otherUserId == null) {
      _showError('Cannot initiate call: User info missing');
      return;
    }

    try {
      final call = await callProvider.initiateCall(
        conversationId: widget.conversationId,
        hostId: currentUserId,
        type: type,
        participantIds: [otherUserId],
      );
      if (call != null && mounted) {
        context.pushNamed('active_call', pathParameters: {'callId': call.id});
      } else if (mounted && callProvider.state.error != null) {
        _showError(callProvider.state.error!);
      }
    } catch (e) {
      _showError('Failed to initiate call: $e');
    }
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
            canPop:
                false, // Handle manually to prevent keyboard/transition glitches
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;

              if (_focusNode.hasFocus) {
                // If keyboard is up, just dismiss it
                _focusNode.unfocus();
              } else {
                // If keyboard is down, allow navigation back
                if (context.mounted) {
                  context.pop();
                }
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
                            highlightedMessageId: state.highlightedMessageId,
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
                              vertical: 8,
                            ),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  state.smartReplies.map((reply) {
                                    final bubbleColor =
                                        state.bubbleColorSent ??
                                        theme.colorScheme.primaryContainer;
                                    final textColor =
                                        state.textColorSent ??
                                        theme.colorScheme.onPrimaryContainer;

                                    return GestureDetector(
                                      onTap: () {
                                        _messageController.text = reply;
                                        _chatProvider.setState(
                                          (s) => s.copyWith(
                                            smartReplies: [],
                                            showingSmartReplies: false,
                                          ),
                                        );
                                        _sendMessage();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: bubbleColor,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          reply,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: textColor,
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                      ),
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
                                ChatWhisperGesture(
                                  isWhisperMode: state.whisperMode,
                                  onWhisperToggle: () {
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
                                  },
                                  builder: (context, dragProgress, dragOffset) {
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Circular progress ring (visible while dragging)
                                        AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 80,
                                          ),
                                          height: dragProgress > 0 ? 52 : 0,
                                          child:
                                              dragProgress > 0
                                                  ? Center(
                                                    child: Stack(
                                                      alignment:
                                                          Alignment.center,
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
                                                                      alpha:
                                                                          0.08,
                                                                    ),
                                                              ),
                                                        ),
                                                        SizedBox(
                                                          width: 40,
                                                          height: 40,
                                                          child: CircularProgressIndicator(
                                                            value: dragProgress,
                                                            strokeWidth: 3,
                                                            backgroundColor:
                                                                colorScheme
                                                                    .secondary
                                                                    .withValues(
                                                                      alpha:
                                                                          0.15,
                                                                    ),
                                                            valueColor: AlwaysStoppedAnimation<
                                                              Color
                                                            >(
                                                              dragProgress >=
                                                                      1.0
                                                                  ? colorScheme
                                                                      .secondary
                                                                  : colorScheme
                                                                      .secondary
                                                                      .withValues(
                                                                        alpha:
                                                                            0.4 +
                                                                            dragProgress *
                                                                                0.6,
                                                                      ),
                                                            ),
                                                          ),
                                                        ),
                                                        Icon(
                                                          dragProgress >= 1.0
                                                              ? Icons
                                                                  .auto_delete
                                                              : Icons
                                                                  .arrow_upward_rounded,
                                                          size: 18,
                                                          color: colorScheme
                                                              .secondary
                                                              .withValues(
                                                                alpha:
                                                                    0.5 +
                                                                    dragProgress *
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
                                          offset: Offset(0, -dragOffset * 0.3),
                                          child: ChatInputArea(
                                            controller: _messageController,
                                            focusNode: _focusNode,
                                            onSend: _sendMessage,
                                            onAttachment:
                                                _showAttachmentOptions,
                                            onSticker: _showGiphyPicker,
                                            isRecording: state.isRecording,
                                            recordDuration:
                                                state.recordDuration,
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
                                            hasAttachment: state.selectedImage != null || 
                                                           state.selectedVideo != null || 
                                                           state.selectedAudio != null || 
                                                           state.selectedFile != null,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Floating Header
                    ChatAppBar(
                      otherUserName:
                          widget.otherUserName ??
                          state.otherUserName ??
                          'Unknown',
                      otherUserAvatar:
                          (widget.otherUserAvatar ?? '').isNotEmpty
                              ? widget.otherUserAvatar
                              : state.otherUserAvatar,
                      otherUserId: widget.otherUserId ?? state.otherUserId,
                      isEncryptionReady: state.encryptionReady,
                      isDesktop: isDesktop,
                      isDetailsOpen: widget.isDetailsOpen,
                      onDetailsToggle: _openChatDetails,
                      onCallPressed: () => _initiateCall(CallType.voice),
                      onVideoCallPressed: () => _initiateCall(CallType.video),
                    ),

                    // Vault Lock Overlay
                    if (_vaultService.isInVaultSync(widget.conversationId) &&
                        !_vaultService.isItemUnlocked(widget.conversationId))
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: () {}, // Prevent taps reaching chat
                          child: Container(
                            color: theme.colorScheme.surface,
                            child: Stack(
                              children: [
                                if (state.backgroundUrl != null)
                                  ChatBackground(
                                    backgroundUrl: state.backgroundUrl,
                                    bgOpacity: 0.1,
                                    bgBrightness: 0.2,
                                  ),
                                BackdropFilter(
                                  filter: ui.ImageFilter.blur(
                                    sigmaX: 30,
                                    sigmaY: 30,
                                  ),
                                  child: Container(
                                    color: colorScheme.surface.withValues(
                                      alpha: 0.8,
                                    ),
                                  ),
                                ),
                                SafeArea(
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(24),
                                          decoration: BoxDecoration(
                                            color: colorScheme.primary
                                                .withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            FluentIcons.lock_closed_48_filled,
                                            size: 64,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        Text(
                                          'Chat Locked',
                                          style: theme.textTheme.headlineSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Authenticate to view this conversation',
                                          textAlign: TextAlign.center,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color:
                                                    colorScheme
                                                        .onSurfaceVariant,
                                              ),
                                        ),
                                        const SizedBox(height: 48),
                                        FilledButton.icon(
                                          onPressed:
                                              () => _vaultService.authenticate(
                                                itemId: widget.conversationId,
                                                context: context,
                                              ),
                                          icon: const Icon(
                                            FluentIcons.fingerprint_24_regular,
                                          ),
                                          label: const Text('Unlock Chat'),
                                          style: FilledButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 32,
                                              vertical: 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        TextButton(
                                          onPressed:
                                              () => Navigator.pop(context),
                                          child: const Text('Go Back'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
}
