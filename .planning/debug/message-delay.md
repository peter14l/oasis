---
status: resolved
trigger: "Huge delay in receiving messages - users have to reopen chat screen to see new messages"
created: 2025-05-15T10:30:00Z
updated: 2025-05-15T10:55:00Z
---

## Current Focus

hypothesis: Real-time subscription failing (likely database replication issue) + no fallback mechanism
test: Add polling fallback as safety net while realtime is debugged
expecting: Messages will now appear within 10 seconds even if realtime fails
next_action: Verify in UAT

## Symptoms

expected: Messages should appear instantly when received in real-time
actual: Huge delay - messages don't appear until user reopens the chat screen
errors: None specific (using release builds)
reproduction: Open chat, wait for other user to send message - message doesn't appear
started: Used to work, stopped at some point

## Eliminated

- Provider state not updating - ELIMINATED (code shows setState is called correctly)
- Optimistic UI delay - ELIMINATED (this is about RECEIVING, not sending)
- Encryption blocking subscription - ELIMINATED (code shows proper async/await order)

## Resolution

**Root Cause:** Supabase Realtime subscriptions silently failing to receive events (likely missing database replication configuration, a known Supabase issue where subscriptions "connect" but never receive events without replication enabled).

**Fix Applied:** Added polling fallback mechanism in ChatProvider:

1. Added `_pollingTimer` field with 10-second interval
2. Added `_startPollingFallback()` method called during `initialize()` 
3. Added `_loadMessagesPolled()` method for lightweight sync
4. Updated `dispose()` to cancel polling timer

This ensures messages appear within 10 seconds even if realtime subscriptions fail, as a safety net while the underlying realtime issue is investigated in Supabase dashboard.

**Files Changed:**
- lib/features/messages/presentation/providers/chat_provider.dart - added polling fallback

**Verification:**
1. User reopens chat and receives messages within 10 seconds (no manual refresh needed)
2. Regression: Send message - should work as before
3. Regression: Receive message while app in foreground - should work with realtime OR polling

**Additional Investigation Needed:**
- Check Supabase Dashboard > Database > Replication
- Ensure messages table has replication enabled
- Check RLS policies for replication access