# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- Polling fallback to `ChatProvider` (message delay fix) - Messages now sync every 10 seconds as fallback when Supabase realtime fails
- Polling fallback to `ConversationProvider` (unread count sync) - Conversations now sync every 10 seconds as fallback
- Polling fallback to `PresenceProvider` (online/offline status) - User presence now polls every 10 seconds as fallback
- Polling fallback to `TypingIndicatorProvider` (typing indicator) - Typing status now polls every 5 seconds as fallback

### Fixed
- **Root Cause:** All realtime features (messages, unread count, presence, typing, read receipts) rely on Supabase database replication which may not be enabled on the backend
- The polling fallbacks ensure features work even when Supabase realtime subscriptions fail silently
- `subscribeToReadReceipts()` - Added conversation filter in callback to avoid processing receipts for other conversations

### Files Changed
- `lib/features/messages/presentation/providers/chat_provider.dart` - Added polling timer for message sync
- `lib/providers/conversation_provider.dart` - Added polling timer for conversation/unread sync
- `lib/providers/presence_provider.dart` - Added polling timer for user presence sync
- `lib/providers/typing_indicator_provider.dart` - Added polling timer for typing indicator sync
- `lib/features/messages/data/message_operations_service.dart` - Fixed subscribeToReadReceipts to filter by conversation

---

## [Previous - Message Delay Fix]

### Added
- 10-second polling fallback in ChatProvider ensures messages appear even if realtime fails

### Root Cause Identified
- Supabase Realtime subscriptions silently failing (database replication not enabled)
- This affects ALL realtime features: messages, unread count, online status, typing indicator, read receipts