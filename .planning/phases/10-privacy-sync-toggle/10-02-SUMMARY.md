---
phase: 10-privacy-sync-toggle
plan: 02
subsystem: Privacy & Settings UI
tags: [privacy, toggle, settings, UI]
requires: [PRIVACY-02]

## Plan Summary

| Field | Value |
|-------|-------|
| Phase | 10-privacy-sync-toggle |
| Plan | 02 |
| Status | ✅ Complete |
| Duration | ~10 minutes |

## Objective

Implement the server sync toggle UI in the Privacy Transparency card with proper warning dialogs.

## Context

- **Prior work (Plan 10-01):** Curation tracking wired, Supabase schema created
- **This plan:** Add toggle UI to Settings → Privacy card
- **Output:** Stateful widget with SwitchListTile + warning dialogs

## Tasks Executed

### Task 1: Add Server Sync Toggle and Warning Dialogs ✅

**Modified file:**
- `lib/features/settings/presentation/widgets/privacy_transparency_card.dart`

**Changes:**
- Converted from StatelessWidget to StatefulWidget
- Added SharedPreferences import for sync toggle state
- Added state: `_isSyncEnabled`, `_isLoading`, `_isSyncing`
- Added `_loadSyncPreference()` on initState
- Added `_toggleSync(bool)` with ON/OFF logic
- Added `_syncLocalToServer()` for syncing (stubbed)
- Added `_showTurnOffWarning()` dialog for confirmation
- Added `_deleteServerAnalytics()` for cleanup (stubbed)
- Added "Your data is NEVER sold" assurance text
- Added SwitchListTile with proper labeling
- Added cloud sync status icon

**UI Elements:**
- ✅ Toggle shows in Privacy Transparency card
- ⚠️ Warning dialog appears when turning OFF from ON
- ✅ Clear text: "Your data is NEVER sold to third parties"

**Verification:**
```
grep -l "Sync to Cloud\|curation_sync_enabled" lib/ → Found in 1 file
```

## Decisions Made

| Decision | Rationale |
|----------|----------|
| StatefulWidget | Need to manage toggle state |
| Stub sync functions | Prepared for server implementation |
| Warning on OFF | Clear UX - user confirms before delete |

## Metrics

| Metric | Value |
|--------|-------|
| Files Modified | 1 |
| Lines Added | ~100 |
| Tasks Completed | 1/1 |
| Verification | Pass |

## Deviation: None

Plan executed as written.

## Stub Tracking

| Stub | File | Reason |
|------|------|--------|
| `_syncLocalToServer()` | Supabase server not deployed yet - placeholder |
| `_deleteServerAnalytics()` | Supabase server not deployed yet - placeholder |

These are intentional - sync functions will be wired when the server is ready.

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| None | No new threat surface - UI toggle only |

---

*Plan: 10-02 • Phase: 10-privacy-sync-toggle*