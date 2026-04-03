# Heavy Flutter Refactoring Plan

## Overview

**Primary Target:** `lib/screens/messages/chat_screen.dart` (4,571 lines)

**Goal:** Break down the monolithic `chat_screen.dart` into a Feature-First architecture under `lib/features/messages/`, using Riverpod for state management. Each extracted module should be under 200 lines.

**Current Architecture:** Layer-based (`screens/`, `services/`, `widgets/`, `providers/`, `models/`)
**Target Architecture:** Feature-First (`lib/features/messages/{presentation, domain, data}`)

---

## Target Directory Structure

```
lib/features/messages/
├── presentation/
│   ├── screens/
│   │   └── chat_screen.dart              # Thin orchestrator (~100 lines)
│   ├── widgets/
│   │   ├── chat/
│   │   │   ├── chat_app_bar.dart         # App bar with avatar, presence, actions
│   │   │   ├── chat_background.dart      # Background image with opacity/brightness
│   │   │   ├── chat_message_list.dart    # ListView with skeletons, empty state
│   │   │   ├── chat_input_area.dart      # Text field + send/record button
│   │   │   ├── chat_whisper_gesture.dart # Pull-up whisper mode gesture
│   │   │   └── chat_typing_indicator.dart
│   │   ├── bubbles/
│   │   │   ├── message_bubble.dart       # Main bubble container + reactions
│   │   │   ├── text_bubble.dart          # Text + link preview
│   │   │   ├── image_bubble.dart         # Image with view-once logic
│   │   │   ├── video_bubble.dart
│   │   │   ├── voice_bubble.dart
│   │   │   ├── document_bubble.dart
│   │   │   ├── system_message_bubble.dart
│   │   │   ├── post_share_bubble.dart
│   │   │   ├── ripple_share_bubble.dart
│   │   │   └── story_reply_bubble.dart
│   │   ├── previews/
│   │   │   ├── reply_preview.dart
│   │   │   ├── image_preview.dart
│   │   │   ├── video_preview.dart
│   │   │   ├── audio_preview.dart
│   │   │   ├── file_preview.dart
│   │   │   └── media_view_mode_selector.dart
│   │   ├── modals/
│   │   │   ├── attachment_options_sheet.dart
│   │   │   ├── message_options_sheet.dart
│   │   │   └── message_options_menu.dart  # Desktop variant
│   │   └── shared/
│   │       ├── view_mode_button.dart
│   │       ├── attachment_option_card.dart
│   │       ├── recording_dot.dart
│   │       └── smart_reply_bar.dart
│   ├── controllers/
│   │   ├── chat_state.dart               # ChatState data class
│   │   ├── chat_controller.dart          # ChatController (Riverpod AsyncNotifier)
│   │   ├── chat_encryption_controller.dart
│   │   ├── chat_recording_controller.dart
│   │   ├── chat_reactions_controller.dart
│   │   └── chat_settings_controller.dart
│   └── mixins/
│       └── chat_scroll_mixin.dart
├── domain/
│   ├── models/
│   │   └── chat_settings.dart
│   └── repositories/
│       └── chat_repository.dart
└── data/
    ├── repositories/
    │   └── supabase_chat_repository.dart
    └── datasources/
        └── chat_cache_datasource.dart
```

---

## Execution Phases

### Phase 1: Foundation — Create Feature Structure + State Layer

**Goal:** Set up the new `lib/features/messages/` directory and create the Riverpod state layer.

#### Task 1.1: Create Directory Structure
- Create all directories listed in the target structure above.
- Create barrel files (`index.dart`) for each subdirectory for clean imports.

#### Task 1.2: Create `ChatState` Data Class
**File:** `lib/features/messages/presentation/controllers/chat_state.dart`

Extract all state variables from `_ChatScreenState` into an immutable `ChatState`:

