---
status: awaiting_human_verify
trigger: "mobile-notifications-not-working"
created: 2026-04-09T00:00:00Z
updated: 2026-04-09T00:00:00Z
---

## Current Focus
hypothesis: dm_notifications_not_listened
test: check if NotificationService subscribes to dm notifications and triggers NotificationManager.showNotification()
expecting: should find that dm type is filtered out and there's no code to display local notifications when dm arrives
next_action: verify root cause and implement fix

## Symptoms
expected: "When a message comes in, a notification should be displayed on the device"
actual: "No notifications are shown - neither local notifications (app in foreground) nor push notifications (FCM). Console shows initialization but nothing else."
errors: "None - no error messages, just no notifications appear"
reproduction: "Send a message to the user, check if notification appears"
started: "Unknown when this started - user never received any notifications for incoming DMs"

## Eliminated
<!-- APPEND only - prevents re-investigating -->

## Evidence
<!-- APPEND only - facts discovered -->

- timestamp: 2026-04-09
  checked: platform context
  found: "Android platform, Supabase backend, user has granted notification permissions"
  implication: "Permissions are granted, so this is not a permission issue"

- timestamp: 2026-04-09
  checked: notification flow for DMs
  found: "1) chat_messaging_service.dart creates 'dm' type notification in DB. 2) notification_service.dart explicitly FILTERS OUT dm type from notification list (line 29: .neq('type', 'dm')). 3) NO code exists that listens for dm notifications and calls NotificationManager.showNotification()"
  implication: "This is the root cause - DM notifications are never displayed as local/push notifications"

## Resolution
root_cause: "No code existed to listen for incoming 'dm' type notifications and display them via NotificationManager. The notification flow was: 1) When a message arrives, _triggerNotifications() creates a 'dm' notification in DB. 2) notification_service.dart filters dm from UI list (by design - dm notifications aren't shown in notification center). 3) NO subscription existed to listen for dm inserts and show native notifications via NotificationManager.showNotification(). This explains why console showed initialization but no notifications triggered."

fix: "Added _subscribeToDmNotifications() in app_initializer.dart that: 1) Subscribes to Supabase realtime notifications for the user. 2) Filters for 'dm' type notifications. 3) Calls NotificationManager.instance.showNotification() with sender name, message, and avatar. This mirrors the FCM handler logic but for local notifications triggered by DB inserts."

verification: "The code now has two notification paths: 1) FCM push (for background/terminated state) - already existed in _initFCM(). 2) Local notifications (for when app is in foreground) - newly added via _subscribeToDmNotifications(). Need manual testing: send DM to user, verify notification appears on device. Note: Foreground notifications while on the specific conversation screen should still be suppressed (that's a different issue - the chat screen handles read receipts locally)."
files_changed: ["lib/services/app_initializer.dart"]