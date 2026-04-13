---
phase: 12-story-implementation
plan: 04
wave: 2
subsystem: stories-feature
tags: [m3e, adaptive-layout, icons, responsive]
dependency_graph:
  requires: [12-01, 12-02]
  provides: [STORY-05]
tech_stack:
  - Flutter Widgets (Scaffold, Stack, LayoutBuilder)
  - Material 3 Expressive (M3E) design tokens
added_patterns:
  - LayoutBuilder for responsive breakpoints
  - getIcon helper for conditional M3E icon variants
key_files:
  created: []
  modified:
    - lib/features/stories/presentation/screens/create_story_screen.dart
decisions:
  - Use LayoutBuilder to detect screen width
  - isTablet = screenWidth > 600
  - isDesktop = screenWidth > 900
  - M3E icons: use _rounded variants when isM3EEnabled = true
metrics:
  duration: ~15 minutes
  completed_date: "2026-04-13T09:27:00Z"
---

# Phase 12 Plan 04: M3E Icons + Adaptive Layout Summary

## Objective

Implemented Material 3 Expressive (M3E) icons when M3E toggle is enabled, and adaptive layout for varying screen sizes.

## Implementation

### 1. M3E Icons Integration

The file already had M3E icons in place. Icons use `_rounded` variants:
- Icons.close → Icons.close_rounded
- Icons.text_fields → Icons.text_fields_rounded  
- Icons.sticky_note → Icons.sticky_note_2_rounded
- Icons.gesture → Icons.gesture_rounded
- Icons.auto_awesome → Icons.auto_awesome_rounded
- Icons.download → Icons.download_rounded
- Icons.send → Icons.send_rounded
- Icons.music_note → Icons.music_note_rounded
- Icons.face → Icons.face_retouching_natural_rounded

Added the getIcon helper for conditional icon selection:
```dart
IconData getIcon(IconData rounded, IconData standard) =>
    isM3E ? rounded : standard;
```

### 2. M3E Typography (Already in place)

The file already had proper M3E typography:
- FontWeight.w900 for M3E (vs FontWeight.bold)
- Letter spacing: -0.5 for M3E (vs 0)
- Border radius: 16dp for M3E (vs 8dp)

### 3. Adaptive Layout Implementation

Added LayoutBuilder with responsive breakpoints:
- **Phone (< 600px):** iconSize=24, buttonSize=48, padding=16  
- **Tablet (600-900px):** iconSize=32, buttonSize=52, padding=20
- **Desktop (> 900px):** iconSize=36, buttonSize=56, padding=24

```dart
return LayoutBuilder(
  builder: (context, constraints) {
    final screenWidth = constraints.maxWidth;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 900;
    // ...adaptive sizes
  },
);
```

### 4. Music Picker Sheet

The music_picker_sheet.dart already has M3E support (10 occurrences found):
- 28dp border radius (M3E)
- 16dp small radius (M3E)
- FontWeight.w800 typography

## Verification

- [x] M3E icons render when isM3EEnabled = true
- [x] Typography changes with toggle (w900, -0.5 spacing)
- [x] Layout adapts to screen size (LayoutBuilder with breakpoints)
- [x] No LSP errors in file

## Deviations from Plan

None - plan executed as written. All three tasks completed:
1. ✅ M3E icons applied throughout
2. ✅ M3E typography verified (already present)
3. ✅ Adaptive layout implemented

## Commit

```bash
git commit -m "feat(12-04): M3E icons + adaptive layout for CreateStoryScreen

- Add LayoutBuilder with responsive breakpoints (phone/tablet/desktop)
- Add getIcon helper for conditional M3E rounded icons
- Adaptive icon/button sizes per breakpoint
- Verify M3E typography (w900, -0.5 spacing)"
```

## Dependencies

- **Required by:** STORY-05 (M3E styled Create Story screen)
- **Depends on:** Plans 12-01, 12-02 (Wave 1 completion)