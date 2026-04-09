# Phase 4: Scalability Improvements - Context

**Gathered:** 2026-04-09
**Status:** Ready for planning

<domain>
## Phase Boundary

Implement scalability patterns including pagination, offline caching, lazy loading, and retry logic to support platform growth. This phase adds infrastructure for handling increased load while maintaining performance.

</domain>

<decisions>
## Implementation Decisions

### Pagination Strategy
- **D-01:** Cursor-based pagination for feeds, messages, and lists
  - Uses a cursor/anchor point for real-time data
  - Best for feeds, chats, timelines
  - More performant at scale than offset-based

### Offline Caching
- **D-02:** Hive (local-first) for offline data handling
  - Local storage for offline capability
  - Data synced when user comes back online
  - Good for messages, feeds, profiles

### Lazy Loading
- **D-03:** Route-based code splitting
  - Split code by route
  - Users download only features they use
  - Best for app with distinct screens (home, feed, profile)

### Image Optimization
- **D-04:** Supabase CDN for image/media optimization
  - Built into Supabase
  - Automatically optimizes images on upload
  - Best for Supabase backend integration

### Retry Logic
- **D-05:** Exponential backoff for network failures
  - Progressive delay between retries
  - Prevents overwhelming servers during outages
  - Standard industry pattern for resilient apps

### the agent's Discretion
- Exact cursor field naming conventions per endpoint
- Hive box organization and schema versioning
- Route splitting boundaries and chunk sizes
- CDN transformation presets
- Retry max attempts and timeout values

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Supabase
- `lib/core/network/supabase_client.dart` — Supabase client configuration

### Existing data sources
- `lib/features/messages/data/datasources/message_remote_datasource.dart` — Message fetching patterns
- `lib/features/feed/data/datasources/feed_remote_datasource.dart` — Feed fetching patterns
- `lib/features/profile/data/datasources/profile_remote_datasource.dart` — Profile fetching patterns

[No external specs — requirements fully captured in decisions above]

</canonical_refs>

## Existing Code Insights

### Reusable Assets
- Supabase client already exists in `lib/core/network/supabase_client.dart`
- Provider pattern established for state management
- Data sources follow a remote/local pattern

### Established Patterns
- Supabase for backend (PostgreSQL + Realtime)
- Provider for state management
- Service layer for business logic

### Integration Points
- New pagination will integrate with existing data sources
- Hive will need to be initialized in AppInitializer
- Lazy loading requires route configuration changes

</specifics>

<deferred>
## Deferred Ideas

- Widget-level deferred imports for complex widgets
- Hybrid with sync for offline caching (more complex, Hive-first is sufficient for v1)
- Cloudinary for image optimization (Supabase CDN is sufficient for now)

</deferred>

---

*Phase: 04-scalability-improvements*
*Context gathered: 2026-04-09*