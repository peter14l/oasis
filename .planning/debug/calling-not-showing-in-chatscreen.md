status: verifying
trigger: "Investigate issue: calling-not-showing-in-chatscreen"
created: 2025-01-24T14:00:00Z
updated: 2025-01-24T17:30:00Z
---

## Current Focus

hypothesis: The navigation handler in `MaterialApp.builder` was failing because 1) it used an unreliable method to detect the current location, 2) it used `push` instead of `pushNamed` which might be less robust for parameters, and 3) `CallProvider` had bugs in state management (especially clearing 'activeCall').
test: 1) Refined location detection using `GoRouter.of(context)` with fallback to the singleton router. 2) Switched to `pushNamed` with explicit `pathParameters`. 3) Fixed `CallProvider.copyWith` and synced `activeCall` with `CallService.currentCallId`. 4) Exposed `AppRouter` navigator keys for reliable context access.
expecting: The call UI to reliably show up when a call is initiated and dismiss when it ends.
next_action: Await human verification.

## Symptoms

expected: It should open a calling screen which should display the recipient's pfp, username, show "Calling" and the other call control buttons.
actual: Nothing happens. For voice calls, nothing happens even though mic permission is given. For video calls, the video permission remains active, but there's no change in the UI/screens. I still remain in the chat screen.
errors: NO error messages. WebRTC logs confirm camera is active, meaning logic completes but navigation fails.
reproduction: Click call/video button in chat screen.
started: Never worked.

## Eliminated

- hypothesis: CallProvider not notifying listeners.
  evidence: Consumer2 in main.dart is correctly set up, and provider calls notifyListeners. User logs confirm WebRTC initializes, meaning initiateCall completes.
- hypothesis: ChatScreen not calling initiateCall.
  evidence: Code inspection confirms it calls callProvider.initiateCall.

## Evidence

- timestamp: 2025-01-24T14:15:00Z
  checked: `ChatScreen._initiateCall`
  found: It calls `callProvider.initiateCall` but does NOT navigate.
  implication: Relies on `MainLayout` or a global handler to handle navigation via `CallProvider` state changes.
- timestamp: 2025-01-24T14:20:00Z
  checked: `AppRouter` and `MainLayout`
  found: `MainLayout` was severely corrupted (fixed in previous turn).
- timestamp: 2025-01-24T15:00:00Z
  checked: `AppRouter` shell route configuration
  found: On mobile, `ChatScreen` is pushed to `_rootNavigatorKey`. 
  implication: Navigating to a root route removes the `ShellRoute` (and `MainLayout`) from the widget tree, disabling its navigation handler.
- timestamp: 2025-01-24T15:15:00Z
  checked: `CallService` logs from user
  found: `FlutterWebRTCPlugin` audio focus changes.
  implication: `CallService.initiateCall` IS being called and WebRTC is initializing, confirming the provider logic is working, but navigation is the missing link.
- timestamp: 2025-01-24T16:10:00Z
  checked: `CallProvider.copyWith`
  found: It was impossible to clear `incomingCall` or `activeCall` because the `copyWith` method always defaulted to the existing value if null was passed.
  implication: Could lead to inconsistent state where an old call persists in the provider.
- timestamp: 2025-01-24T16:20:00Z
  checked: `lib/main.dart` navigation logic
  found: It was using `AppRouter.router.routerDelegate.currentConfiguration.uri.path` which might not be updated or reliable in all contexts within `builder`. It also didn't use the root navigator's context.
- timestamp: 2025-01-24T17:15:00Z
  checked: `CallProvider` endCall logic
  found: It was passing `activeCall: null` to `copyWith`, which due to the `?? this.activeCall` bug, didn't actually clear it.
  implication: Confirmed state management bugs in `CallProvider`.

## Resolution

root_cause: 1) `MainLayout` (previous location of navigation handler) is unmounted on mobile when in `ChatScreen`. 2) `CallProvider` state management was buggy, preventing clearing of call state and sync with `CallService`. 3) Navigation handler in `MaterialApp.builder` used unreliable location detection and navigator context.
fix: 1) Fixed `CallProvider` state management and synced `activeCall` with `CallService.currentCallId`. 2) Moved navigation handler to `MaterialApp.builder` with robust location check and use of root navigator context. 3) Exposed navigator keys in `AppRouter`. 4) Switched to `pushNamed` for navigation.
verification: 
files_changed: [lib/features/calling/presentation/providers/call_provider.dart, lib/routes/app_router.dart, lib/main.dart, lib/features/calling/presentation/screens/calling_screen.dart]
