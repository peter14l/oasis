# Oasis Project State

## Current Status
- **Phase:** 3 (Advanced Calling Experience)
- **Status:** Phase 3 completed. Phase 2 completed. Phase 1 (Cleanup) in progress (01-01 ready).

## Recent Activity
- **Phase 3:** Fully implemented multi-participant Mesh calls, E2EE signaling, screen sharing, and integrated calling UI into the chat system.
- **Phase 2:** Successfully implemented username-based sign-in and password reset.

## Key Decisions
- **Cleanup Scope:** Focused exclusively on .dart files.
- **Migration Path:** Legacy models (notification.dart, call.dart, story_model.dart) will be replaced by feature-driven entities (AppNotification, CallEntity, StoryEntity) before deletion.
- **Exclusions:** No .sql, assets, or scripts should be touched in this phase.

## Blockers
- None.

## Todos
- [ ] Execute Plan 01-01: Migration & Audit.
- [ ] Execute Plan 01-02: Cleanup & Validation.
