# Project Progress & Status

## Completed Tasks
- [x] **Calling V2 Architecture Implementation**
  - Migrated database to a simplified `calls` table.
  - Moved high-frequency signaling (ICE candidates) to Supabase Realtime Broadcast for low latency.
  - Implemented a robust DB-backed handshake for offers and answers.
  - Added 30-second ringing timeout and strict state machine in `CallProvider`.
  - Achieved full E2EE by encrypting WebRTC offers, answers, and ICE candidates using Signal Protocol.
- [x] **Platform Support & UI**
  - Updated `CallingScreen` for optimized 1-on-1 calls.
  - Fixed Windows/macOS native notification actions for V2.
  - Switched Web platform from Fluent UI to standard Material UI for consistency with mobile.
- [x] **Messaging Fixes**
  - Removed obsolete `call_id` column from the `messages` table.
  - Updated Supabase `send_message_v2` RPC function to remove legacy calling fields.
  - Resolved compilation errors related to `callId` removal in `MessagingService`.
- [x] **Web Subdomain Deployment Readiness**
  - Implemented automatic redirection to landing page (`http://oasisweb-omega.vercel.app/`) for unauthenticated web users.
  - Added `vercel.json` for proper SPA routing on Vercel.

## Current Issues & Pending Work
- [ ] **Flutter Web Build:** Initial build was started but manually stopped. Needs a clean re-run for deployment.
- [ ] **Vercel Deployment:** The app needs to be connected to Vercel, and environment variables from `.env` must be added to the Vercel dashboard manually.
- [ ] **Realtime Stability:** Added retry logic for `CallProvider` initialization, but should be monitored for any edge-case WebSocket disconnections.

## Next Steps
1. Push all latest changes to GitHub.
2. Connect the repository to Vercel for both the landing page (main domain) and the app (subdomain).
3. Update `oasisapp.com` DNS to point the `app` subdomain to Vercel.
4. Update the redirect URL in `app_router.dart` once the final domain is live.
