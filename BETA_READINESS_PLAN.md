# Oasis Beta Readiness Plan

This document outlines the critical issues and performance bottlenecks identified during the codebase analysis. These must be addressed before the app is ready for production beta testing.

## 1. Security Blockers (High Priority)

### 1.1 Insecure Legacy Key Derivation (E2EE)
- **Status:** **FIXED**
- **Issue:** Legacy users had no recovery path if they forgot their PIN.
- **Action:** 
    - [x] Implemented `needsRecoveryBackup` detection.
    - [x] Added automated recovery key generation for legacy PIN users.
    - [x] Forced V2 Argon2id PIN-based key derivation for all new setups.

### 1.2 Hardcoded Environment URLs
- **Status:** **FIXED**
- **Issue:** Staging URLs (`oasis-web-red.vercel.app`) were hardcoded across 12+ files.
- **Action:**
    - [x] Created `AppConfig` class driven by `.env`.
    - [x] Updated all references to use `AppConfig.getWebUrl()`.

### 1.3 Direct Subscription Mutations
- **Status:** **FIXED**
- **Issue:** `SubscriptionService` directly updated the `profiles` table from the client.
- **Action:**
    - [x] Removed direct `profiles` table update from client-side code.
    - [x] Restricted `debugToggleProStatus` to `kDebugMode` and local-only state.

---

## 2. Performance Bottlenecks

### 2.1 N+1 Query in Conversations
- **Issue:** `ConversationRemoteDatasource` fetches conversations in a loop.
- **Action:** 
    - [ ] Refactor to use a single `.inFilter('id', ids)` query.

### 2.2 Expensive Custom Painters (Blur)
- **Issue:** `MeshGradientBackground` and `StarryNightBackground` use `MaskFilter.blur` inside 60fps loops.
- **Action:** 
    - [ ] Replace dynamic blurs with optimized `BackdropFilter` or static assets.

### 2.3 SharedPreferences Overload
- **Issue:** Large JSON strings (Feeds, Chats) are being stored in `SharedPreferences`.
- **Action:** 
    - [ ] Migrate heavy data caching to a local SQLite database (e.g., `sqflite` or `drift`).

---

## 3. Memory & Resource Leaks

### 3.1 Unbounded Timers
- **Issue:** `DigitalWellbeingService` and `EnergyMeterService` timers may leak.
- **Action:** 
    - [ ] Audit all services for `dispose()` logic and explicit timer cancellation.

### 3.2 Realtime Channel Leaks
- **Issue:** `CanvasService` caches channels in a map but doesn't always clean them up.
- **Action:** 
    - [ ] Implement a robust cleanup mechanism for `_presenceChannels`.

---

## 4. Architectural Improvements

### 4.1 Bypassing Repositories
- **Issue:** Some screens call Supabase clients directly.
- **Action:** 
    - [ ] Enforce repository pattern across all features.

### 4.2 Centralized Logging
- **Issue:** Errors are not reported to Sentry in most `catch` blocks.
- **Action:** 
    - [ ] Implement a global `Logger` service.

---

## 5. Feature Completion Checklist

- [ ] **Story Creation:** Finish UI and background processing.
- [x] **Voice Transcription:** Integrated Multilingual Whisper via Edge Functions.
- [ ] **Two-Factor Auth:** Implement 2FA flow.
- [ ] **Zen Mode:** Implement "Quiet all noise" logic.
- [ ] **Voice Comments:** Enable audio recording/playback for post comments.
- [x] **Secure Checkout:** Implemented secure redirect flow and Pro member validation in app.
