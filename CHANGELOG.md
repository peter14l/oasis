# Changelog

All notable changes to the Oasis project will be documented in this file. This project follows [Semantic Versioning](https://semver.org/).

## [1.1.29] - 2026-09-19

### Messaging & E2E Audio
- **Encrypted Voice Notes Decryption & Playback** - Fixed on-demand download and decryption flow in `VoiceBubble` and `VoiceMessagePlayer`, ensuring voice notes play reliably across sender and receiver clients without decryption stalls.
- **`send_message_v3` Metadata Integrity** - Updated Supabase RPC migration to return `voice_duration`, `encrypted_keys`, `iv`, `share_data`, and `signal_sender_content` in JSON responses, preventing loss of encryption headers.
- **Audio Error Handling & Validation** - Filtered benign transient native audio playback errors in `main.dart` error boundary and added validation to discard empty/corrupted voice recording files before transmission.
- **Adaptive Bubble Grouping & Sender Headers** - Dynamically adjusted bubble corner radii based on message group position (tight radii inside contiguous groups) and display sender labels on incoming group starts.
- **Jitter-Free Chat Input Area** - Refactored attachment and sticker/spoiler buttons into a stable fixed-size row container, eliminating layout jumping and text reflow while typing.
- **New Conversation FAB** - Added a dedicated floating action button to the Direct Messages screen for fast 1-tap message composition.

### Interface & Liquid Glass Navigation
- **Fluid Drag Magnification** - Implemented Apple-style fluid lens expansion that smoothly magnifies the indicator capsule width (+6px) and height (+3px) with enhanced refraction when grabbed and dragged.
- **Natural Compact Pill Geometry** - Re-centered and sized the bottom navbar pill dynamically according to destination count rather than stretching across screen width.
- **Drag Cancel Protection** - Added `onHorizontalDragCancel` gesture handler to gracefully spring the indicator back to the selected destination if an active drag is aborted.
- **Widget Test Suite** - Added automated unit and widget tests for `LiquidGlassBottomNavPill` geometry, responsive scaling, and interaction physics.

### In-Call Controls & VoIP Usability
- **Two-Tier Ergonomic Control Bar** - Divided in-call actions into an upper utility tier (Minimize, Screen Share, Add Participant) and a lower primary tier (Mute with active status color, Audio Output cycling, Video toggle, End Call).
- **Enlarged Touch Targets & Tooltips** - Added explicit tooltips and expanded minimum touch targets across call controls, post action chips, and circles navigation.
- **Study Session Safety Dialogs** - Redesigned focus room abandon confirmation buttons with clear destructive vs. keep-focusing action hierarchy.

## [1.1.28] - 2026-09-19

### Calling & Real-Time Communication
- **Handset Proximity Sensor (Ear-Detection Screen Blanking)** - Integrated native Android (`PowerManager.PROXIMITY_SCREEN_OFF_WAKE_LOCK`) and iOS (`isProximityMonitoringEnabled`) ear detection. Turning the screen black and disabling touch inputs when held to the ear during earpiece calls, matching WhatsApp and native phone call behavior.
- **In-Call Picture-in-Picture (Floating Call Overlay)** - Enabled draggable mini-window floating overlay across Android, iOS, and Windows. Users can minimize any active or incoming call to browse the app freely, view live video or pulsating participant avatars, and perform one-tap mute, end-call, or restore back to full screen.
- **Top-Bar Minimize Control** - Added quick-minimize chevron action in the call header for one-tap transition into floating overlay mode.
- **Audio Routing Resilience** - Default earpiece routing for voice calls, with seamless 3-way cycling across earpiece, speaker, and bluetooth devices.

## [1.1.27] - 2026-09-17

### Interface & Design
- **Horizontal Oval Liquid Glass Indicator** - Refined indicator shape into a horizontal oval (capsule) with smooth full-curvature corners (`height / 2`), providing an Apple visionOS/iOS-style liquid lens aesthetic.

## [1.1.26] - 2026-09-17

### Interface & Design
- **Rectangular Squircle Liquid Indicator** - Replaced circular indicator with a modern rounded rectangular squircle (`LiquidRoundedSuperellipse`) that spans navigation destination slots.
- **Wider Bottom Navbar Pill Layout** - Enhanced bottom pill width to responsively fill available screen width with clean margins.
- **Bottom Screen Anchoring** - Fixed vertical layout centering bug to anchor the pill and progressive blur backdrop firmly at the bottom of the screen.

## [1.1.25] - 2026-09-17

### Interface & Design
- **Apple-Style Liquid Glass Bottom Nav Pill** - Replaced standard navigation bar with an authentic Apple Liquid Glass floating navbar pill with continuous curvature and specular rim border.
- **Draggable Circular Indicator** - Interactive circular lens indicator with dedicated liquid glass refraction layer that can be dragged horizontally across navigation destinations with spring snapping physics and tactile haptic feedback.
- **Progressive Blur Backdrop** - Soft gradient progressive blur fading in behind the bottom floating pill without hard cutoffs.
- **Streamlined Label-Free Layout** - Removed destination text labels inside the pill for a cleaner, modern look.


### Interface & Design
- **Floating Bottom Navigation Bar** - Redesigned bottom navigation bar to be a floating capsule with glassmorphism/blur effects, margin/padding, and border decoration when transparency effects are on.
- **Stable Chat Input Bar Layout** - Combined the attachment, sticker/GIF, and spoiler toggle buttons into a single fixed-size container to completely prevent layout wrapping jitters and height jumps while typing.

### Push Notifications
- **FCM Permission Request** - Added explicit request for OS-level runtime notifications permission on Android 13+ to ensure FCM messages are received and displayed successfully.

## [1.1.13] - 2026-07-28

### Security & Privacy
- **Stealth Decoy App Mode** - Added a stealth setting to completely disguise the app as a simple "Calendar" app on the home screen (supporting dynamic icon and name rebranding on Android, and dynamic alternate icon on iOS).
- **Multi-Finger Gesture Unlock** - Implemented a secret raw pointer listener requiring a **triple-finger swipe down** to reveal the security PIN sheet on the decoy screen.
- **PIN-Protected Unlock** - Locked decoy calendar screen behind a secure 6-digit PIN bottom sheet verification.
- **Background & Screen-Lock Auto-Locking** - Integrated app lifecycle listeners that instantly lock the app back to its decoy state when minimized or when the device screen locks.
- **Stealth Settings Panel** - Added interface inside Privacy settings to toggle Stealth Mode, setup a 6-digit PIN with double-entry check, and change the PIN.

### Web & Platform Compatibility
- **Web Compilation Refactoring** - Fixed web compilation errors by resolving window effect invocations and titles that rely on non-web package signatures.
- **Database & Migration Updates** - Optimized schema definitions and cleaned up database migration logs.
- **Cleanup** - Evicted massive debug trace files, dump logs, and obsolete plans to optimize repository size.

## [1.1.11] - 2026-05-15

### UI/UX & Theming
- **Liquid Glass Effect** - Full implementation of the experimental glassmorphism engine across all platforms.
- **Micro-animations** - Enhanced interactive feedback and fluid transitions in feed and messaging.
- **Collaborator Support** - Added infrastructure for shared posts and collaboration requests.

### Fixes & Stability
- **WebRTC Calling** - Resolved audio routing issues and improved ICE candidate buffering for more stable connections.
- **E2EE Decryption** - Fixed fallback logic for secure message decryption and notification previews.
- **Cursor Pagination** - Implemented robust cursor-based pagination for feeds and conversations to improve performance.
- **Security Hardening** - Further refinement of RLS policies to prevent recursion and ensure data isolation.

## [1.1.10] - 2026-05-10

### Fixes & Performance
- Initial support for Liquid Glass effects.
- Bug fixes in auth and messaging providers.

## [1.1.9] - 2026-05-09

### Post-Quantum Security (PQ-DR)
- **Hybrid PQ-Aura E2EE** - Integrated Rust-based Post-Quantum encryption layer via `PQ-DR` submodule to protect conversations against future quantum decryption.
- **PQ Session Indicators** - Added visual "Shield" indicators in chat headers to provide real-time verification of post-quantum secure handshakes.
- **Hardened Backend Security** - Comprehensive audit and hardening of Row Level Security (RLS) policies and column-level permissions across all core tables.
- **Multi-Account E2EE Notifications** - Implemented data-only FCM handling that allows for secure, on-the-fly decryption of notification previews even when switching between multiple active accounts.

### UI/UX & Theming (Liquid Glass)
- **Liquid Glass Rendering** - Introduced an experimental glassmorphism engine (Oasis Liquid) for headers, navigation bars, and bottom sheets with settings-toggle support.
- **Liquid FAB Cluster** - Replaced standard FAB with a morphing animation cluster for organic, fluid interaction.
- **Experimental Feed Layouts** - Added four new layout engines for the main feed:
  - **Spatial Glider**: A 2.5D staggered masonry grid with depth-based shadows.
  - **Focused Flow**: Magazine-style vertical snapping with ambient blurred backgrounds.
  - **Living Canvas**: Borderless organic layout with glowing "connecting fibers."
  - **Classic**: The refined, high-performance original layout.
- **Desktop Refinements** - Integrated Mica and Acrylic window effects for Windows/macOS and migrated to native Fluent UI components for desktop-class interactions.

### Feature Enhancements
- **Circles V2** - Major overhaul of the community system:
  - Transitioned from raw User IDs to full profile resolution (Names/Avatars) in member lists.
  - Private Circle feeds ensure only members can view and interact with shared posts.
  - Dedicated circle-specific creation flows and moderation tools.
- **In-App Updater** - Completely rebuilt update infrastructure:
  - Automated APK downloads via public R2 buckets.
  - Integrated `REQUEST_INSTALL_PACKAGES` and `FileProvider` for secure, one-tap installation on Android.
  - Native system-level installation prompts.
- **WebRTC Calling V2** - Significant stability improvements to the calling engine:
  - Hardware-optimized rendering sessions and ICE candidate buffering.
  - Advanced audio routing to resolve focus contention across platforms.
  - Call diagnostics and real-time connectivity status reporting.

### Fixes & Performance
- **Optimized Media Loading** - Integrated `CachedNetworkImage` and optimistic UI states for instant media previews in chat.
- **Parallel Decryption** - Enhanced chat responsiveness by parallelizing E2EE decryption workloads across isolates.
- **Storage Consolidation** - Unified secure storage providers to ensure data persistence and prevent state leakage during account switching.
- **Navigation Resilience** - Resolved GoRouter assertion errors by refactoring full-screen route handling outside of the ShellRoute context.

---

## [1.1.1] - 2026-05-01

### Added
- **Major Overhaul of Circles** - Transitioned to a restricted, feed-centric group conversation system.
- **Private Circle Feeds** - Only circle members can view and interact with circle posts.
- **Dedicated Post FAB** - Create posts directly within specific circles.

### Fixed
- **Row Level Security (RLS)** - Improved security constraints for circle-specific content.
- **Separated Feed Content** - Isolated circle content from the main application feed.

---

## [1.0.0+1] - 2026-04-30

### Added
- **Initial Release** - Welcome to Oasis!
- **End-to-End Encrypted Messaging (Whisper Mode)**.
- **Digital Wellbeing Engine**.
- **Multi-platform Support (Android, iOS, Windows, macOS, Web)**.
