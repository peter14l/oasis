# GSD Debug Knowledge Base

Resolved debug sessions. Used by `gsd-debugger` to surface known-pattern hypotheses at the start of new investigations.

---

## instant-call-pickup-connecting-loop — Instant call pickup when receiving a call
- **Date:** 2024-05-16
- **Error patterns:** instant pickup, auto-accept, CallingScreen, connecting loop
- **Root cause:** `CallingScreen` was explicitly designed to auto-accept incoming calls in `initState` if `isIncoming` was true and a `callId` was provided.
- **Fix:** Removed `_autoAcceptCall` method and its invocation from `initState`. Refactored the UI to show the manual Accept/Decline buttons. Added a 10s timeout for initial call data arrival.
- **Files changed:** lib/features/calling/presentation/screens/calling_screen.dart
---