```dart
@freezed
class ChatState with _$ChatState {
  const factory ChatState({
    required List<Message> messages,
    required bool isLoading,
    required bool isSending,
    required bool isRecording,
    required int recordDuration,
    Message? replyMessage,
    List<String> smartReplies,
    required bool showingSmartReplies,
    ChatTheme? activeTheme,
    required int whisperMode,
    required int lastActiveWhisperMode,
    required int ephemeralDuration,
    String? backgroundUrl,
    required double bgOpacity,
    required double bgBrightness,
    required String mediaViewMode,
    Color? bubbleColorSent,
    Color? bubbleColorReceived,
    Color? textColorSent,
    Color? textColorReceived,
    required bool encryptionReady,
    XFile? selectedImage,
    File? selectedVideo,
    File? selectedAudio,
    PlatformFile? selectedFile,
    required double whisperDragProgress,
    required double whisperDragOffset,
    required bool whisperTriggered,
    String? otherUserName,
    String? otherUserId,
  }) = _ChatState;
}
```

#### Task 1.3: Create `ChatController` (Riverpod AsyncNotifier)
**File:** `lib/features/messages/presentation/controllers/chat_controller.dart`

Migrate the following methods from `_ChatScreenState` into the controller:
- `loadMessages()` (from `_loadMessages`)
- `subscribeToMessages()` → handled via stream in controller
- `subscribeToReadReceipts()`
- `markAsRead()`
- `sendMessage()` — split into sub-methods for clarity
- `unsendMessage()`
- `scrollToBottom()`
- `fetchConversationDetails()`
- `loadSmartReplies()`

The controller should accept `conversationId` and `otherUserId` as constructor parameters.

#### Task 1.4: Create `ChatEncryptionController`
**File:** `lib/features/messages/presentation/controllers/chat_encryption_controller.dart`

Extract:
- `_initializeEncryption()`
- `_decryptSingleMessage()`
- `_enableScreenProtection()` / `_disableScreenProtection()`
- `_extractColorsFromBackground()`

#### Task 1.5: Create `ChatRecordingController`
**File:** `lib/features/messages/presentation/controllers/chat_recording_controller.dart`

Extract:
- `_toggleRecording()`
- `_startRecording()`
- `_stopRecording()`
- `_sendAudioMessage()`
- `_formatDuration()`

#### Task 1.6: Create `ChatReactionsController`
**File:** `lib/features/messages/presentation/controllers/chat_reactions_controller.dart`

Extract:
- `_groupReactions()`
- `_onReactionSelected()`

#### Task 1.7: Create `ChatSettingsController`
**File:** `lib/features/messages/presentation/controllers/chat_settings_controller.dart`

Extract:
- `_loadPersistedSettings()`
- `_savePersistedSettings()`
- `_toggleWhisperMode()`
- `_handleThemeChange()`
- `_loadCachedMessages()`
- `_saveMessagesToCache()`

---

### Phase 2: Extract Widget Components (Bottom-Up)

**Goal:** Extract all private `_build*` methods and inner widget classes into standalone, reusable widgets.

#### Task 2.1: Extract Shared Helper Widgets
**Files:**
- `lib/features/messages/presentation/widgets/shared/view_mode_button.dart`
  - Extract `_ViewModeButton` class.
- `lib/features/messages/presentation/widgets/shared/attachment_option_card.dart`
  - Extract `_AttachmentOption` class.
- `lib/features/messages/presentation/widgets/shared/recording_dot.dart`
  - Extract `_RecordingDot` class.
- `lib/features/messages/presentation/widgets/shared/smart_reply_bar.dart`
  - Extract `SmartReplyBar` usage wrapper (if not already a standalone widget).

#### Task 2.2: Extract Preview Widgets
**Files:**
- `lib/features/messages/presentation/widgets/previews/reply_preview.dart`
  - Extract `_buildReplyPreview()` method.
- `lib/features/messages/presentation/widgets/previews/image_preview.dart`
  - Extract `_buildImagePreview()` + `_buildMediaViewModeSelector()`.
