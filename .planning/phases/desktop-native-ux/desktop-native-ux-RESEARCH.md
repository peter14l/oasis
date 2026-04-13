# Desktop Native UX Research

## Analysis Complete: 2026-04-13

## Research Findings

### 1. Platform Detection
- **Existing:** `ResponsiveLayout.isDesktop(context)` - checks width >= 1200px
- **Status:** Already implemented and used throughout codebase
- **Conclusion:** No new detection needed

### 2. Navigation Infrastructure
- **NavigationRail** exists in `lib/routes/navigation_shell.dart`
- **Status:** Functional but minimal - could be enhanced
- **Conclusion:** Base exists, enhancement is optional

### 3. Files with Mobile Patterns (Critical)

#### Bottom Sheets (36 files) - Priority High
Key files needing context menu replacement:
- `feed_screen.dart` - Ripples entry
- `post_card.dart` - Post actions
- `message_options_menu.dart` / `message_options_sheet.dart` - Message actions
- `comments_modal.dart` - Comments
- `share_sheet.dart` - Sharing when clicking share button

#### Long Press (15 files) - Priority High
Key files needing right-click:
- `post_card.dart` - Long press for options
- `chat_message_list.dart` - Long press for message options
- `canvas_item_widget.dart` - Canvas item actions
- `story_reply_bubble.dart`, `ripple_share_bubble.dart`, `post_share_bubble.dart` - Share bubbles

### 4. Duplicate Screens Found
- `lib/screens/feed_screen.dart` - COMPLETELY COMMENTED OUT - candidate for deletion
- Potential duplicates in `lib/screens/messages/` vs `lib/features/messages/presentation/screens/`

### 5. Desktop-Specific Code Already Present
- `DesktopHeader` widget for desktop headers
- Side comment panes for desktop (in feed_screen.dart)
- ResponsiveBuilder in responsive_layout.dart
- Desktop detection throughout

## Recommendations

### Must Have (4-day deadline)
1. Create DesktopContextMenu widget (replace showModalBottomSheet on desktop)
2. Add right-click support (SecondaryTapHandler)
3. Update high-impact widgets: post_card, message_options_menu
4. Verify NavigationRail is fully functional

### Should Have (if time permits)
1. Improve NavigationRail styling
2. Keyboard shortcuts for desktop
3. Desktop-optimized dialogs

### Can Skip (deadline pressure)
1. Extensive widget cleanup
2. Legacy screen deletion
3. Navigation enhancement

## Implementation Strategy
All changes should be PLATFORM-AWARE (additive, not replacement):
- Use `if (ResponsiveLayout.isDesktop(context))` for desktop behavior
- Keep mobile behavior unchanged for mobile
- Test on both platforms