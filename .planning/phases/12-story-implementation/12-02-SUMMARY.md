---
phase: 12-story-implementation
plan: 02
subsystem: stories
tags: [music-picker, spotify, artwork-picker, M3E]
dependency_graph:
  requires: []
  provides:
    - path: lib/widgets/stories/music_picker_sheet.dart
      description: Music picker UI with search, featured tracks, artwork picker
    - path: lib/services/spotify_service.dart
      description: Spotify search and featured tracks API
  affects: [create_story_screen.dart]
tech_stack:
  added:
    - StoryMusicEntity.artworkStyle field
  patterns:
    - M3E theming (28dp border radius, 16dp container radius)
    - Scroll-based pagination (load more at 200px from bottom)
    - Artwork picker modal bottom sheet
key_files:
  created: []
  modified:
    - lib/features/stories/domain/models/story_entity.dart
    - lib/services/spotify_service.dart
    - lib/widgets/stories/music_picker_sheet.dart
decisions:
  - Added artworkStyle to StoryMusicEntity with default 'original'
  - Used horizontal scroll list for artwork picker options
  - Implemented load-more pattern with scroll listener
  - Added clear button to search when text present
metrics:
  duration: null
  completed_date: "2026-04-13"
  tasks_completed: 4
  files_modified: 3
---

# Phase 12 Plan 2: Music Picker Fix and Visual Overhaul

**One-liner:** Fixed music search functionality, added featured tracks display, implemented Spotify-like visual overhaul, and added artwork picker with 4 style options.

## Summary

Implemented fixes and enhancements to the music picker for story creation:

1. **Search Fix**: Music search now returns results - searches filter featured tracks when no Spotify API key, returns real API results when configured

2. **Featured Tracks**: Initial load displays 5 featured tracks (The Weeknd, Harry Styles, Taylor Swift, Miley Cyrus)

3. **Visual Overhaul**: Spotify-inspired design with M3E styling:
   - 28dp border radius (M3E Extra Large)
   - Larger album art (56dp)
   - Section headers showing "Featured" or "Results for X"
   - Song count indicator
   - Clear button in search field

4. **Draggable List**: Scroll-based pagination with load-more button at bottom

5. **Artwork Picker**: When user taps a track, shows modal with 4 artwork styles:
   - Original (square crop)
   - Blurred (wide background)
   - Circle (circular crop)
   - Full (full bleed)

## Deviations from Plan

**Auto-fixed Issues**

1. [Rule 1 - Bug] Added artworkStyle field to StoryMusicEntity
   - **Found during:** Task 1 analysis
   - **Issue:** No way to store user's artwork preference
   - **Fix:** Added artworkStyle field with serialization support
   - **Files modified:** story_entity.dart
   - **Commit:** 6ee7a04

## Verification

- [x] Initial load shows 5 featured tracks (not empty)
- [x] Search returns matching tracks from featured list
- [x] Music picker has M3E styling (28dp radius, larger album art)
- [x] Artwork picker shows 4 options after tapping track
- [x] Load more button appears for longer lists
- [x] Section headers display correctly
- [x] Clear button in search field works

## Files Modified

| File | Changes |
|------|---------|
| `story_entity.dart` | Added artworkStyle field to StoryMusicEntity |
| `spotify_service.dart` | Added artworkStyle to featured tracks and parsed tracks |
| `music_picker_sheet.dart` | Complete overhaul - search fix, featured tracks, artwork picker, M3E styling |

## Auth Gates

None - no authentication required for this feature.

## Known Stubs

None - all functionality implemented.

## Threat Flags

None - no security-relevant changes.

## Self-Check: PASSED

- [x] Files exist: story_entity.dart, spotify_service.dart, music_picker_sheet.dart
- [x] Commit exists: 6ee7a04
- [x] Implementation matches plan requirements