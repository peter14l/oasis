# Study Sessions: Feature Planning & Implementation Guide

## 1. Feature Overview
"Study Sessions" (or "Focus Rooms") is a productivity and wellness feature designed to help users concentrate on their tasks while connected with their community. It leverages the existing `StudySessionService` backend to allow users to create, join, and complete timed focus sessions, rewarding them with XP for successful completion.

## 2. Current Backend State (from `StudySessionService`)
The backend is already implemented and supports:
*   **Session Creation:** `createSession(title, durationMinutes, isLockedIn)`
*   **Joining Sessions:** `joinSession(sessionId)`
*   **Completing Sessions:** `completeSession(sessionId, xpEarned)`
*   **XP Rewards:** Increments user XP in the `profiles` table via Supabase RPC.
*   **Lock-in Mode:** A boolean flag (`is_locked_in`) indicating a strict focus mode.

## 3. Proposed UI/UX Architecture

To integrate seamlessly with the Oasis app's aesthetic (glassmorphism, Fluent/M3E support, wellness focus), we propose the following screens and components:

### A. The "Focus Hub" (Main Dashboard)
*   **Location:** Accessible via a new tab in the main navigation or prominently featured within the `WellnessCenterScreen`.
*   **Components:**
    *   **Active Sessions List:** A masonry grid or horizontal scroll of currently active study sessions created by friends or community members.
    *   **"Start New Session" FAB:** A prominent floating action button to create a new session.
    *   **Weekly Stats Widget:** Shows total focus time and XP earned this week.

### B. Session Creation Modal (`CreateStudySessionSheet`)
*   **Inputs:**
    *   `Title`: TextField (e.g., "Deep Work: Coding", "Reading Group").
    *   `Duration`: Slider or preset chips (15m, 30m, 45m, 60m).
    *   `Lock-in Mode`: Toggle switch. If enabled, exiting the app or screen penalizes the user (ties into `DigitalWellbeingService`).
*   **Action:** Calls `StudySessionService.createSession()`.

### C. Active Session Room (`ActiveStudySessionScreen`)
*   **Visuals:** Immersive, distraction-free UI. Dark theme, minimal UI elements. Optional "Starry Night" or "Living Canvas" animated backgrounds to induce calm.
*   **Components:**
    *   **Giant Timer:** Centered countdown timer.
    *   **Participant Avatars:** Small floating avatars of others in the same session (synced via Supabase Realtime).
    *   **Leave/Give Up Button:** Prompts a warning about losing potential XP or incurring a penalty.
*   **Lock-in Enforcement:** If `is_locked_in` is true, use `PopScope` to prevent accidental back navigation and tie into `WidgetsBindingObserver` to detect if the app goes to the background.

### D. Session Completion Screen
*   **Visuals:** Celebratory animation (confetti/glow).
*   **Data:** Shows time focused and XP earned.
*   **Action:** Calls `StudySessionService.completeSession()` and routes back to the Hub.

## 4. Implementation Phases

### Phase 1: Core UI & Solo Sessions
1.  **Create UI Scaffold:** Build the `StudySessionsHubScreen` and add navigation routing in `app_router.dart`.
2.  **Creation Flow:** Implement the `CreateStudySessionSheet` and wire it to the backend.
3.  **Active Room (Solo):** Build the `ActiveStudySessionScreen` with a working local timer.
4.  **Completion Logic:** Wire up the timer completion to trigger `completeSession` and award XP.

### Phase 2: Multiplayer & Realtime
1.  **Fetch Active Sessions:** Update the Hub to query and display ongoing sessions from the database.
2.  **Join Flow:** Wire up the `joinSession` backend method.
3.  **Realtime Presence:** Use Supabase Realtime (similar to `CanvasRemoteDatasource.subscribeToPresence`) to show live avatars of participants in the `ActiveStudySessionScreen`.

### Phase 3: "Lock-in" & Wellness Integration
1.  **Strict Mode:** Implement the logic for `is_locked_in`. If a user backgrounds the app during a locked-in session, automatically fail the session or deduct XP (using the existing `_zenPenaltyXP` logic from `WellnessService`).
2.  **Notification Suppression:** Integrate with `NotificationManager.instance.setPaused(true)` during active locked-in sessions.
3.  **Dopamine Detox Tie-in:** Optionally apply the `GrayscaleDetox` filter automatically while a study session is active to prevent distractions if the user tries to navigate away.

## 5. Required Dependencies / State Management
*   Create a `StudySessionProvider` to manage local timer state, active participants, and handle the interaction with `StudySessionService`.
*   Inject `StudySessionProvider` into `AppInitializer`.