---
status: investigating
trigger: "Investigate issue: unread-message-counter-missing"
created: 2025-02-14T11:47:00Z
updated: 2025-02-14T12:30:00Z
---

## Current Focus

hypothesis: There are two main issues:
1. `REPLICA IDENTITY FULL` is missing on `conversation_participants`, causing `conversation_id` to be null in realtime updates, which prevents `ConversationProvider` from refreshing.
2. `ConversationProvider._handleReadReceiptUpdate` optimistically zeros out the unread count for ALL conversations whenever ANY read receipt is received, because `subscribeToReadReceipts` does not filter by conversation.
test: 
1. Check `ConversationService.subscribeToConversations` for null-pointer/type errors when `conversation_id` is missing.
2. Verify `REPLICA IDENTITY` for `conversation_participants`.
3. Analyze `ConversationProvider`'s handling of read receipts.
expecting: To confirm that updates are failing and that read receipts are incorrectly clearing unread counts.
next_action: Apply fixes for REPLICA IDENTITY and the aggressive optimistic update.

## Symptoms

expected: It should be positioned at the top of the conversation bubbles and look like a counter.
actual: It's absent.
errors: Unknown (running release APK).
reproduction: Send a message to a user and check the direct messages screen.
started: It used to work at some point.

## Eliminated

## Evidence

- timestamp: 2025-02-14T12:15:00Z
  checked: lib/features/messages/data/conversation_service.dart
  found: `subscribeToConversations` expects `conversation_id` in `payload.newRecord`.
  implication: Without `REPLICA IDENTITY FULL` on `conversation_participants`, `conversation_id` is NOT sent on updates, causing the callback to fail.

- timestamp: 2025-02-14T12:20:00Z
  checked: lib/features/messages/data/message_operations_service.dart
  found: `subscribeToReadReceipts` does not filter by `conversation_id` because the table lacks that column.
  implication: It listens to ALL read receipts for the user.

- timestamp: 2025-02-14T12:25:00Z
  checked: lib/providers/conversation_provider.dart
  found: `_handleReadReceiptUpdate` optimistically zeros out `unreadCount` for the conversation it was called for.
  implication: Since `subscribeToReadReceipts` triggers for EVERY conversation on ANY read receipt, all unread counts are cleared optimistically.

## Resolution

root_cause: 
fix: 
verification: 
files_changed: []
