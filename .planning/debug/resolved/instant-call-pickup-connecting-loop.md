---
status: resolved
trigger: "Investigate issue: instant-call-pickup-connecting-loop"
created: 2024-05-16T10:00:00Z
updated: 2024-05-16T10:35:00Z
---

## Current Focus

hypothesis: `CallingScreen` contains an `_autoAcceptCall` method that is triggered when `isIncoming` is true, causing calls to be accepted without user interaction.
test: Remove `_autoAcceptCall` and associated logic in `lib/features/calling/presentation/screens/calling_screen.dart`, ensuring manual answer/decline flow is preserved.
expecting: The call will no longer be auto-accepted, and the Answer/Decline UI will be shown.
next_action: Session resolved.

## Symptoms

expected: The recipient should see an Answer/Decline screen and the call should only connect after answering.
actual: Call instantly transitions to a connected/connecting state on both ends without user interaction.
errors: No specific error codes, but 'call_error.jpg' shows a failure state and the UI gets stuck on 'Connecting'.
reproduction: Place a call from Android to Windows (or any device) starting from lib/features/messages/presentation/screens/chat_screen.dart.
started: Never fully worked, but the Answer/Decline screen used to appear until about 2-3 commits ago.

## Eliminated

## Evidence

- timestamp: 2024-05-16T10:15:00Z
  checked: `lib/features/calling/presentation/screens/calling_screen.dart`
  found: `_CallingScreenState` has an `initState` that calls `_autoAcceptCall()` if `widget.isIncoming` is true.
  implication: This is the direct cause of the instant pickup.
- timestamp: 2024-05-16T10:16:00Z
  checked: `lib/services/desktop_call_notifier.dart`
  found: `_navigateToCallScreen` pushes `active_call` with `isIncoming: true` as soon as an incoming call is detected.
  implication: On desktop platforms, any incoming call will trigger the auto-navigation and subsequent auto-acceptance.
- timestamp: 2024-05-16T10:25:00Z
  checked: Manual Accept/Decline flow
  found: `_buildControlBar` in `CallingScreen` correctly handles `provider.acceptCall` and `provider.declineCall` when `provider.hasIncomingCall` is true.
  implication: Removing auto-accept will reveal these buttons to the user.

## Resolution

root_cause: `CallingScreen` was explicitly designed to auto-accept incoming calls in `initState` if `isIncoming` was true and a `callId` was provided.
fix: Removed `_autoAcceptCall` method and its invocation from `initState`. Refactored the UI to show the manual Accept/Decline buttons. Added a 10s timeout for initial call data arrival to prevent the screen from hanging if Realtime fails.
verification: Manual code review confirms that the auto-acceptance logic is gone and the conditional UI for Accept/Decline will be shown when the call data arrives.
files_changed: [lib/features/calling/presentation/screens/calling_screen.dart]
