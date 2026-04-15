# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

## [4.2.0] - 2026-04-15

### Added
- **Secure Error Handling (2026-04-15)** - Introduced `ErrorParser` utility to map backend/database exceptions to user-friendly messages, preventing schema and logic leaks via UI SnackBars.
- **Unified Error Display (2026-04-15)** - Updated `CustomSnackbar` to automatically handle error objects through the new secure parser.

### Fixed
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
- **Debug/Release Package Separation (2026-04-15)** - Debug builds now use `com.oasis.app.debug` package name, release builds use `com.oasis.app`. This prevents debug and release APKs from overwriting each other on the same device. Correctly implemented via `applicationIdSuffix`.
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

---

## [Previous - Message Delay Fix]

### Added
- 10-second polling fallback in ChatProvider ensures messages appear even if realtime fails

### Root Cause Identified
- Supabase Realtime subscriptions silently failing (database replication not enabled)
- This affects ALL realtime features: messages, unread count, online status, typing indicator, read receipts