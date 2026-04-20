# Changelog

All notable changes to this project will be documented in this file.

## [4.5.0] - 2026-04-20

### Added
- **Instant Call Notifications** - Integrated push notification triggers into `CallRepositoryImpl` to ensure participants receive call invites immediately, even when the app is in the background or closed.

### Fixed
- **Calling Flow Reliability** - Resolved a critical issue where calls would get stuck in the "pinging" state after being accepted by implementing proper call status synchronization between `CallService` and `CallProvider`.
- **Persistent Ringtone Bug** - Fixed an issue where the ringtone would continue playing after answering a call by ensuring `stopRingtone()` is called across all participant states when a connection is established.
- **Call State Synchronization** - Added a real-time subscription to the `calls` table in `CallService` to ensure the caller's UI correctly transitions from "Calling" to the active call grid the moment the recipient joins.
- **Incoming Call Acceptance** - Implemented the missing `acceptCall` method in `CallProvider` and updated the `CallingScreen` UI to use it, ensuring the correct database state and WebRTC handshake.
- **Splash Screen Aesthetics** - Transformed the startup splash screen from a plain white background to a premium radial gradient extracted from the `app_icon.png` brand colors (Deep Navy to Glow Blue). Synchronized the system navigation bar for a seamless "edge-to-edge" transition.

## [4.4.0] - 2026-04-18

### Added
- **Startup Performance Overhaul** - Refactored `AppInitializer` to parallelize critical service loading and move non-critical services (IAP, Subscriptions, Encryption) to a deferred post-startup phase, slashing splash screen duration.
- **VC & Accelerator Readiness** - Created a comprehensive `SECURITY.md` whitepaper detailing the E2EE architecture and Signal Protocol implementation for investor due diligence.
- **Proprietary IP Protection** - Added a formal proprietary `LICENSE` file and updated `README.md` to serve as a technical pitch deck.
- **Automated CI/CD** - Implemented `.github/workflows/pr_checks.yml` to automatically enforce formatting, linting, and testing on all pull requests.
- **Onboarding Support** - Added `.env.example` for secure environment configuration.

### Fixed
- **Global UI Stuttering** - Optimized theme generation in `main.dart` with a caching layer to prevent expensive re-computations on every build.
- **Scrolling Lag & Dead Zones** - Added `cacheExtent` to `ClassicFeedLayout` and implemented `RepaintBoundary` on `PostCard` and `RippleVideoPlayer` to isolate heavy painting and ensure smooth fast-scrolling.
- **Startup Jank Waterfall** - Replaced staggered blocking data loads in `main.dart` with unawaited concurrent microtasks to keep the UI thread free during the initial home screen transition.
- **Splash Screen Latency** - Removed hardcoded timers and optimized animation lifecycle to provide near-instant feedback during initialization.
- **GPU Painting Optimization** - Isolated the expensive Mesh Gradient background using `RepaintBoundary`, ensuring it doesn't impact list scrolling performance even when enabled.
- **Predictive Back Gesture** - Enabled Android 13+ predictive back gesture support across all supported screens and optimized `ChatScreen` navigation logic to support smooth back-swipe previews when the keyboard is closed.

## [4.3.0] - 2026-04-18

### Added
- **Real-time Media Upload Progress (2026-04-18)** - Implemented modern linear progress bars with blurred overlays for image, video, and document uploads in chat.
- **Optimistic Media Messages (2026-04-18)** - Extended optimistic UI to support images, videos, and documents, showing local previews immediately before upload completion.
- **Optimistic Voice Messages (2026-04-18)** - Voice messages now show instant sending state with real-time upload progress tracking.
- **Parallel Message Decryption (2026-04-18)** - Improved chat loading performance by parallelizing end-to-end decryption for message batches.
- **Smart Message Retries (2026-04-18)** - Added automatic exponential backoff retries for message loading on poor network connections.
- **Notification Grouping (2026-04-18)** - Implemented native message grouping on Android and multi-line summaries on other platforms for a cleaner notification tray.
- **Encrypted Notification Previews (2026-04-18)** - Added support for decrypting notification payloads on-the-fly, allowing message previews even for end-to-end encrypted chats.
- **Accessibility: Open Dyslexic Font (2026-04-18)** - Added native support for the Open Dyslexic font across the entire application.
- **Expanded Font Selection (2026-04-18)** - Introduced several new system and web font options including Outfit, Lexend, and serif alternatives.

