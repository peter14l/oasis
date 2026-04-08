# External Integrations

**Analysis Date:** 2026-04-08

## APIs & External Services

**Backend-as-a-Service:**
- Supabase - Primary backend (PostgreSQL, Auth, Realtime, Storage).
  - SDK: `supabase_flutter`
  - Client: `lib/core/network/supabase_client.dart`
  - Config: `lib/core/config/supabase_config.dart`

**Messaging & Push:**
- Firebase Cloud Messaging (FCM) - Cross-platform push notifications.
  - SDK: `firebase_messaging`
  - Init: `lib/services/app_initializer.dart`
  - Manager: `lib/services/notification_manager.dart`

**Media & Content:**
- Giphy - Integrated GIF search and selection.
  - SDK: `giphy_get`
  - Client: `GiphyGet` in `lib/features/messages/presentation/widgets/giphy_picker.dart` (implied usage)

**Location Services:**
- Google Maps - Map visualization and interaction.
  - SDK: `google_maps_flutter`
  - Manager: `lib/services/location_service.dart` (implied usage)

## Data Storage

**Databases:**
- Supabase (PostgreSQL)
  - Realtime: Used for presence, typing indicators, and message syncing.
  - Client: `SupabaseClient` in `lib/core/network/supabase_client.dart`

**File Storage:**
- Supabase Storage
  - Purpose: Storing user avatars, post media (images/videos), and voice recordings.
  - Interface: `SupabaseService().storage` in `lib/core/network/supabase_client.dart`

**Caching:**
- SharedPreferences - Local persistence for user settings and session metadata.
- FlutterSecureStorage - Persistent storage for E2EE keys and sensitive tokens.
- cached_network_image - Image caching for performance.

## Authentication & Identity

**Auth Provider:**
- Supabase Auth
  - Social Auth: Google (`google_sign_in`), Apple (`sign_in_with_apple`).
  - Approach: GoTrue with PKCE flow.
  - Local Auth: Biometrics (`local_auth`) for vault and app locking.

## Monitoring & Observability

**Error Tracking:**
- Sentry
  - SDK: `sentry_flutter`
  - DSN: Configured in `lib/services/app_initializer.dart` via `SENTRY_DSN` environment variable.

**Logs:**
- Console logging (via `debugPrint`) during development.
- Sentry breadcrumbs and events in production.

## CI/CD & Deployment

**Hosting:**
- Supabase (Backend/Database).
- GitHub Pages/Vercel (Likely for `web_landing/` and `website/`).

**CI Pipeline:**
- GitHub Actions (implied by `.github/workflows/`).

## Environment Configuration

**Required env vars:**
- `SUPABASE_URL`: Supabase project URL.
- `SUPABASE_ANON_KEY`: Supabase project anonymous key.
- `SENTRY_DSN`: Sentry project DSN.
- `GOOGLE_MAPS_API_KEY`: API key for Google Maps SDK.

**Secrets location:**
- `.env` file (local development).
- Environment variables/Secrets (production/CI).

## Webhooks & Callbacks

**Incoming:**
- Supabase Edge Functions - Triggers for events like voice transcription.
- FCM Background Callbacks - `lib/services/app_initializer.dart`.

**Outgoing:**
- Supabase Functions - `transcribe-voice` function for speech-to-text.

---

*Integration audit: 2026-04-08*
