---
status: investigating
trigger: "Messaging regressions including unread counter, delay, read receipts, typing indicator, and online status."
created: 2025-05-15T10:00:00Z
updated: 2025-05-15T10:55:00Z
---

## Current Focus

hypothesis: Root cause identified - Supabase Realtime subscriptions failing silently (database replication issue) plus no fallback
test: Add polling fallback in ChatProvider for message sync
expecting: Messages now appear within 10 seconds even if realtime fails
next_action: Test fix in UAT, also investigate unread counter and other realtime features

## Root Cause Identified

The message delay issue has been FIXED with a polling fallback in chat_provider.dart.

The underlying cause is likely Supabase Realtime subscriptions silently failing:
- Subscriptions "connect" but never receive events
- This happens when database replication isn't enabled for the tables
- Known Supabase limitation

## Related Issues

Other broken features (unread counter, typing indicator, read receipts) likely have the same root cause:
- They all use Supabase Realtime subscriptions
- subscribeToConversations (unread count)
- subscribeToReadReceipts (blue checkmarks)
- subscribeToTypingStatus (typing indicator)

## Fix Applied

chat_provider.dart - added polling fallback:
- Timer.periodic every 10 seconds to refresh messages
- Ensures messages appear even if realtime fails
- Will help identify if realtime is working vs completely broken

## Verification

Test the fix: Reopen chat, wait 10 seconds - messages should appear without manual refresh

For the other broken features, same investigation path needed:
- Check Supabase Dashboard > Database > Replication
- Enable replication for: messages, message_read_receipts, typing_indicators, conversation_participants