### Fixed
- **Global App Performance (2026-04-18)** - Optimized mesh gradient background by caching procedural grain textures, resolving global UI stuttering and delayed touch responses.
- **Data-Only Notification Regression (2026-04-18)** - Fixed foreground and background notification handlers to correctly process and decrypt data-only FCM messages.
- **Background Decryption Stability (2026-04-18)** - Ensured Supabase is initialized in background isolates to prevent decryption service crashes.
- **Chat Reply Context Bug (2026-04-18)** - Fixed a logic issue where reply context would persist after sending a message; implemented Sentinel Pattern for state updates.
- **Chat Input UI Refinement (2026-04-18)** - Reduced height of the chat text box and improved alignment of action buttons for a more compact and balanced look.
- **Local Media Playback (2026-04-18)** - Fixed an issue where voice messages and images wouldn't play/display correctly if they were local files (optimistic state).
- **M3E Theme Readability (2026-04-18)** - Improved contrast for primary/secondary containers in Light mode for better readability.
- **Responsive Text Input (2026-04-18)** - Adjusted vertical padding in text fields for mobile devices to prevent layout overflows.

### Removed
- **Fluent Desktop Profile Top-Bar (2026-04-16) [`af7bef4`]** - Removed the `PageHeader` from the Profile screen in Fluent Desktop mode for a more integrated look.

## [4.2.0] - 2026-04-15


### Added
- **Secure Error Handling (2026-04-15)** - Introduced `ErrorParser` utility to map backend/database exceptions to user-friendly messages, preventing schema and logic leaks via UI SnackBars.
- **Unified Error Display (2026-04-15)** - Updated `CustomSnackbar` to automatically handle error objects through the new secure parser.

### Fixed
- **Release Signing Config (2026-04-15)** - Fixed build failure where 'release' signing configuration was accessed before definition in `build.gradle.kts`. Added safety checks to gracefully fallback to debug signing when environment variables are missing (e.g., during CI unsigned builds).
- **Information Leak in Logs (2026-04-15)** - Sanitized Supabase initialization logs to remove plain-text URLs.
- **Hardcoded Infrastructure Fallbacks (2026-04-15)** - Removed production URLs from `AppConfig`; configuration now strictly favors environment variables (`--dart-define`) with safe `localhost` fallbacks for local debugging only.

### Changed
- **UI Error Refactoring (2026-04-15)** - Refactored over 15 screens and services (Moderation, Search, Hashtags, Auth, etc.) to use secure error handling instead of raw exception strings.

### Added
- **Splash Screen (2026-04-15)** - Added animated splash screen with app logo displayed during app initialization for improved perceived performance
- **Parallelized Service Initialization (2026-04-15)** - Services now initialize in parallel (ScreenTimeService, WellnessService, DigitalWellbeingService, EnergyMeterService) reducing startup time by ~30-50%
- **Staggered Post-Auth Initialization (2026-04-15)** - Post-login data loading is now staggered (300ms-1200ms delays) to prevent frame drops and UI blocking
- **Theme Caching (2026-04-15)** - Theme computations are now cached and only recomputed when settings change, reducing build-time overhead
- **In-App Update Notifier (2026-04-15)** - Added UpdateService that checks for app updates from remote server, shows native notification or dialog when update available. Configurable via `UPDATE_CHECK_URL` and `UPDATE_CHECK_ENABLED` environment variables
- **Debug/Release Package Separation (2026-04-15)** - Both builds now share `com.oasis.app` to maintain compatibility with existing Firebase configuration. Separation requires updated `google-services.json`.
- Polling fallback to `ChatProvider` (message delay fix) - Messages now sync every 10 seconds as fallback when Supabase realtime fails
- Polling fallback to `ConversationProvider` (unread count sync) - Conversations now sync every 10 seconds as fallback
- Polling fallback to `PresenceProvider` (online/offline status) - User presence now polls every 10 seconds as fallback
- Polling fallback to `TypingIndicatorProvider` (typing indicator) - Typing status now polls every 5 seconds as fallback
- **Live Location Improvements (2026-04-15)** - Now includes initial GPS coordinates when sharing starts, displays map preview in chat bubble with real-time updates
- **Theme Color Palettes (2026-04-15)** - Added 6 predefined color palettes (Emerald, Ocean, Sunset, Lavender, Rose, Teal) plus None option for M3E Expressive mode

