---
status: awaiting_human_verify
trigger: "call-notification-not-received"
created: 2026-04-09T00:00:00Z
updated: 2026-04-09T00:00:00Z
---

## Current Focus
hypothesis: "No push notification is sent when call is initiated - only Supabase realtime is used which only works when app is running"
test: "Check if push notification (FCM) is sent when call is initiated"
expecting: "Find that call initiation only writes to DB but doesn't trigger any push notification to recipient"
next_action: "Verify this by checking initiateCall flow for notification sending"

## Symptoms
expected: "When user makes a call, the recipient should receive a call notification/calling UI regardless of their app state (foreground/background) and current screen"
actual: "Recipient doesn't receive any call notification/calling UI when the caller initiates a call"
errors: "None specific, just no notification arrives"
reproduction: "Initiate a call from one device, check if recipient receives notification"
started: "Never worked since the calling feature was added"

## Eliminated

## Evidence

- timestamp: 2026-04-09
  checked: "call_service.dart - initiateCall method"
  found: "The initiateCall method only writes to Supabase database (calls + call_participants tables) and subscribes to realtime. It does NOT send any push notification to recipients."
  implication: "Call notifications only work via Supabase realtime, which requires the app to be running. When app is killed/backgrounded, no notification arrives."

- timestamp: 2026-04-09
  checked: "call_service.dart - startIncomingCallListener method"
  found: "The listener on call_participants uses Supabase realtime stream which only works when app is in memory"
  implication: "Even receiving side only works via realtime - no push notification is used"

- timestamp: 2026-04-09
  checked: "supabase migrations and Edge Functions"
  found: "The push-notifications Edge Function exists but is NOT connected to any database trigger. No notification type (including calls) automatically triggers FCM."
  implication: "Need to add a database trigger that invokes the Edge Function when notifications table has new rows"

## Resolution
root_cause: "When a call is initiated, only Supabase database records are created. No push notification (FCM) is sent to recipients - only Supabase realtime subscriptions are used which only work when app is running. Recipients won't receive any notification when app is killed/backgrounded."
fix: "1. Create Supabase database trigger on call_participants to invoke push notification Edge Function when new participant with 'invited' status is added. 2. Update push-notifications Edge Function to handle 'call' notification type. 3. Add handling in Flutter notification_manager.dart to navigate to call screen when tapping call notification. 4. Add handling for background notification tap to show incoming call UI."
verification: "1. Code compiles without errors - all Dart and TypeScript changes are syntactically correct. 2. Migration uses PostgreSQL http extension to directly invoke Edge Function. 3. Push notifications Edge Function now handles 'call' notification type with call_id and call_type in payload. 4. Notification manager handles call notification taps and navigates to call screen. 5. The flow: Caller initiates call -> DB insert to call_participants -> Trigger fires -> Edge Function invoked -> FCM push sent -> Recipient receives notification even when app is killed/backgrounded"
files_changed: ["lib/services/call_service.dart (verified already has correct flow)", "lib/services/notification_manager.dart", "supabase/functions/push-notifications/index.ts", "supabase/migrations/20260409000002_call_notifications_trigger.sql"]