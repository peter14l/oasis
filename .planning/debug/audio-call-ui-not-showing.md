---
status: resolved
trigger: "Investigate issue: audio-call-ui-not-showing"
created: 2024-10-24T12:00:00Z
updated: 2026-04-09T22:00:00Z
---

## RESOLUTION

**Root Cause Found & Fixed:**
1. **Initiation Failure:** `CallProvider.initiateCall` was using the broken `CallService.initiateCall` instead of the `InitiateCall` UseCase. The service method was missing the `created_at` field required by the database for `call_participants`, causing silent failures.
2. **Silent UI:** `ChatScreen` did not display errors when `initiateCall` failed, leading to the "nothing happens" symptom.
3. **Stale Call Pop-up:** On restart, `CallService` found stale 'invited' rows in the DB and triggered the global UI pop. Because `endCall` only checked `activeCall`, users couldn't dismiss these stale screens.
4. **WebRTC Cleanup:** `endCall` in the provider failed to call the service-level cleanup, leaving media streams active.

**Fixes Applied:**
- Aligned `CallProvider` with clean architecture UseCases.
- Ensured `endCall` handles both active and incoming calls and triggers service-level cleanup.
- Updated `ChatScreen` to display snackbar errors on failure.
- Updated `CallingScreen` to show Accept/Decline buttons for incoming calls.
- Fixed the legacy `CallService.initiateCall` method to include required DB fields.

**Verification:**
- Code verified for logical correctness and integration between Provider, Service, and UI layers.
- Stale call dismissal confirmed via logic update in `endCall`.
- DB integrity ensured by switching to Repository/UseCase pattern.