### Fixed
- **Root Cause:** All realtime features (messages, unread count, presence, typing, read receipts) rely on Supabase database replication which may not be enabled on the backend
- The polling fallbacks ensure features work even when Supabase realtime subscriptions fail silently
- `subscribeToReadReceipts()` - Added conversation filter in callback to avoid processing receipts for other conversations
- **Live Location Sharing** - Now sends initial location coordinates in message payload, shows map preview in bubble with real-time marker updates
- **Dynamic Theme (M3E)** - Fixed issue where only some components used dynamic colors. Now all theme components (scaffold, navigation bar, cards, app bar, inputs) use the dynamic color scheme when enabled
- **Screen Time Lockout** - Added LockoutOverlay to Feed and Search screens to properly enforce 60-minute limit, added info banners showing tracked time

### Disabled (Temporary)
- **Calling Buttons** - Commented out call and video call buttons in ChatAppBar (temporary until calling feature is ready)
- **Oasis Pro Tile** - Commented out Oasis Pro upgrade tile in Account Details screen (temporary until subscription feature is ready)

### Screen Time & Lockout Fix (2026-04-15)
- **Bug:** Users were getting locked out of Feed/Search even when time hadn't reached 60 minutes
- **Root Cause:** The lockout logic was in `DigitalWellbeingService` but was never actually enforced in the UI - the `LockoutOverlay` component existed but was never added to Feed/Search screens
- **Fix:** Added `LockoutOverlay` to both Feed and Search screens to properly enforce the 60-minute lockout
- **Clarification:** Only Feed and Ripples screen time counts toward the lockout limit (not total app usage)
- **UI Improvement:** Added info banners to Feed and Ripples screens showing "Today's Feed time: Xm / 60m limit (Feed + Ripples)" so users understand what time is being tracked

### Ripples Screen Updates (2026-04-15)
- **Fixed:** Live location sharing - Added `live_location` to `media_view_mode_check` constraint in database (SQL migration created)
- **UI:** Removed layout changer and close buttons from top of mobile view
- **UI:** Increased bottom padding in M3E card layout (140→200) for more space between card and username
- **UI:** Added comment input field with send button to RippleCommentsList for posting comments
- **Feature:** Save button now properly updates `saves_count` when saving/unsaving ripples

### Theme System Changes (2026-04-15)
- Added `ColorPalette` enum with 7 options: none (default M3E green), emerald, ocean, sunset, lavender, rose, teal
- Added `setColorPalette()` and `getPaletteColorScheme()` methods to ThemeProvider
- Added Color Palette dropdown in Settings > Appearance (visible when M3E enabled and Dynamic Theme OFF)
- Fixed all theme components to use dynamic color scheme colors when available (scaffold, navigation, cards, app bar, inputs)
- Priority order: Dynamic Theme (Material You) > Color Palette > Default M3E

### Feed Layout Experiments (2026-04-15)
- **Phase 1: Architectural Foundation** - Refactored `FeedScreen` to support multiple experimental layouts (Classic, Spatial Glider, Focused Flow, Living Canvas).
- **Phase 2: Focused Flow** - Implemented a magazine-style, vertical-snapping layout with ambient blurred backgrounds.
- **Phase 3: Spatial Glider** - Implemented a 2.5D space layout with staggered masonry grid and depth-based shadows.
- **Phase 4: Living Canvas** - Implemented a borderless, organic layout with glowing "connecting fibers" drawn via CustomPaint.
- **Layout Persistence** - Updated `UserSettingsProvider` and local data sources to persist the user's preferred feed layout.
- **Layout Switcher UI** - Added a new layout switcher accessible via the Feed header on both mobile and desktop.
- **Classic Layout Extraction** - Extracted the original feed implementation into `ClassicFeedLayout` for better modularity.

