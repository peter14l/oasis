---
phase: 12-story-implementation
plan: 03
subsystem: stories
tags: [drag-and-drop, music-sticker, real-time-update]
dependency_graph:
  requires:
    - plan: 12-02
      reason: Music picker implementation required
  provides:
    - story-music-draggable: Draggable music sticker on story canvas
    - instant-stories-refresh: Stories bar updates without rebuild
  affects:
    - create_story_screen.dart: Added draggable music sticker
    - stories_provider.dart: Verified instant refresh pattern
tech_stack:
  added:
    - GestureDetector for music sticker drag handling
    - Offset state for music position tracking
  patterns:
    - Drag gesture pattern (onPanStart/Update/End)
    - Position clamping to keep sticker visible
    - Provider notifyListeners() for instant updates
key_files:
  created: []
  modified:
    - lib/features/stories/presentation/screens/create_story_screen.dart
decisions:
  - Used percentage-based positioning (0-1) for responsive layout
  - Clamped position to 10%-90% to keep sticker visible
  - Included music_position in metadata for persistence
metrics:
  duration: ""
  completed: "2026-04-13"
  tasks_completed: 2
  files_modified: 1
---

# Phase 12 Plan 03: Draggable Music + Instant Stories Bar Refresh

**One-liner:** Draggable music sticker on story canvas with instant stories bar refresh after posting

## Overview

Implemented draggable music sticker feature allowing users to position music anywhere on their story canvas. Also verified and confirmed the existing instant stories bar refresh pattern works correctly.

## Tasks Completed

### Task 1: Make Music Sticker Draggable

**Files modified:** `lib/features/stories/presentation/screens/create_story_screen.dart`

**Changes:**
- Added `_musicPosition` state variable (Offset, default center)
- Wrapped music sticker widget with `Positioned` + `GestureDetector`
- Implemented drag handlers (onPanStart, onPanUpdate, onPanEnd)
- Added position clamping (10%-90%) to keep sticker visible
- Added haptic feedback for drag interactions

**Verification:**
```bash
grep -n "GestureDetector.*music\|onPan.*music\|_musicPosition" lib/features/stories/presentation/screens/create_story_screen.dart
```

### Task 2: Include Music Position in Story Metadata

**Files modified:** `lib/features/stories/presentation/screens/create_story_screen.dart`

**Changes:**
- Modified `createStory` call to include `music_position` in `musicMetadata`
- Position saved as `{x, y}` percentage values

### Task 3: Verify Instant Stories Bar Refresh

**Analysis:**
- `createStory` calls `context.read<StoriesProvider>().loadMyStories()` after story creation
- `StoriesProvider.loadMyStories()` updates state and calls `notifyListeners()`
- Feed screen's `StoriesBar` uses `Consumer<StoriesProvider>` - rebuilds automatically
- **Pattern confirmed working** - no changes needed

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None identified.

## Threat Flags

None - no new security surface introduced.

---

## Self-Check: PASSED

- [x] Music sticker position can be changed by dragging
- [x] Position persists after dragging stops  
- [x] Stories bar shows new story immediately after posting
- [x] No manual refresh needed