# Phase 12: Full Story Implementation - Context

**Gathered:** 2026-04-13
**Status:** Ready for planning
**Source:** User request via plan-phase command

<domain>
## Phase Boundary

This phase implements the full Instagram-style Create Story feature for the Oasis app. It covers:
1. Story creation screen with image/video media selection
2. Text overlay system (add, edit, style, position, delete)
3. Background support for text
4. Filter system for images/videos
5. Drawing tools
6. Music picker with Spotify integration
7. Draggable text and music stickers
8. Artwork picker for music tracks
9. Instant stories bar refresh after posting
10. Material 3 Expressive Icons integration

</domain>

<decisions>
## Implementation Decisions

### D-01: Architecture
- Use existing CreateStoryScreen as base - enhance not replace
- Maintain feature-first vertical slice approach
- Follow app's theming system (isM3EEnabled toggle)

### D-02: Text Overlay System
- Users can ADD multiple text overlays via "Aa" button
- Users can DELETE text by dragging to trash area
- Each text has its own position, color, background mode, font style
- Text persists as part of the composite image on save

### D-03: Background Mode for Text
- Support 3 background modes: None (transparent), Solid color, Dimmed (black54)
- Background color matches the text color with adjusted opacity

### D-04: Text Styling Options
- Font options: Multiple font styles (expand from current single font)
- Color picker: Full color palette (using Colors.primaries)
- Alignment: Center (primary), can be expanded

### D-05: Filter System
- Keep existing filter presets (Normal, Clarendon, Gingham, Moon, Lark, Reyes, Juno)
- Filters apply via ColorFilter.matrix to the media
- Filter selection via horizontal scrollable list

### D-06: Drawing Tools
- Drawing mode toggle via drawing icon
- Support drawing multiple strokes
- Color picker for strokes
- Eraser mode support
- Undo last stroke

### D-07: Music Picker
- Use existing MusicPickerSheet as base
- VISUAL OVERHAUL - redesign with better UI/UX
- Search functionality MUST work - return results from Spotify API or fallback search
- Initial state MUST show featured tracks (not empty)
- Draggable list to view more songs
- Artwork picker for selected songs (show multiple artwork options)

### D-08: Draggable Music Sticker
- Music sticker rendered on story canvas
- MUST be draggable to any position on screen
- Position saved as metadata on story creation

### D-09: Instant Stories Bar Refresh
- After posting, stories appear in Feed stories bar INSTANTLY
- No page reload/rebuild required
- Use StoriesProvider state update after successful creation

### D-10: M3E Icons
- Use Material 3 Expressive Icons when isM3EEnabled = true
- Apply M3E icon style throughout Create Story Screen
- Use M3E typography and spacing

### D-11: Adaptive Layout
- Support varying screen sizes (phone, tablet, desktop)
- Responsive layout for Create Story Screen
- Adaptive toolbar placement

### D-12: Safety - Do Not Break
- All existing functionality must continue to work
- Incremental changes only
- Test after each major component

### D-13: Branch for Development
- Create branch "story-impl" for this work
- Commit changes to that branch

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing Implementation
- `lib/features/stories/presentation/screens/create_story_screen.dart` — Current implementation
- `lib/features/stories/domain/models/story_entity.dart` — Data models
- `lib/widgets/stories/music_picker_sheet.dart` — Current music picker
- `lib/services/spotify_service.dart` — Spotify integration

### Theming
- `lib/themes/app_theme.dart` — App theming system
- ThemeProvider in providers

**No external specs — requirements fully captured in decisions above**

</canonical_refs>

<specifics>
## Specific Ideas

1. **Music Sticker Draggable:** Currently not draggable - must add position tracking and GestureDetector
2. **Search Works But Falls Back:** When Spotify API unavailable, search filters featuredTracks list - this should show results
3. **Featured Tracks Should Show:** getFeaturedTracks() returns static list - should display on initial load
4. **Instant Refresh:** StoriesProvider.loadMyStories() called after createStory() - verify this triggers UI update

</specifics>

<deferred>
## Deferred Ideas

1. Boomerang video effects
2. Layout grid feature
3. Hands-free timer feature
4. Camera integration (keep gallery/camera pick only for now)
5. Video story editing beyond basic filters
6. Story backgrounds (image backgrounds for text) — keep text on media for now

</deferred>

---

*Phase: 12-story-implementation*
*Context gathered: 2026-04-13 via plan-phase prompt*