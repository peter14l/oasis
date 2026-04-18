---
status: investigating
trigger: "Investigate and fix the following issues in the Oasis app: 1. Global UI stuttering and delayed touch response (Performance). 2. Notifications broken after switching to data-only FCM messages (Regression). 3. Chat reply context stays attached after sending a message (Logic bug). 4. Chat TextInputBox height reduction and alignment (UI polish)."
created: 2026-04-18T14:31:00Z
updated: 2026-04-18T14:31:00Z
---

## Current Focus

hypothesis: Global UI stuttering might be caused by excessive work on the main thread or inefficient notification handling logic introduced in commit dc8f271. Notifications failure is likely due to incorrect processing of data-only FCM messages in the background isolate. Chat reply context persistence is a state management issue in ChatScreen. Input box UI needs layout adjustments.
test: Review commit dc8f271 changes, examine notification service and background handler, check ChatScreen state management, and inspect ChatTextInputBox widget.
expecting: Identification of performance bottlenecks, fixing FCM data message handling, ensuring state reset after chat send, and adjusting UI layout.
next_action: Examine commit dc8f271 and related notification/background code.

## Symptoms

expected: Smooth UI; Notifications received; Reply context cleared after send; Aligned input box.
actual: Lag/stuttering; No notifications; Reply context persists; Input box too tall/misaligned.
errors: Unknown (release build), but suspected background isolate issues.
reproduction: Use app for some time; Trigger notification; Send a reply in ChatScreen; View ChatScreen input area.
started: Performance and Notifications issues started after commit dc8f271 (data-only FCM transition).

## Eliminated

## Evidence

- timestamp: 2026-04-18T14:50:00Z
  checked: lib/services/notification_manager.dart
  found: FCM onMessage listener only handles messages with notification != null. Data-only messages are ignored in foreground.
  implication: This explains Issue 2 for foreground notifications.

- timestamp: 2026-04-18T14:55:00Z
  checked: lib/services/app_initializer.dart
  found: firebaseMessagingBackgroundHandler calls NotificationDecryptionService.decryptMessage which calls EncryptionService.init. EncryptionService.init uses Supabase.instance, but Supabase is never initialized in the background isolate.
  implication: This explains Issue 2 for background notifications (crash in isolate).

- timestamp: 2026-04-18T15:00:00Z
  checked: lib/features/messages/presentation/providers/chat_state.dart
  found: ChatState.copyWith uses `replyMessage: replyMessage ?? this.replyMessage`. This makes it impossible to clear replyMessage by passing null.
  implication: This explains Issue 3.

- timestamp: 2026-04-18T15:05:00Z
  checked: lib/features/messages/presentation/widgets/chat/chat_input_area.dart
  found: ChatInputArea uses CrossAxisAlignment.end and fixed padding which might lead to misalignment and excessive height when combined with CustomTextField's internal padding and maxLines: 2.
  implication: This explains Issue 4.

## Resolution

root_cause: 
fix: 
verification: 
files_changed: []
