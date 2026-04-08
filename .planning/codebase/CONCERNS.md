# Codebase Concerns

**Analysis Date:** 2024-05-28

## Tech Debt

**Architecture Migration (Feature vs Screens):**
- Issue: The codebase is in the middle of a migration from a flat `lib/screens` structure to a modular `lib/features` architecture. Many screens exist in both locations or are partially migrated.
- Files: `lib/screens/chat_details_screen.dart`, `lib/features/messages/presentation/screens/chat_screen.dart`, `lib/routes/app_router.dart`
- Impact: High cognitive load for developers, risk of modifying the wrong file, and bloated application size due to duplicated logic.
- Fix approach: Complete the migration by moving all active screens into `lib/features`, updating `app_router.dart` to use the new locations, and deleting the legacy files in `lib/screens`.

**RevenueCat Integration Mocked:**
- Issue: The subscription purchase flow is currently mocked with a `Future.delayed` and a comment `TODO: Implement actual revenuecat purchase flow here`.
- Files: `lib/features/settings/presentation/screens/subscription_screen.dart`
- Impact: Users cannot actually subscribe to the Pro tier, and no revenue will be generated in production.
- Fix approach: Integrate the official `purchases_flutter` SDK and connect it to the backend webhooks to grant pro status correctly.

## Known Bugs

**Legacy Auto-Restore Key Migration Edge Cases:**
- Symptoms: Users migrating from older versions of the app might fail to decrypt their chat history if the legacy ghost keys are corrupted or missing from secure storage before the v2 security upgrade.
- Files: `lib/features/messages/data/encryption_service.dart`
- Trigger: Launching the app on an old install before setting up a PIN.
- Workaround: Users must manually generate a recovery key or rely on fallback mechanisms if implemented.

## Security Considerations

**Vulnerable Legacy Backup Key Derivation:**
- Risk: The `deriveLegacyBackupKey` method uses a simple SHA-256 hash of the `userId` to generate a 32-byte AES key for encrypting private RSA keys. This is highly predictable and makes any leaked database dump immediately vulnerable to decryption of users' private keys.
- Files: `lib/services/key_management_service.dart`, `lib/features/messages/data/encryption_service.dart`
- Current mitigation: The code is marked as `🚩 VULNERABLE` and is only used for backward compatibility during the v2 migration.
- Recommendations: Force-migrate all active users to the new Argon2id PIN-based derivation (`deriveSecureBackupKey`) as soon as possible and completely remove the legacy logic. Delete legacy encrypted keys from the database.

**Client-Side Pro Status Checks for Vault Authentication:**
- Risk: `VaultService` checks `isPro` status by reading `userMetadata?['is_pro']` from the Supabase auth session. Client-side claims can potentially be manipulated on rooted/jailbroken devices to bypass biometric authentication requirements or access premium features.
- Files: `lib/services/vault_service.dart`
- Current mitigation: It checks local auth session data.
- Recommendations: Ensure that any sensitive operations gated by the Pro status are also strictly validated on the backend/database via Row Level Security (RLS).

## Performance Bottlenecks

**Scroll and Interaction Rebuilds in Large Screens:**
- Problem: Extremely large screen widgets (1,400+ lines) call `setState` on rapid events like `_onScroll` or pointer movements (`_triggerLocalPulse`).
- Files: `lib/features/canvas/presentation/screens/timeline_canvas_screen.dart`, `lib/features/stories/presentation/screens/create_story_screen.dart`
- Cause: Using `setState` at the top level of a large `StatefulWidget` forces the entire widget tree to rebuild on every scroll frame or mouse hover, causing severe UI jank, especially on lower-end devices.
- Improvement path: Refactor the scroll tracking and pulse animations to use `ValueNotifier` or dedicated animated builders (like `ListenableBuilder`) that only rebuild the specific UI components (like the parallax background or the ripple effects) without triggering a full screen rebuild.

## Fragile Areas

**Monolithic Screen Files:**
- Files: `lib/features/stories/presentation/screens/create_story_screen.dart` (1843 lines), `lib/features/messages/presentation/screens/direct_messages_screen.dart` (1733 lines)
- Why fragile: These files mix UI layout, local state management, network calls, and business logic into massive classes. A small change to one part of the UI can easily break state logic or cause unintended rebuilds elsewhere in the file.
- Safe modification: Break these screens down into smaller, focused widgets and move state management logic into Providers or BLoCs/Riverpod controllers before adding new features.
- Test coverage: Almost completely untested.

## Scaling Limits

**Realtime Channel Subscriptions (Canvas Pulses):**
- Current capacity: Supabase Realtime handles standard broadcast traffic, but sending a pulse broadcast on every `onLongPressStart` and tracking presence on `onHover` without explicit client-side rate limiting can overwhelm the connection.
- Limit: High concurrent users in a single Canvas session could hit Supabase websocket message limits or cause severe battery drain and network congestion on client devices.
- Scaling path: Implement strict client-side debouncing and throttling for presence updates and pulse broadcasts. Group rapid events before dispatching them to the realtime channel.

## Missing Critical Features

**In-App Purchases Implementation:**
- Problem: The subscription flow is a mock UI.
- Blocks: Monetization and granting of Pro features securely.

## Test Coverage Gaps

**Core Feature and UI Tests:**
- What's not tested: There are only ~19 test files in the entire repository. The majority of the presentation layer (screens, widgets), navigation routing (`app_router.dart`), and complex state management logic have zero tests.
- Files: `lib/features/**/*.dart`, `lib/screens/**/*.dart`
- Risk: High risk of regressions during the ongoing architecture migration. Changes to legacy screens might break migrated features without developers noticing until runtime.
- Priority: High. Need integration and UI tests for critical flows (Authentication, Messaging, Canvas interactions, and Feed browsing).

---

*Concerns audit: 2024-05-28*