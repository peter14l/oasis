# Phase 7: Desktop Modal Adaptations - Context

**Gathered:** 2026-04-12
**Status:** Ready for planning
**Source:** User description from /gsd-plan-phase

<domain>
## Phase Boundary

Adapt all modal bottom sheets and context menus to work properly on desktop platforms (macOS, Windows, Web). Currently, these modals are designed for mobile touch interaction but need to show as context menus on desktop via right-click.

</domain>

<decisions>
## Implementation Decisions

### D-01: Desktop Detection Strategy
- Use `MediaQuery.of(context).size.width >= 1000` to detect desktop/tablet (existing pattern from chat_screen.dart)
- Continue using this threshold for consistency

### D-02: Modal Sheet Replacement Strategy
- For desktop: Show context menu (PopupMenu) instead of ModalBottomSheet
- For mobile: Keep existing ModalBottomSheet behavior
- This applies to: message options, attachment options, and any other modal sheets triggered by long-press or tap

### D-03: Right-Click Trigger
- Where modals currently open on tap-and-hold (mobile gesture), desktop should open on right-click
- `GestureDetector.onSecondaryTap` should be used alongside existing gestures

### D-04: Context Menu Positioning
- Use `RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy)` pattern from existing MessageOptionsMenu
- Position context menu next to the element (not blocking it)

### D-05: Message Options Desktop Adaptation (Priority)
- The message options sheet in chat_screen.dart already has this partially implemented
- Need to extend to full parity with mobile sheet (reactions picker)

### D-06: Attachment Options Desktop Adaptation
- Create AttachmentOptionsMenu for desktop right-click
- Keep existing AttachmentOptionsSheet for mobile

### D-07: Additional Modal Sheets
- Identify and adapt other frequently-used modal sheets:
  - Share sheet
  - Security PIN sheet (if applicable)
  - Account switcher sheet
  - Collection sheet

### the agent's Discretion
- Which additional modal sheets beyond message options and attachment options need adaptation
- Exact implementation details for context menus (icon styling, spacing)
- Whether to create new files or add conditional logic to existing sheets

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing Desktop Pattern
- `lib/features/messages/presentation/widgets/modals/message_options_menu.dart` — Context menu implementation (model for desktop menu)
- `lib/features/messages/presentation/screens/chat_screen.dart` — Desktop detection and menu triggering (lines 421-476)

### Related Files to Review
- `lib/features/messages/presentation/widgets/modals/message_options_sheet.dart` — Mobile sheet (for feature parity)
- `lib/features/messages/presentation/widgets/modals/attachment_options_sheet.dart` — Needs desktop menu

</canonical_refs>

<specifics>
## Specific Ideas

**From user description:**
- In chat_screen.dart, there's a modal sheet that shows up when tapping and holding the text bubbles
- For desktops, make the sheet show up as a mini context menu beside the text bubbles, on right-clicking them
- Make similar such other changes throughout the codebase

**Example pattern already exists:**
```dart
// From chat_screen.dart lines 425-437
if (MediaQuery.of(context).size.width >= 1000 && position != null) {
  MessageOptionsMenu(
    message: message,
    isOwnMessage: isOwn,
    position: position,  // Desktop: show menu at position
    onReply: () => _setReplyMessage(message),
    ...
  );
} else {
  showModalBottomSheet(...)  // Mobile: show sheet
}
```

</specifics>

<deferred>
## Deferred Ideas

- Dark mode specific styling for context menus (handled by theme)
- Keyboard shortcuts for desktop (future enhancement)
- Web-specific context menu styling

</deferred>

---

*Phase: 07-desktop-modal-adaptations*
*Context gathered: 2026-04-12 from user description*