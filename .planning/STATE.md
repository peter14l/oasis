# Oasis Project State

## Current Status
- **Phase:** 10 (Privacy Sync Toggle)
- **Status:** Phase 10 completed. Phase 8 completed. Phase 3 completed. Phase 2 completed. Phase 1 (Cleanup) in progress (01-01 ready).

## Recent Activity
- **Phase 10:** Wired curation tracking to FeedProvider/ChatProvider, created server schema, added sync toggle UI with warning dialogs
- **Phase 8:** Implemented E2EE for all personal content (Capsules, Canvas), Privacy Heartbeat logs, Local Curation Tracking, and House Ads system.
- **Phase 3:** Fully implemented multi-participant Mesh calls, E2EE signaling, screen sharing, and integrated calling UI into the chat system.
- **Phase 2:** Successfully implemented username-based sign-in and password reset.

## Key Decisions
- **Cleanup Scope:** Focused exclusively on .dart files.
- **Migration Path:** Legacy models (notification.dart, call.dart, story_model.dart) will be replaced by feature-driven entities (AppNotification, CallEntity, StoryEntity) before deletion.
- **Exclusions:** No .sql, assets, or scripts should be touched in this phase.
- **Privacy Sync Default:** OFF (privacy-first default per user requirements)

## Blockers
- None.

## Todos
- [ ] Execute Plan 01-01: Migration & Audit.
- [ ] Execute Plan 01-02: Cleanup & Validation.
