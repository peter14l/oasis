# Calling V2 Architecture Plan

## Background & Motivation
The current calling implementation (V1) has several critical flaws:
1. **Database Bloat & Flickering:** Using Postgres tables for high-frequency WebRTC ICE candidates causes rapid-fire DB events, leading to UI flickering and race conditions.
2. **State Machine Confusion:** The separation of `calls`, `call_participants`, and `call_signaling` has led to desynced states, where the UI thinks the call is active while WebRTC is still negotiating (the "Connecting" hang).
3. **Dangerous Schema Linkages:** The `messages` table had a foreign key to `calls` that caused a disastrous cascade deletion.
4. **Auto-Answer Race Conditions:** Due to rapid stream replays, the recipient UI gets trapped in loops, repeatedly answering the same call.

## Objective
Completely tear down the V1 calling infrastructure and rebuild a robust, simplified V2 architecture. 

## Proposed Solution (Phased Implementation)

### Phase 1: Clean Slate & Schema Overhaul
*   **Database Cleanup:** Safely drop the `call_id` foreign key from the `messages` table to prevent future cascade issues. Drop the old `call_signaling`, `call_participants`, and `calls` tables.
*   **Simplified Schema:** 
    *   Recreate the `calls` table with a strict state machine (`ringing`, `active`, `ended`, `declined`, `missed`).
    *   Store the WebRTC `offer` and `answer` directly on the `calls` table to ensure atomic state transitions (no race conditions).
    *   *Crucial Change:* We will **NOT** create a `call_signaling` table. All ICE candidates will be sent via **Supabase Realtime Broadcast** (ephemeral messages).

### Phase 2: Ephemeral Signaling Layer
*   **Broadcast Channels:** Update `CallService` to use Supabase Broadcast for exchanging ICE candidates. This bypasses the Postgres database entirely, reducing latency from ~500ms to ~50ms and completely eliminating DB bloat and UI build loops.
*   **Handshake Flow:**
    1. Caller creates a `calls` row with `status = 'ringing'` and the `offer`.
    2. Recipient receives a DB update, shows the "Answer/Decline" UI.
    3. Recipient clicks Answer, updates the `calls` row with their `answer` and `status = 'active'`.
    4. Both sides immediately switch to Broadcast channels to trade ICE candidates and connect.

### Phase 3: The State Machine (CallProvider)
*   **Strict States:** Rewrite `CallProvider` to use a sealed class or enum for its state (e.g., `Idle`, `Incoming`, `Outgoing`, `InCall`). It will ignore any Supabase events that do not match its current expected state, permanently fixing the "auto-answer" and "loop" bugs.
*   **Call Timeout:** Implement a robust 30-second ringing timeout. If no answer is received, the caller updates the DB to `missed` and hangs up.

### Phase 4: UI Refinement
*   **Calling Screens:** Re-implement `CallingScreen` as a pure consumer of the `CallProvider` state.
*   **Hardware Management:** Ensure cameras and microphones are correctly requested, initialized, and released upon call termination.

## Migration & Rollback
Since this is a complete tear-down of a broken feature, there is no data migration for existing calls. All existing call history will be dropped (as was already attempted), and the system will start fresh.

## Verification
*   **E2E Testing:** Verify Android-to-Windows, Android-to-Android, and Windows-to-Windows flows.
*   **Network Resilience:** Test the Broadcast fallback mechanisms.
*   **State Consistency:** Ensure hanging up immediately tears down the WebRTC connection and returns the UI to normal.