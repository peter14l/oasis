---
phase: 14
plan: 09
subsystem: Security & Digital Wellbeing
tags: [fortress-mode, lock, away-message, digital-wellbeing]
dependency_graph:
  requires:
    - 14-06 (PIN/encryption)
  provides:
    - fortress-lock
    - away-messages
  affects:
    - profiles-table
    - presence-service
    - desktop-header
tech_stack:
  added:
    - FortressService (ChangeNotifier)
    - FortressLockScreen
    - FortressLockButton
    - FortressMessageSelector
    - FortressStatusDisplay
  patterns:
    - One-tap activation via long-press or triple-tap
    - Same PIN as app lock (vault/encryption)
    - Custom away messages (predefined + custom)
    - Integrated with presence for friends visibility
key_files:
  created:
    - lib/services/fortress_service.dart
    - lib/screens/fortress_lock_screen.dart
    - lib/widgets/fortress_lock_button.dart
    - lib/widgets/fortress_message_selector.dart
    - lib/widgets/fortress_status_display.dart
    - supabase/migrations/20260428000000_add_fortress_mode.sql
  modified:
    - lib/services/app_initializer.dart
    - lib/widgets/desktop_header.dart
decisions:
  - Used lock icon instead of castle (fluent icons)
  - Same PIN as encryption/vault for simplicity
  - Predefined messages: 🏰 In my fortress, 📵 Digital detox, 🔋 Recharging, 🎯 In the zone, 🌙 Sleep mode, 📚 Deep in a book, 🏖️ Taking a break
  - Fortress status shown in presence for friends to see
metrics:
  duration: 15 minutes
  completed: 2026-04-28
---

# Phase 14 Plan 09: Fortress Mode Summary

**One-tap to lock the app with a custom "away" message.**

## Implementation

### Database
- Added `fortress_mode` (BOOLEAN DEFAULT FALSE)
- Added `fortress_message` (VARCHAR 200) 
- Added `fortress_until` (TIMESTAMPTZ for auto-disable)
- Created index for efficient fortress queries
- RLS policies for read access and self-update

### FortressService
- State management with ChangeNotifier
- `activateFortress(customMessage, duration)` - enables fortress mode
- `deactivateFortress()` - disables fortress mode
- `toggleFortress()` - quick toggle
- `onTripleTap()` - triple-tap gesture handler
- `getFortressStatus(userId)` - static method to get other users' fortress status
- Updates presence to 'fortress' when activated, 'online' when deactivated

### Fortress Lock Screen
- PIN entry UI (6-digit)
- Shows away message prominently
- Castle/lock animation on entry
- Unlock to deactivate

### Fortress Message Selector
- Predefined messages with emoji + text
- Custom message input option
- Chip-based selection UI

### Fortress Lock Button
- Long-press to activate (with progress indicator)
- Tap to show options sheet
- Shows active indicator when fortress is enabled

### Desktop Header Integration
- Added FortressLockButton to header actions
- Can be toggled on/off via showFortressButton parameter

### Friends Visibility
- FortressStatusDisplay widget for showing in friend lists
- UserFortressStatus future builder for fetching status
- Integrated with presence - status shows as "fortress" instead of "offline"

## Verification

- [x] Database migration applied
- [x] FortressService initializes and loads status
- [x] Lock screen shows PIN entry
- [x] Away message can be selected
- [x] Long-press activates fortress
- [x] Desktop header shows lock button
- [x] Friends can see fortress status
- [x] Build passes (analyzer shows no errors)

## Deviations

None - plan executed as written.

## Known Stubs

None - all functionality wired and working.