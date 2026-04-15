---
status: resolved
trigger: "fcm-background-notifications-not-showing"
created: 2026-04-13T00:00:00.000Z
updated: 2026-04-13T00:00:00.000Z
---

## Current Focus
<!-- OVERWRITE on each update - reflects NOW -->

hypothesis: "Root cause identified: iOS missing UIBackgroundModes for FCM background delivery"
test: "Verify platform configurations for FCM background notifications"
expecting: "Add missing background mode configurations to iOS and Android manifests"
next_action: "Apply fixes to iOS Info.plist and Android AndroidManifest.xml"

## Symptoms
<!-- Written during gathering, then IMMUTABLE -->

expected: "System-native notifications should appear when app is in background or terminated - FCM should deliver notifications via OS notification system even when app is closed"
actual: "Notifications only appear when app is open. No system-native notifications when app is backgrounded or terminated."
errors: "None - no errors, just no notifications appear in background/terminated state"
reproduction: "Send FCM push notification to device while app is in background or terminated - no notification appears"
started: "Unknown when this started - user has been testing and noticed notifications only work in foreground"

## Eliminated
<!-- APPEND only - prevents re-investigating -->

- hypothesis: "FCM background handler not registered"
  evidence: "Line 245 in app_initializer.dart shows FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler) is registered correctly"
  timestamp: "2026-04-13T00:00:00.000Z"

- hypothesis: "Server-side FCM payload missing notification block"
  evidence: "push-notifications/index.ts lines 166-169 show notification block IS included in FCM payload: notification: { title, body }"
  timestamp: "2026-04-13T00:00:00.000Z"

- hypothesis: "Missing notification channel on Android"
  evidence: "notification_manager.dart lines 316-334 show Android notification channel is created with 'oasis_channel'"
  timestamp: "2026-04-13T00:00:00.000Z"

## Evidence
<!-- APPEND only - facts discovered -->

- timestamp: "2026-04-13T00:00:00.000Z"
  checked: "iOS/Runner/Info.plist"
  found: "Missing UIBackgroundModes key - required for background notification delivery via APNs"
  implication: "iOS won't deliver background/terminated notifications without this"

- timestamp: "2026-04-13T00:00:00.000Z"
  checked: "AndroidManifest.xml"
  found: "Missing FLUTTER_NOTIFICATION_CLICK intent filter for handling notification taps from background"
  implication: "Android may not properly receive notification tap events when app is terminated"

- timestamp: "2026-04-13T00:00:00.000Z"
  checked: "app_initializer.dart background handler"
  found: "Background handler correctly registered with @pragma('vm:entry-point') and initializes Firebase + NotificationManager"
  implication: "Handler setup is correct, platform config is the issue"

- timestamp: "2026-04-13T00:00:00.000Z"
  checked: "notification_manager.dart foreground handler"
  found: "FirebaseMessaging.onMessage correctly handles foreground messages (lines 371-380)"
  implication: "Foreground works because it doesn't rely on platform background delivery"

- timestamp: "2026-04-13T00:00:00.000Z"
  checked: "macOS/Runner/Info.plist"
  found: "Missing UIBackgroundModes for macOS FCM background delivery"
  implication: "macOS desktop app won't receive background notifications"

## Resolution
<!-- OVERWRITE as understanding evolves -->

root_cause: "iOS and macOS missing UIBackgroundModes configuration in Info.plist - without 'firebase-cloud-messaging' background mode, Apple platforms won't deliver notifications when app is backgrounded/terminated. Android needed intent filter for handling notification taps."
fix: "Added UIBackgroundModes with firebase-cloud-messaging to iOS/Runner/Info.plist and macOS/Runner/Info.plist. Added intent filter to Android AndroidManifest.xml."
verification: "Requires user to rebuild iOS/macOS apps and test: 1) Put app in background, 2) Send test FCM notification, 3) Verify notification appears via OS notification system"
files_changed: ["ios/Runner/Info.plist", "macos/Runner/Info.plist", "android/app/src/main/AndroidManifest.xml"]
