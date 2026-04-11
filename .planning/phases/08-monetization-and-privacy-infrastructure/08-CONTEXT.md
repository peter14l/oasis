# Phase 8: Monetization and Privacy Infrastructure - Context

**Gathered:** 2026-04-11
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase focuses on three pillars:
1.  **Privacy & Security:** Auditing and reinforcing security for Journals, Time Capsules, and Canvas items to ensure they are private and uncompromised.
2.  **User-Centric Tracking:** Implementing a "Privacy-First Tracking" algorithm for Feed and Ripples that collects data *only* for curation, with explicit user assurance and no 3rd-party data sales.
3.  **Sustainable Monetization:** Implementing an Ad system for Feed and Ripples using only free services, with data-privacy protections (no sharing) and automatic ad-removal for Pro members.

</domain>

<decisions>
## Implementation Decisions

### Security Audit & Reinforcement
- **D-01:** Server-side Row Level Security (RLS) validation for `time_capsules`, `canvas_items`, and `journals`.
- **D-02:** Ensure all sensitive content utilizes the existing E2EE infrastructure where applicable (libsignal_protocol_dart).
- **D-03:** Implement a "Privacy Heartbeat" or audit log that users can view to see how their data was accessed.

### Tracking Algorithm
- **D-04:** Implement `CurationTrackingService` to log user interests (e.g., categories viewed, time spent, likes) locally or in a private Supabase table.
- **D-05:** Data is explicitly siloed and never exported to 3rd-party trackers (like Facebook/Google SDKs).
- **D-06:** User assurance UI: A "Privacy Transparency" card in the settings explaining exactly what is tracked and why.

### Monetization (Ads)
- **D-07:** Use a "House Ads" or "Internal Ad Exchange" model to start, or integrate a free-tier ad provider that doesn't require invasive SDKs (e.g., carbon-style ads or custom sponsored content).
- **D-08:** `isPro` check in `FeedProvider` and `RipplesProvider` to conditionally filter out ad entities.
- **D-09:** Ad entities must follow the same schema as `Post` (using `isAd: true`) to minimize UI changes.

</decisions>

<canonical_refs>
## Canonical References

### Features
- `lib/features/capsules/domain/models/time_capsule_entity.dart`
- `lib/features/canvas/domain/models/canvas_models.dart`
- `lib/features/ripples/presentation/providers/ripples_provider.dart`
- `lib/features/feed/presentation/providers/feed_provider.dart`

### Services
- `lib/services/time_capsule_service.dart`
- `lib/services/subscription_service.dart`
- `lib/services/digital_wellbeing_service.dart` (potential integration for tracking)

</canonical_refs>

## Existing Code Insights

### Ad Support
- `Post` entity in `lib/features/feed/domain/models/post.dart` already has an `isAd` boolean.

### Pro Status
- `UserProfileEntity` has `isPro`.
- `SubscriptionService` provides `isPro` status.

### Security
- libsignal_protocol_dart is present in `pubspec.yaml` and used in messaging.

</specifics>

---

*Phase: 08-monetization-and-privacy-infrastructure*
*Context gathered: 2026-04-11*