- `lib/features/messages/presentation/widgets/previews/video_preview.dart`
  - Extract `_buildVideoPreview()`.
- `lib/features/messages/presentation/widgets/previews/audio_preview.dart`
  - Extract `_buildAudioPreview()`.
- `lib/features/messages/presentation/widgets/previews/file_preview.dart`
  - Extract `_buildFilePreview()`.

#### Task 2.3: Extract Message Bubble Widgets
**Files:**
- `lib/features/messages/presentation/widgets/bubbles/system_message_bubble.dart`
  - Extract `_buildSystemMessage()`.
- `lib/features/messages/presentation/widgets/bubbles/text_bubble.dart`
  - Extract text rendering + link preview logic from `_buildMessageBubble()`.
  - Include `_isDisplayableCaption()`, `_containsUrl()`, `_extractUrl()`.
- `lib/features/messages/presentation/widgets/bubbles/image_bubble.dart`
  - Extract image rendering + view-once/allow-replay logic.
- `lib/features/messages/presentation/widgets/bubbles/video_bubble.dart`
  - Extract video rendering + view-once logic.
- `lib/features/messages/presentation/widgets/bubbles/voice_bubble.dart`
  - Extract `VoiceMessagePlayer` wrapper.
- `lib/features/messages/presentation/widgets/bubbles/document_bubble.dart`
  - Extract document display + download logic.
- `lib/features/messages/presentation/widgets/bubbles/post_share_bubble.dart`
  - Extract `_buildPostShareBubble()`.
- `lib/features/messages/presentation/widgets/bubbles/ripple_share_bubble.dart`
  - Extract `_buildRippleBubble()`.
- `lib/features/messages/presentation/widgets/bubbles/story_reply_bubble.dart`
  - Extract `_buildStoryReplyBubble()`.
- `lib/features/messages/presentation/widgets/bubbles/message_bubble.dart`
  - The main bubble container that wraps the above. Handles:
    - Bubble decoration (colors, border radius, shadows)
    - Reply-to preview inside bubble
    - Read receipts (checkmarks + "Seen" text)
    - Reactions display
    - Swipeable wrapper
    - Long-press → options modal
    - Double-tap → heart reaction

#### Task 2.4: Extract Modal/Sheet Widgets
**Files:**
- `lib/features/messages/presentation/widgets/modals/attachment_options_sheet.dart`
  - Extract `_showAttachmentOptions()` and the entire bottom sheet UI.
- `lib/features/messages/presentation/widgets/modals/message_options_sheet.dart`
  - Extract `_showMessageOptions()` mobile bottom sheet variant.
  - Include `_buildModalAction()`.
- `lib/features/messages/presentation/widgets/modals/message_options_menu.dart`
  - Extract `_showMessageOptions()` desktop `showMenu` variant.

#### Task 2.5: Extract Chat UI Components
**Files:**
- `lib/features/messages/presentation/widgets/chat/chat_app_bar.dart`
  - Extract the entire `AppBar` from `build()` method (~200 lines).
  - Includes: avatar, presence indicator, encryption lock icon, online status, desktop action buttons, mobile popup menu.
  - Include `_buildDesktopAction()`.
- `lib/features/messages/presentation/widgets/chat/chat_background.dart`
  - Extract the `Positioned.fill` background image with opacity/brightness/colorBlendMode.
- `lib/features/messages/presentation/widgets/chat/chat_message_list.dart`
  - Extract the `ListView.builder` with:
    - Skeleton loading state
    - Empty state
    - Message rendering with type switch
    - Padding calculations for AppBar
- `lib/features/messages/presentation/widgets/chat/chat_typing_indicator.dart`
  - Extract the `Consumer<TypingIndicatorProvider>` block.
- `lib/features/messages/presentation/widgets/chat/chat_whisper_gesture.dart`
  - Extract the `GestureDetector` for pull-up whisper mode with circular progress ring.
