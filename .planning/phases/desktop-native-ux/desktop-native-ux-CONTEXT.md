# Desktop Native UX Implementation Context

## Phase Goal
Make desktop apps feel native by replacing mobile-first patterns with desktop-native equivalents, without breaking phone UI.

## User Requirements
1. Context menus instead of modal sheets
2. Right-click instead of tap-and-hold
3. Proper desktop navigation
4. Fix duplicate components
5. DO NOT touch phone UI
6. Don't break anything
7. 4-day deadline

## Key Constraints
- **Preserve mobile UI completely** - all mobile interactions must remain unchanged
- **No essential components/code removed** - only refactor, don't delete functionality
- **Backward compatible** - desktop detection must be reliable

## Desktop Detection Strategy
Use existing `ResponsiveLayout.isDesktop(context)` which checks for width >= 1200px

## Implementation Priority

### Phase 1: Core Infrastructure
1. Create DesktopContextMenu widget (replaces showModalBottomSheet on desktop)
2. Add SecondaryTapHandler widget (right-click support)
3. Update gesture utilities for desktop

### Phase 2: Feed & Posts
1. Replace showModalBottomSheet in feed screen with inline panel or Dialog
2. Add right-click context menu for post cards
3. Ensure desktop sidebar remains functional

### Phase 3: Messages
1. Replace message options bottom sheet with context menu
2. Add right-click for message actions (reply, forward, copy, etc.)
3. Inline message details panel for desktop

### Phase 4: Navigation Enhancements
1. Improve NavigationRail appearance
2. Add proper desktop keyboard shortcuts
3. Optimize navigation for desktop UX

### Phase 5: Cleanup
1. Remove/comment legacy duplicate screens
2. Verify no mobile breakpoints

## Technical Approach
- Platform detection: `ResponsiveLayout.isDesktop(context)` 
- No kIsWeb - Flutter desktop uses same code
- All changes should be additive with platform checks

## Success Criteria
- Desktop: right-click works, context menus appear, no bottom sheets
- Mobile: unchanged behavior - same tap-hold, same bottom sheets
- Both platforms function correctly