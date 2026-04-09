# Phase 4: Scalability Improvements - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-09
**Phase:** 04-scalability-improvements
**Areas discussed:** Pagination Strategy, Offline Caching, Lazy Loading, Image Optimization, Retry Logic

---

## Pagination Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Cursor-based | Uses a cursor/anchor point. Best for real-time data like feeds, chats, timelines. More performant at scale. | ✓ |
| Offset-based | Uses offset and limit. Simpler to implement but degrades with large datasets. | |
| Hybrid | Use cursor for feeds/chats, offset for search results with page numbers | |

**User's choice:** Cursor-based (Recommended)

---

## Offline Caching

| Option | Description | Selected |
|--------|-------------|----------|
| Hive (local-first) | Local-only storage for offline. Data synced when online. Good for messages, feeds, profiles. | ✓ |
| Remote-only | All data stays on server. Only cache UI state. | |
| Hybrid with sync | Smart sync: local cache + server sync + conflict resolution. | |

**User's choice:** Hive (local-first) (Recommended)

---

## Lazy Loading

| Option | Description | Selected |
|--------|-------------|----------|
| Route-based splitting | Split code by route. Users download features they use. Best for distinct screens. | ✓ |
| Widget-level | Defer non-critical imports until needed. Good for large widgets. | |
| Full code splitting | All of the above combined | |

**User's choice:** Route-based splitting (Recommended)

---

## Image Optimization

| Option | Description | Selected |
|--------|-------------|----------|
| Supabase CDN | Built into Supabase. Automatically optimizes images on upload. | ✓ |
| Cloudinary | Third-party service with advanced transformations. | |
| Skip for now | Don't optimize now, handle when needed | |

**User's choice:** Supabase CDN (Recommended)

---

## Retry Logic

| Option | Description | Selected |
|--------|-------------|----------|
| Exponential backoff | Progressive delay between retries. Prevents overwhelming servers during outages. | ✓ |
| Fixed retries | Fixed number of retries with constant delay. | |
| Circuit breaker | Stop calling service after failures, retry after cooldown. | |

**User's choice:** Exponential backoff (standard pattern for resilient apps)

---

## the agent's Discretion

- Exact cursor field naming conventions per endpoint
- Hive box organization and schema versioning
- Route splitting boundaries and chunk sizes
- CDN transformation presets
- Retry max attempts and timeout values

---

## Deferred Ideas

- Widget-level deferred imports for complex widgets
- Hybrid with sync for offline caching (more complex, Hive-first is sufficient for v1)
- Cloudinary for image optimization (Supabase CDN is sufficient for now)