- `lib/features/messages/presentation/widgets/chat/chat_input_area.dart`
  - Extract the text input row: attachment button, TextField, send/record button.
  - Include `_buildInputDecoration()` with DottedBorder logic.
  - Include keyboard shortcuts for desktop Enter-to-send.

---

### Phase 3: Extract Media & File Picking Logic

**Goal:** Move all media picking and file handling into dedicated services or controller methods.

#### Task 3.1: Create `ChatMediaPicker` Service
**File:** `lib/features/messages/data/datasources/chat_media_picker.dart`

Extract:
- `_getInitialDirectory()`
- `_pickImage()`
- `_pickFile()`
- `_pickVideo()`
- `_pickAudio()`
- `_showError()`

This can be a simple class with methods that return `Future<XFile?>`, `Future<File?>`, etc.

#### Task 3.2: Integrate Media Picker into Controller
- Wire the `ChatMediaPicker` into `ChatController` so that `sendMessage()` can receive pre-picked media.

---

### Phase 4: Rebuild the Thin ChatScreen

**Goal:** Rewrite `chat_screen.dart` as a thin orchestrator that composes the extracted widgets and connects to Riverpod providers.

#### Task 4.1: Rewrite `ChatScreen` Widget
**File:** `lib/features/messages/presentation/screens/chat_screen.dart`

The new screen should:
1. Accept the same constructor parameters (`conversationId`, `otherUserName`, etc.)
2. Use `ChatController` via Riverpod (`ref.watch` / `ref.read`)
3. Compose extracted widgets:
   ```dart
   Scaffold(
     extendBodyBehindAppBar: true,
     appBar: ChatAppBar(...),
     body: Stack(
       children: [
         ChatBackground(...),
         Column(
           children: [
             Expanded(child: ChatMessageList(...)),
             if (replyMessage != null) ReplyPreview(...),
             if (selectedImage != null) ImagePreview(...),
             // ... other previews
             if (showingSmartReplies) SmartReplyBar(...),
             ChatInputArea(...),
           ],
         ),
       ],
     ),
   )
   ```
4. Handle `PopScope` keyboard/back behavior.
5. Handle `GestureDetector` for unfocusing keyboard.

**Target size:** ~100-150 lines.

---

### Phase 5: Router & Import Migration

**Goal:** Update all references to the old `chat_screen.dart` and ensure the app compiles.

#### Task 5.1: Update Router
**File:** `lib/routes/app_router.dart`

- Update any route that imports `chat_screen.dart` from the old path to the new `lib/features/messages/presentation/screens/chat_screen.dart`.
- Verify `go_router` or `Navigator` usages still work with the same constructor parameters.

#### Task 5.2: Update All Import References
- Search the entire codebase for `import 'package:oasis_v2/screens/messages/chat_screen.dart'`.
- Replace with the new import path.
- Verify no broken imports after the migration.

#### Task 5.3: Clean Up Old Files
- Once verified working, delete or archive the original `lib/screens/messages/chat_screen.dart`.
- Consider keeping it as `chat_screen.dart.bak` temporarily for rollback safety.

---

### Phase 6: Verification & QA

**Goal:** Ensure the refactored code is functionally identical to the original.

#### Task 6.1: Compilation Check
- Run `flutter analyze` — zero errors, zero new warnings.
- Run `flutter build apk --debug` (or your target platform) — successful build.