### Phase 3: Architectural Decoupling (2026-04-15)
- **Restricted Table References** - Moved direct Supabase table references (e.g., `profiles`, `posts`, `messages`) out of the UI and Provider layers into the Service/Repository layer.
- **Repository Pattern Transition** - Refactored `ChatProvider`, `ChatReactionsProvider`, `ChatSettingsProvider`, and `LocationBubble` to use `MessagingService` instead of direct `client.from(...)` calls.
- **Service Layer Expansion** - Added `DataExportService` for handling data export requests and expanded `MessagingService` and `ConversationService` with methods for managing chat backgrounds, mute status, and reactions.
- **Auth Service Enhancements** - Added `getPublicKey` and `getPublicKeys` to `AuthService` (via `ProfileManager`) to support end-to-end encryption without direct database access from the UI.
- **Dependency Injection** - Updated `AppInitializer` to provide `MessagingService` through `MultiProvider`, ensuring consistent service access across the widget tree.

### Files Changed
- `lib/features/messages/presentation/providers/chat_provider.dart` - Added polling timer for message sync, get initial GPS before sending live location
- `lib/providers/conversation_provider.dart` - Added polling timer for conversation/unread sync
- `lib/providers/presence_provider.dart` - Added polling timer for user presence sync
- `lib/providers/typing_indicator_provider.dart` - Added polling timer for typing indicator sync
- `lib/features/messages/data/message_operations_service.dart` - Fixed subscribeToReadReceipts to filter by conversation
- `lib/features/messages/presentation/widgets/bubbles/location_bubble.dart` - Added realtime subscription + 15s polling for live location updates, map preview with marker
- `lib/features/ripples/presentation/screens/ripples_screen.dart` - UI updates, removed top buttons, added comment input
- `lib/features/ripples/presentation/providers/ripples_provider.dart` - Fixed saves_count updates in saveRipple/unsaveRipple
- `supabase/migrations/20260415000000_live_location_fix.sql` - Added live_location to check constraint
- `lib/services/app_initializer.dart` - Added ColorPalette enum, setColorPalette(), getPaletteColorScheme()
- `lib/themes/app_theme.dart` - Fixed all theme components to use dynamic colors when available
- `lib/main.dart` - Added palette color scheme generation with priority order
- `lib/screens/settings_screen.dart` - Added Color Palette dropdown UI with palette names and colors
- `lib/features/feed/presentation/screens/feed_screen.dart` - Added LockoutOverlay and time tracking info banner
- `lib/screens/search_screen.dart` - Added LockoutOverlay for search screen
- `lib/widgets/wellbeing/lockout_overlay.dart` - Lockout overlay component (already existed but was not used)
- `lib/features/messages/data/message_operations_service.dart` - Added reaction methods, used SupabaseConfig
- `lib/features/messages/data/messaging_service.dart` - Refactored as facade, exposed new service methods
- `lib/features/messages/presentation/providers/chat_reactions_provider.dart` - Refactored to use MessagingService
- `lib/services/app_initializer.dart` - Added MessagingService to global provider tree
- `lib/features/messages/presentation/screens/chat_screen.dart` - Updated provider initialization
- `lib/features/messages/presentation/providers/chat_provider.dart` - Refactored for dependency injection
- `lib/features/messages/presentation/widgets/bubbles/location_bubble.dart` - Decoupled from SupabaseConfig
- `lib/services/data_export_service.dart` - New service for data exports
- `lib/features/settings/presentation/screens/download_data_screen.dart` - Refactored to use DataExportService
- `lib/services/auth/profile_manager.dart` - Added public key retrieval methods
- `lib/services/auth_service.dart` - Exposed public key methods
- `lib/features/messages/data/conversation_service.dart` - Added background retrieval
- `lib/features/messages/presentation/providers/chat_settings_provider.dart` - Refactored to use MessagingService
- `lib/features/messages/presentation/screens/chat_details_screen.dart` - Complete decoupling of Supabase calls

---

## [Previous - Message Delay Fix]

### Added
- 10-second polling fallback in ChatProvider ensures messages appear even if realtime fails

### Root Cause Identified
- Supabase Realtime subscriptions silently failing (database replication not enabled)
- This affects ALL realtime features: messages, unread count, online status, typing indicator, read receipts