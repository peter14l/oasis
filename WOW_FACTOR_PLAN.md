# Wow Factor Implementation Plan

## 1. Wow Navigation Structure
**Goal:** Shift from a consumption-heavy (Feed/Ripples) to an intentional-first (Canvas/Vault) navigation model.

### Navigation Refactor (Tabs):
1. **Canvas (Index 0):** The hero feature. An infinite spatial universe for co-creation.
2. **Vault (Index 1):** Time Capsules and permanent memories.
3. **Wellness (Index 2):** Mood Rooms and collective presence.
4. **Messages (Index 3):** E2EE Communication.
5. **Profile/Settings (Index 4/5):** Personal space.

### Technical Tasks:
- [ ] Update `MainLayout._getCurrentIndex` in `lib/routes/app_router.dart`.
- [ ] Update `MainLayout._buildBottomNavigationBar` and `_buildNavigationRail`.
- [ ] Update `MainLayout._onDestinationSelected` for routing.
- [ ] Update `NavigationShell` in `lib/routes/navigation_shell.dart`.

---

## 2. Ghost Presence (Real-time Pointers)
**Goal:** Create a sense of synchronous connection on the shared Canvas.

### Features:
- **Ghost Pointers:** Translucent glowing orbs showing where other users are touching.
- **Synchronized Haptics:** Vibrate when pointers overlap.
- **Star Flare:** Background stars flare up when users are close to each other.

### Technical Tasks:
- [ ] **Presence Layer:** Create a Supabase Realtime channel for spatial coordinates.
- [ ] **Broadcasting:** Hook into `GestureDetector` in `InfiniteCanvas` to broadcast local coordinates.
- [ ] **Rendering:** Create `GhostPresencePainter` to render incoming pointer data as fading glows.
- [ ] **Optimization:** Throttle broadcast updates (e.g., 30-60ms) to avoid IOPS spikes.

---

## 3. TBD Features ( Skeptical - Documented for Future)
*These are documented for future consideration and will not be implemented in this phase.*

### TBD-01: Constellation Builder
Automatically connect items with star-lines when users interact with them simultaneously.

### TBD-02: Spatial Voice Bubbles
Audio notes that have spatial volume based on the user's viewport on the Canvas.

### TBD-03: Joint Rituals
A "Synchronize" button for collaborative breathing exercises with shared haptics.

### TBD-04: Interactive Spoilers
Memories that unlock only after specific group tasks or presence milestones.
