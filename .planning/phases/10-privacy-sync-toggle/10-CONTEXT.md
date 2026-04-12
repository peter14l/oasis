# Phase 10: Privacy Sync Toggle - Context

**Gathered:** 2026-04-12
**Status:** Ready for planning
**Source:** User requirements

<domain>
## Phase Boundary

This phase addresses the Privacy Transparency feature with optional server sync:

1. **Verify existing tracking:** Check if the current PrivacyTransparencyCard is working and if CurationTrackingService is actually being called anywhere
2. **Add server sync toggle:** Provide users a toggle to optionally sync their tracking data to our Supabase server
3. **Update tracking logic:**
   - When toggle ON: Sync existing local analytics to server, store new analytics in Supabase
   - When toggle OFF: Show warning about losing curated content, delete user's analytics from server
4. **User assurance:** Clearly state data won't be sold to 3rd parties
5. **Create Supabase schema:** New tables for storing user analytics server-side

</domain>

<decisions>
## Implementation Decisions

### D-01: Existing Tracking Verification
- **Decision:** The CurationTrackingService exists but is NOT being called anywhere in the codebase. Need to fix this first.
- **Rationale:** The local tracking must actually work before we can sync it to the server.

### D-02: Server Sync Toggle
- **Decision:** Add a toggle switch in the PrivacyTransparencyCard UI
- **UI Location:** Same card, add Switch widget next to or below the description
- **Label:** "Sync to Server" or "Enable Cloud Backup"
- **Default:** OFF (privacy-first default)

### D-03: Third-Party Assurance
- **Decision:** Clearly state in UI that data will NEVER be sold to third parties
- **Implementation:** Add text: "Your data is NEVER sold to third parties and is SOLELY used to provide you with curated content."

### D-04: Server Sync Logic (Toggle ON)
- **Decision:** When toggle is turned ON:
  1. Read all existing local tracking data from CurationTrackingService
  2. POST to Supabase (new endpoint/table)
  3. Change CurationTrackingService to sync to Supabase instead of or in addition to local storage
- **Implementation:** Create server_sync_methods in CurationTrackingService, or new CurationSyncService

### D-05: Server Sync Logic (Toggle OFF)
- **Decision:** When toggle is turned OFF from ON state:
  1. Show warning dialog: "You will lose curated content on new devices"
  2. If confirmed: DELETE all analytics for this user from Supabase
  3. Revert to local-only storage
- **Warning text:** "Disabling sync will return to local-only storage. Your curated recommendations won't transfer to new devices."

### D-06: Supabase Schema
- **Decision:** Create new database table(s) for user_analytics
- **Table:** user_analytics (user_id, category_interactions, post_likes, time_spent, synced_at)
- **Security:** RLS policies allowing only the user's own data

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing Code
- `lib/services/curation_tracking_service.dart` — Local tracking (exists but unused)
- `lib/features/settings/presentation/widgets/privacy_transparency_card.dart` — UI card to modify
- `supabase/migrations/` — SQL migration patterns

### Supabase Patterns
- `supabase/migrations/20260413000000_house_ads.sql` — Recent migration style
- `supabase/migrations/20260412000000_privacy_and_ads.sql` — Privacy-related patterns

</canonical_refs>

<specifics>
## Specific Ideas

1. **Toggle UI:** Add SwitchListTile or similar in PrivacyTransparencyCard
2. **Service change:** Modify CurationTrackingService or create CurationSyncService
3. **SQL migration:** Create `supabase/migrations/20260412000000_user_analytics_sync.sql`
4. **Warning dialog:** Use showDialog with clear warning when toggling OFF from ON
5. **DELETE function:** Supabase RPC function to delete user's analytics

</specifics>

<deferred>
## Deferred Ideas

- Cross-device recommendation sync (beyond just analytics)
- Push notifications about new device sync status
- None — all items covered above

</deferred>

---

*Phase: 10-privacy-sync-toggle*
*Context gathered: 2026-04-12*