#### Task 6.2: Functional Testing Scenarios
Verify each of these scenarios works identically to before:
1. **Text messaging:** Send/receive plain text messages.
2. **Media messaging:** Send images, videos, audio, files.
3. **Optimistic updates:** Text appears instantly before server confirmation.
4. **Encryption:** End-to-end encryption works (Signal + RSA fallback).
5. **Realtime updates:** New messages appear without refresh.
6. **Read receipts:** Double-checkmarks update correctly.
7. **Whisper mode:** Pull-up gesture toggles, screen protection activates.
8. **Voice recording:** Record, stop, send audio messages.
9. **Reactions:** Add/remove/toggle emoji reactions (optimistic + DB sync).
10. **Smart replies:** Appear for received text messages.
11. **Reply to message:** Swipe-to-reply, reply preview shows, sends correctly.
12. **Message options:** Long-press shows Reply/Forward/Copy/Unsend.
13. **Chat details:** Navigate to details, change background, return.
14. **Typing indicator:** Shows when other user types.
15. **Presence:** Online/offline status displays correctly.
16. **Background image:** Custom backgrounds with color extraction work.
17. **View-once media:** Once/twice/keep modes work correctly.
18. **Message cache:** Messages load from cache on cold start.
19. **App lifecycle:** Reload on resume, reconnect realtime.
20. **Desktop vs Mobile:** Responsive layout adapts correctly.

#### Task 6.3: Performance Check
- Verify no jank during message list scrolling.
- Verify decryption doesn't block UI (should use `Future.delayed(Duration.zero)` yields).
- Verify image background color extraction doesn't cause frame drops.

---

## Migration Strategy

### Approach: Strangler Fig Pattern
1. Create the new feature structure alongside the old code.
2. Build and test the new `ChatScreen` in isolation (can be accessed via a temporary route like `/chat-v2`).
3. Once verified, swap the router to point to the new screen.
4. Delete the old file.

### Risk Mitigation
- **Git branch:** Create a `refactor/messages-feature` branch before starting.
- **Incremental commits:** Commit after each phase. Each commit should compile.
- **Rollback plan:** The old `chat_screen.dart` remains untouched until Phase 5.3.
- **No behavior changes:** The refactoring is purely structural. Zero UI/UX changes.

---

## File Size Targets

| File | Current Lines | Target Lines |
|------|--------------|--------------|
| `chat_screen.dart` (orchestrator) | 4,571 | ~120 |
| `chat_controller.dart` | — | ~250 |
| `chat_encryption_controller.dart` | — | ~150 |
| `chat_recording_controller.dart` | — | ~80 |
| `chat_reactions_controller.dart` | — | ~80 |
| `chat_settings_controller.dart` | — | ~120 |
| `chat_app_bar.dart` | — | ~150 |
| `chat_message_list.dart` | — | ~120 |
| `chat_input_area.dart` | — | ~200 |
| `message_bubble.dart` | — | ~150 |
| Each bubble widget | — | ~60-100 |
| Each preview widget | — | ~40-60 |
| Each modal widget | — | ~80-120 |
| Helper widgets | — | ~30-50 |

**Total files created:** ~30+
**Max file size:** ~250 lines
**Average file size:** ~80 lines

---

## Dependencies

### New Packages (if not already present)
- `riverpod` / `flutter_riverpod` — State management
- `freezed` + `freezed_annotation` — Immutable state classes (optional, can use plain classes)
- `riverpod_generator` — Code generation for providers (optional)

### Existing Packages Used
- `provider` — Currently used, will coexist during migration
- `supabase_flutter` — Realtime subscriptions
- `shared_preferences` — Local caching
- `cached_network_image` — Image loading
- `record` — Audio recording
- `image_picker` / `file_picker` — Media selection
- `palette_generator` — Color extraction
- `screen_protector` — Screenshot prevention
- `go_router` — Navigation
- `any_link_preview` — URL previews
- `fluentui_system_icons` — Icons

---

## Post-Refactoring: Next Targets

After `chat_screen.dart` is complete, apply the same pattern to:

1. `lib/screens/messages/direct_messages_screen.dart` (1,714 lines) → `lib/features/messages/presentation/screens/direct_messages_screen.dart`
2. `lib/themes/app_theme.dart` (1,532 lines) → Split into `app_colors.dart`, `app_typography.dart`, `app_components.dart`
3. `lib/routes/app_router.dart` (1,357 lines) → Split by feature route groups
4. `lib/screens/settings_screen.dart` (1,286 lines) → `lib/features/settings/`
