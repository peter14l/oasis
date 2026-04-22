---
status: investigating
trigger: "Investigate persistent call flow issues: instant pickup (Android -> Windows), rapid UI flickering (3-4 times), and \"Connecting\" hang."
created: 2025-01-24T12:35:00Z
updated: 2025-01-24T12:35:00Z
---

## Current Focus

hypothesis: There is a race condition or auto-answer logic in the Windows-specific code or signaling service that triggers before user interaction.
test: Examine signaling flow and platform-specific call handling in lib/services/signaling_service.dart and lib/screens/calling/calling_screen.dart.
expecting: Identify where the call is being automatically accepted or where multiple signaling updates are triggering UI rebuilds.
next_action: Search for "accept" or "answer" in signaling service and Windows-specific call handling.

## Symptoms

expected: Manual answer/decline, smooth transition to connected state.
actual: Android -> Windows still auto-answers. Rapid UI flickering on both devices. Stuck on "Connecting".
reproduction: Place call from Android to Windows.
started: Post removal of _autoAcceptCall in CallingScreen.

## Eliminated

- hypothesis: _autoAcceptCall in CallingScreen was the cause.
  evidence: User reports issue persists after its removal.
  timestamp: 2025-01-24T12:35:00Z

## Evidence

- timestamp: 2025-01-24T12:35:00Z
  checked: Initial symptoms.
  found: Windows still auto-answers calls from Android.
  implication: The auto-answer logic is likely deeper than the UI layer or exists in a parallel path (e.g., SignalingService).

## Resolution

root_cause: 
fix: 
verification: 
files_changed: []
