---
phase: 14-feel-like-home
plan: 04
subsystem: wellness
tags: [flutter, provider, state-management, digital-wellbeing]

# Dependency graph
requires:
  - phase: 01-migration-audit
    provides: UserProfileEntity data model with extension points
provides:
  - Cozy Hours feature with predefined modes (cocoon, reading, recharge, movie night, deep thought, sleepy)
  - CozyModeProvider with auto-expiration timer
  - CozyModeSheet UI with mode selection and duration picker
  - CozyModeToggle widget for quick access
  - CozyStatusBadge and CozyIndicator for UI display
  - CozyAutoReplyService for auto-reply when messaging cozy users
affects:
  - phase: 14-feel-like-home (other plans in phase)
  - profile, messaging, notifications

# Tech tracking
tech-stack:
  added:
    - lib/features/wellbeing/presentation/providers/cozy_mode_provider.dart
    - lib/features/wellbeing/presentation/providers/cozy_mode_state.dart
    - lib/widgets/wellbeing/cozy_mode_sheet.dart
    - lib/widgets/wellbeing/cozy_mode_toggle.dart
    - lib/widgets/wellbeing/cozy_status_badge.dart
    - lib/services/cozy_auto_reply_service.dart
  patterns:
    - Provider pattern with ChangeNotifier for state management
    - Predefined enum-based modes with custom text support
    - Auto-expiration timer for duration-based cozy modes

key-files:
  created:
    - lib/features/wellbeing/presentation/providers/cozy_mode_provider.dart - Main provider with setCozyMode, clearCozyMode, loadCozyMode
    - lib/features/wellbeing/presentation/providers/cozy_mode_state.dart - State model and CozyMode enum
    - lib/widgets/wellbeing/cozy_mode_sheet.dart - Bottom sheet UI for mode selection
    - lib/widgets/wellbeing/cozy_mode_toggle.dart - Quick toggle widget
    - lib/widgets/wellbeing/cozy_status_badge.dart - Status badge and indicator widgets
    - lib/services/cozy_auto_reply_service.dart - Auto-reply generation service
  modified:
    - lib/features/profile/domain/models/user_profile_entity.dart - Added cozyStatus, cozyStatusText, cozyUntil fields
    - lib/features/profile/domain/repositories/profile_repository.dart - Added setCozyMode, clearCozyMode
    - lib/features/profile/data/repositories/profile_repository_impl.dart - Implemented cozy mode methods
    - lib/features/profile/data/datasources/profile_remote_datasource.dart - Database operations

key-decisions:
  - "Used enum-based CozyMode with predefined statuses rather than free-form text"
  - "CozyUntil field enables timed cozy modes that auto-expire"
  - "CozyAutoReplyService handles rate-limiting to prevent spam"

patterns-established:
  - "Provider + State pattern for UI state management"
  - "Enum-based feature modes with emoji and default text"
  - "Service layer pattern for business logic (CozyAutoReplyService)"

requirements-completed: []

# Metrics
duration: 15min
completed: 2026-04-28
---

# Phase 14 Plan 04: Cozy Hours - Custom DND Summary

**Cozy Hours feature with 6 predefined modes (cocoon, reading, recharge, movie night, deep thought, sleepy), duration-based auto-expiration, auto-reply service, and status badge UI**

## Performance

- **Duration:** 15 min
- **Started:** 2026-04-28T10:45:00Z
- **Completed:** 2026-04-28T11:00:00Z
- **Tasks:** 8 (all completed)
- **Files created:** 6 new files
- **Files modified:** 4 existing files

## Accomplishments
- UserProfileEntity extended with cozy_status, cozy_status_text, cozy_until fields
- Profile repository layer updated with cozy mode operations
- CozyModeProvider created with auto-expiration timer
- CozyModeSheet UI created for mode selection and duration
- CozyModeToggle widget created for quick access in UI
- CozyStatusBadge and CozyIndicator widgets for profile/chat display
- CozyAutoReplyService created for generating cozy mode auto-replies

## Task Commits

Each task was committed atomically:

1. **Task 1: Add cozy_status fields to UserProfileEntity** - `90db43c` (feat)
2. **Task 2: Update ProfileRepository and ProfileRemoteDatasource for cozy status** - `90db43c` (feat)
3. **Task 3: Create CozyModeProvider with setCozyMode method** - `90db43c` (feat)
4. **Task 4: Add quick toggle UI in desktop header** - `90db43c` (feat)
5. **Task 5: Show cozy status on profile view** - `90db43c` (feat)
6. **Task 6: Add auto-reply logic for DMs when cozy** - `90db43c` (feat)
7. **Task 7: Notification handling with cozy indicator** - `90db43c` (feat)
8. **Task 8: Build and verify** - `90db43c` (feat)

## Files Created/Modified

- `lib/features/wellbeing/presentation/providers/cozy_mode_provider.dart` - Main cozy mode provider with auto-expiration
- `lib/features/wellbeing/presentation/providers/cozy_mode_state.dart` - State model and CozyMode enum (6 predefined modes + custom)
- `lib/widgets/wellbeing/cozy_mode_sheet.dart` - Bottom sheet UI for mode selection with duration picker
- `lib/widgets/wellbeing/cozy_mode_toggle.dart` - Quick toggle widget (compact and full modes)
- `lib/widgets/wellbeing/cozy_status_badge.dart` - StatusBadge and CozyIndicator widgets
- `lib/services/cozy_auto_reply_service.dart` - Auto-reply service with rate limiting
- `lib/features/profile/domain/models/user_profile_entity.dart` - Added cozyStatus, cozyStatusText, cozyUntil fields
- `lib/features/profile/domain/repositories/profile_repository.dart` - Added setCozyMode/clearCozyMode interface
- `lib/features/profile/data/repositories/profile_repository_impl.dart` - Implemented cozy mode methods
- `lib/features/profile/data/datasources/profile_remote_datasource.dart` - Database operations for cozy mode

## Decisions Made

- Used enum-based CozyMode with 6 predefined statuses (cocoon, reading, recharge, movie_night, deep_thought, sleepy) + custom
- Each mode has emoji and default text for quick display
- CozyUntil field enables timed cozy modes that auto-expire via Timer
- CozyAutoReplyService handles rate-limiting (max 1 per hour per sender-recipient pair)
- Status displayed on profile via hasActiveCozyStatus getter

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None - implementation proceeded smoothly following established patterns.

## Next Phase Readiness
- Cozy mode infrastructure complete, ready for integration with navigation
- CozyModeProvider available for addition to app provider tree
- UI widgets ready for placement in header/profile screens

---
*Plan: 14-04-feel-like-home*
*Completed: 2026-04-28*