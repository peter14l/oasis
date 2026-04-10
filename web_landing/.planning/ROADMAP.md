# ROADMAP.md - Oasis MVP

## Milestone: v1.0 MVP

**Goal:** Production-ready MVP with security focus  
**Timeline:** Under 1 month

---

## Phase Structure

### Phase 1: Security Foundations
- Fix critical `.gitignore` issue
- Rotate exposed API keys
- Implement proper error handling (replace alerts)
- Add error boundary

**Status:** Complete
**Plans:** 1 plan

**Plan list:**
- [x] 01-01-PLAN.md — Fix .gitignore, replace alerts, add error boundary

**Depends on:** None

### Phase 2: Testing Infrastructure
- Add Vitest + @testing-library/react
- Write tests for authentication flows
- Write tests for payment integrations

**Status:** In Progress
**Plans:** 3 plans

**Plan list:**
- [ ] 02-01-PLAN.md — Install Vitest + @testing-library/react, configure test environment
- [ ] 02-02-PLAN.md — Write tests for Login.jsx and SignUp.jsx (TDD)
- [ ] 02-03-PLAN.md — Write tests for payment components (TDD)

**Depends on:** Phase 1

### Phase 3: Quality Improvements
- Add TypeScript for type safety
- Implement Sentry error tracking
- Add lazy loading for routes

**Status:** In Progress
**Plans:** 3 plans

**Plan list:**
- [ ] 03-01-PLAN.md — Add TypeScript dependencies and configuration
- [ ] 03-02-PLAN.md — Install and configure Sentry error tracking
- [ ] 03-03-PLAN.md — Convert files to TypeScript and implement lazy loading

**Depends on:** Phase 2

### Phase 4: Feature Polish
- Fix navigation/routing issues
- Polish UI components
- Optimize bundle size

**Status:** Planned
**Plans:** 3 plans

**Plan list:**
- [ ] 04-01-PLAN.md — Fix navigation/routing issues (NavLink, Footer links)
- [ ] 04-02-PLAN.md — Polish UI components (ErrorBoundary, LoadingSpinner)
- [ ] 04-03-PLAN.md — Optimize bundle size (manual chunks)

**Depends on:** Phase 3

### Phase 5: Production Readiness
- HTTPS enforcement
- CSP headers
- Rate limiting
- Deploy to production

**Status:** In Progress
**Plans:** 1 plan

**Plan list:**
- [x] 05-01-PLAN.md — Implement HTTPS enforcement and CSP headers
- [ ] 05-02-PLAN.md — Implement rate limiting
- [ ] 05-03-PLAN.md — Deploy to production

**Depends on:** Phase 4

---

## Summary

| Phase | Focus | Priority |
|-------|-------|----------|
| 1 | Security Foundations | P0 |
| 2 | Testing Infrastructure | P1 |
| 3 | Quality Improvements | P2 |
| 4 | Feature Polish | P2 |
| 5 | Production Readiness | P1 |

---

*Created: 2026-04-09*
*Milestone: v1.0 MVP*