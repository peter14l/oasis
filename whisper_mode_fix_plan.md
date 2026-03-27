# Whisper Mode Fix & Completion Plan

## Background & Motivation
Whisper Mode (also known as Vanish Mode) is a feature where messages disappear after being read. Currently, the implementation is inconsistent and partially broken across the SQL, Service, and UI layers.

### Key Issues Identified:
1.  **Broken Database Deletion**: The SQL function `cleanup_vanish_mode_messages` in `COMPLETE_MASTER_SCHEMA.sql` deletes ALL ephemeral messages immediately when called, ignoring the 24h timer (`ephemeral_duration = 86400`).
2.  **Missing Client-Side Expiration**: The client (`MessagingService.filterExpiredMessages`) expects an `expires_at` timestamp from the database. However, the trigger that set this timestamp was removed in `COMPLETE_MASTER_SCHEMA.sql`. The client does not calculate expiration locally from read receipts.
3.  **RPC Name Mismatch**: `MessagingService.dart` attempts to call an RPC named `cleanup_expired_messages`, but the database function is actually named `cleanup_vanish_mode_messages`.
4.  **No Session Persistence for Instant Messages**: The intended "Keep visible during session" logic is ineffective because the database may delete the messages before the session ends if another participant's client triggers the cleanup.
5.  **Inconsistent Mode Logic**: The "pull-up" gesture in `ChatScreen` only toggles between `Off (0)` and `Instant (1)`, making it impossible to enable `24h (2)` mode without going into settings. It also disables Whisper Mode if it was in `24h` mode.
6.  **Missing Screenshot Protection**: Whisper Mode does not currently activate `ScreenProtector` for the entire chat screen, leaving sensitive conversations vulnerable.

---

## Proposed Solution

### 1. Database Layer (Supabase/SQL)
*   **Fix `cleanup_vanish_mode_messages`**: Update the SQL function to respect `ephemeral_duration`. It should only delete messages if they have been read AND the current time is past `read_at + ephemeral_duration`.
*   **Re-introduce `expires_at` Calculation**: While "Instagram-style" cleanup on open/close is the preferred approach for V4, setting `expires_at` in the database provides a clear source of truth for all clients. We should re-add a trigger to `message_read_receipts` that updates `messages.expires_at`.

### 2. Service Layer (Logic)
*   **Fix RPC Calls**: Update `MessagingService.cleanupVanishModeMessages` to use the correct RPC name (`cleanup_vanish_mode_messages`).
*   **Dynamic Expiration Calculation**: Update `MessagingService.filterExpiredMessages` to calculate expiration locally using `anyReadAt + ephemeral_duration` if `expiresAt` is null but the message is ephemeral and has been read.
*   **Consolidate Whisper Modes**: Ensure all services and models consistently use the `0 (Off), 1 (Instant), 2 (24h)` enum/int values.

### 3. UI Layer (Screens/Widgets)
*   **Screenshot Protection**: In `ChatScreen`, if `_isWhisperMode > 0`, activate `ScreenProtector.preventScreenshotOn()`. Deactivate it on `dispose` or when Whisper Mode is turned off.
*   **Pull-up Gesture Enhancement**: Update the gesture to cycle through modes or toggle between "Off" and the "Last Active" whisper mode.
*   **System Messages**: When Whisper Mode is toggled, insert a local (and potentially remote) "System Message" so participants can see exactly where the secret conversation began.
*   **Session Persistence**: Update `ChatScreen` to better respect the "Seen this session" logic, perhaps by delaying the cleanup call or marking messages as "Pending Deletion" locally.

---

## Implementation Plan

### Phase 1: Database & RPC Fixes
1.  Apply updated SQL for `cleanup_vanish_mode_messages`.
2.  Re-add the `set_message_expiration` trigger function to `message_read_receipts`.

### Phase 2: Service Layer Updates
1.  Update `lib/services/messaging_service.dart` to use correct RPC names.
2.  Enhance `filterExpiredMessages` logic for local calculation.
3.  Ensure `markAsRead` properly triggers the database updates needed for expiration.

### Phase 3: UI Enhancements
1.  Integrate `ScreenProtector` into `ChatScreen`.
2.  Refine the pull-up gesture logic and visual feedback.
3.  Implement the info message/system message logic for mode toggles.

### Phase 4: Verification
1.  Test Instant Vanish (0s).
2.  Test Timed Vanish (24h).
3.  Verify synchronization across multiple devices.
4.  Confirm screenshot protection is active in Whisper Mode.

---

## Verification Steps
1.  **Instant Vanish**: Send a message with Whisper Mode (Instant). Recipient reads it. Message should stay visible until current chat session ends (on both sides), then vanish from DB and UI on next open.
2.  **24h Vanish**: Send a message with 24h Vanish. Recipient reads it. Message should remain visible for exactly 24 hours after being read, then vanish.
3.  **Synchronization**: Toggle Whisper Mode on Device A. Device B should show a snackbar and update its UI (input hint, info message) instantly via Realtime.
4.  **Screenshot Protection**: Enable Whisper Mode. Try to take a screenshot or record the screen. It should be blocked (on Android/iOS).
