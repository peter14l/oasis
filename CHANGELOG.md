# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- Polling fallback to `ChatProvider` (message delay fix) - Messages now sync every 10 seconds as fallback when Supabase realtime fails
- Polling fallback to `ConversationProvider` (unread count sync) - Conversations now sync every 10 seconds as fallback
- Polling fallback to `PresenceProvider` (online/offline status) - User presence now polls every 10 seconds as fallback
- Polling fallback to `TypingIndicatorProvider` (typing indicator) - Typing status now polls every 5 seconds as fallback
- **Live Location Improvements (2026-04-15)** - Now includes initial GPS coordinates when sharing starts, displays map preview in chat bubble with real-time updates

### Fixed
- **Root Cause:** All realtime features (messages, unread count, presence, typing, read receipts) rely on Supabase database replication which may not be enabled on the backend
- The polling fallbacks ensure features work even when Supabase realtime subscriptions fail silently
- `subscribeToReadReceipts()` - Added conversation filter in callback to avoid processing receipts for other conversations
- **Live Location Sharing** - Now sends initial location coordinates in message payload, shows map preview in bubble with real-time marker updates

### Ripples Screen Updates (2026-04-15)
- **Fixed:** Live location sharing - Added `live_location` to `media_view_mode_check` constraint in database (SQL migration created)
- **UI:** Removed layout changer and close buttons from top of mobile view
- **UI:** Increased bottom padding in M3E card layout (140→200) for more space between card and username
- **UI:** Added comment input field with send button to RippleCommentsList for posting comments
- **Feature:** Save button now properly updates `saves_count` when saving/unsaving ripples

### Files Changed
- `lib/features/messages/presentation/providers/chat_provider.dart` - Added polling timer for message sync, get initial GPS before sending live location
- `lib/providers/conversation_provider.dart` - Added polling timer for conversation/unread sync
- `lib/providers/presence_provider.dart` - Added polling timer for user presence sync
- `lib/providers/typing_indicator_provider.dart` - Added polling timer for typing indicator sync
- `lib/features/messages/data/message_operations_service.dart` - Fixed subscribeToReadReceipts to filter by conversation
- `lib/features/messages/presentation/widgets/bubbles/location_bubble.dart` - Added realtime subscription + 15s polling for live location updates, map preview with marker
- `lib/features/ripples/presentation/screens/ripples_screen.dart` - UI updates, removed top buttons, added comment input
- `lib/features/ripples/presentation/providers/ripples_provider.dart` - Fixed saves_count updates in saveRipple/unsaveRipple
- `supabase/migrations/20260415000000_live_location_fix.sql` - Added live_location to check constraint

---

## [Previous - Message Delay Fix]

### Added
- 10-second polling fallback in ChatProvider ensures messages appear even if realtime fails

### Root Cause Identified
- Supabase Realtime subscriptions silently failing (database replication not enabled)
- This affects ALL realtime features: messages, unread count, online status, typing indicator, read receipts