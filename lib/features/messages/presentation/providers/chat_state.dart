import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:oasis/models/message.dart';
import 'package:oasis/models/chat_theme.dart';

/// Immutable UI state for the chat screen.
/// Extracted from the 4,571-line _ChatScreenState in chat_screen.dart.
/// Does NOT include RealtimeChannel subscriptions — those live in the Provider.
class ChatState {
  final List<Message> messages;
  final bool isLoading;
  final bool isSending;
  final bool isRecording;
  final int recordDuration;
  final Message? replyMessage;
  final List<String> smartReplies;
  final bool showingSmartReplies;
  final ChatTheme? activeTheme;
  final int whisperMode;
  final int lastActiveWhisperMode;
  final int ephemeralDuration;
  final String? backgroundUrl;
  final double bgOpacity;
  final double bgBrightness;
  final String mediaViewMode;
  final Color? bubbleColorSent;
  final Color? bubbleColorReceived;
  final Color? textColorSent;
  final Color? textColorReceived;
  final bool encryptionReady;
  final XFile? selectedImage;
  final File? selectedVideo;
  final File? selectedAudio;
  final PlatformFile? selectedFile;
  final double whisperDragProgress;
  final double whisperDragOffset;
  final bool whisperTriggered;
  final String? otherUserName;
  final String? otherUserId;
  final String? otherUserAvatar;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.isRecording = false,
    this.recordDuration = 0,
    this.replyMessage,
    this.smartReplies = const [],
    this.showingSmartReplies = false,
    this.activeTheme,
    this.whisperMode = 0,
    this.lastActiveWhisperMode = 1,
    this.ephemeralDuration = 86400,
    this.backgroundUrl,
    this.bgOpacity = 1.0,
    this.bgBrightness = 0.7,
    this.mediaViewMode = 'unlimited',
    this.bubbleColorSent,
    this.bubbleColorReceived,
    this.textColorSent,
    this.textColorReceived,
    this.encryptionReady = false,
    this.selectedImage,
    this.selectedVideo,
    this.selectedAudio,
    this.selectedFile,
    this.whisperDragProgress = 0.0,
    this.whisperDragOffset = 0.0,
    this.whisperTriggered = false,
    this.otherUserName,
    this.otherUserId,
    this.otherUserAvatar,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isLoading,
    bool? isSending,
    bool? isRecording,
    int? recordDuration,
    Message? replyMessage,
    List<String>? smartReplies,
    bool? showingSmartReplies,
    ChatTheme? activeTheme,
    int? whisperMode,
    int? lastActiveWhisperMode,
    int? ephemeralDuration,
    String? backgroundUrl,
    double? bgOpacity,
    double? bgBrightness,
    String? mediaViewMode,
    Color? bubbleColorSent,
    Color? bubbleColorReceived,
    Color? textColorSent,
    Color? textColorReceived,
    bool? encryptionReady,
    XFile? selectedImage,
    File? selectedVideo,
    File? selectedAudio,
    PlatformFile? selectedFile,
    double? whisperDragProgress,
    double? whisperDragOffset,
    bool? whisperTriggered,
    String? otherUserName,
    String? otherUserId,
    String? otherUserAvatar,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      isRecording: isRecording ?? this.isRecording,
      recordDuration: recordDuration ?? this.recordDuration,
      replyMessage: replyMessage ?? this.replyMessage,
      smartReplies: smartReplies ?? this.smartReplies,
      showingSmartReplies: showingSmartReplies ?? this.showingSmartReplies,
      activeTheme: activeTheme ?? this.activeTheme,
      whisperMode: whisperMode ?? this.whisperMode,
      lastActiveWhisperMode:
          lastActiveWhisperMode ?? this.lastActiveWhisperMode,
      ephemeralDuration: ephemeralDuration ?? this.ephemeralDuration,
      backgroundUrl: backgroundUrl ?? this.backgroundUrl,
      bgOpacity: bgOpacity ?? this.bgOpacity,
      bgBrightness: bgBrightness ?? this.bgBrightness,
      mediaViewMode: mediaViewMode ?? this.mediaViewMode,
      bubbleColorSent: bubbleColorSent ?? this.bubbleColorSent,
      bubbleColorReceived: bubbleColorReceived ?? this.bubbleColorReceived,
      textColorSent: textColorSent ?? this.textColorSent,
      textColorReceived: textColorReceived ?? this.textColorReceived,
      encryptionReady: encryptionReady ?? this.encryptionReady,
      selectedImage: selectedImage ?? this.selectedImage,
      selectedVideo: selectedVideo ?? this.selectedVideo,
      selectedAudio: selectedAudio ?? this.selectedAudio,
      selectedFile: selectedFile ?? this.selectedFile,
      whisperDragProgress: whisperDragProgress ?? this.whisperDragProgress,
      whisperDragOffset: whisperDragOffset ?? this.whisperDragOffset,
      whisperTriggered: whisperTriggered ?? this.whisperTriggered,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserAvatar: otherUserAvatar ?? this.otherUserAvatar,
    );
  }
}
