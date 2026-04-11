# Oasis Project Roadmap

## Phase 1: Codebase Cleanup
**Goal:** Remove unused legacy .dart files after migrating active dependencies.
**Status:** In Progress
**Plans:** 2 plans

### Plans:
- [ ] 01-01-PLAN.md — Migrate active dependencies to new entities and audit remaining references.
- [ ] 01-02-PLAN.md — Remove unused legacy .dart files and perform final validation.

## Phase 2: Username-based Sign-in
**Goal:** Implement secure sign-in and password reset using unique usernames or emails.
**Status:** Completed
**Plans:** None (Single-task phase)

## Phase 3: Advanced Video/Voice Calling Experience
**Goal:** Implement robust, multi-participant video/voice calling with E2EE signaling, screen sharing, and themed UI.
**Status:** Completed
**Plans:**
- [x] 03-01-PLAN.md — Implement multi-participant Mesh calls, E2EE signaling, and screen sharing.
- [x] 03-02-PLAN.md — Implement themed calling UI, participant management, and overlay controls.

**Requirements:**
[CLEANUP-01, CLEANUP-02, CALL-01, CALL-02, CALL-03]

## Phase 4: Scalability Improvements
**Goal:** Implement scalability patterns including pagination, offline caching, lazy loading, and retry logic to support platform growth.
**Status:** Planned
**Plans:** None (TBD)

## Phase 5: PIN Recovery Mechanism
**Goal:** Set New Pin mechanism for users who have Both Forgot their pin and lost their recovery codes as well. The previous texts can't be accessed anymore but set up a mechanism for setting new pin so that the new texts are not lost anymore.
**Status:** Planned
**Plans:** 1 plan

### Plans:
- [ ] 05-01-PLAN.md — Implement PIN reset via email/password with warning and new PIN setup.

## Phase 7: Monetization and Privacy Infrastructure
**Goal:** Implement ethical monetization via House Ads and reinforce privacy through security auditing and transparency.
**Status:** Planned
**Plans:** 3 plans

### Plans:
- [ ] 07-01-PLAN.md — Security Audit, RLS reinforcement, and Privacy Heartbeat.
- [ ] 07-02-PLAN.md — Curation Tracking Service and Privacy Transparency UI.
- [ ] 07-03-PLAN.md — House Ads integration and Pro-member ad removal.

**Requirements:**
[PRIVACY-01, PRIVACY-02, MONETIZATION-01, MONETIZATION-02]
