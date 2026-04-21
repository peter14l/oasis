# Debug Session: Call Sync Issues

## Context
**Slug:** call_sync_issues
**Goal:** find_and_fix

## Symptoms
- **Expected:** Proper calling setup like WhatsApp (realtime ring, background received, audio working).
- **Actual:** 
  1. Call doesn't appear for User B immediately; requires app restart.
  2. If app closed, calls don't come through. 
  3. When User B answers, User A's UI updates, but User B's UI stays stuck on "calling".
  4. Audio previously didn't work (no sound).
- **Errors:** No logs available (testing on release builds due to low RAM on dev machine).
- **Reproduction:** User A calls User B.
- **Timeline:** New feature, has never fully worked.
- **Tech Stack:** WebRTC, Supabase, FCM.

## Investigation Steps
1. **Background Notifications (FCM):** Check how FCM payloads map to ringing UI if app is closed.
2. **Realtime Signaling (Supabase):** Check why Supabase realtime updates require an app restart for B (potentially lack of active realtime listener or subscription caching).
3. **Answering Call UI State:** Check B's side when answering. Why doesn't B's UI update to "In Call" even though A receives the "Answered" signal? (Likely UI state not being set on resolving the peer connection local state).
4. **WebRTC Audio:** Check ICE candidate exchanges and making sure local/remote audio tracks are added to the WebRTC streams.
