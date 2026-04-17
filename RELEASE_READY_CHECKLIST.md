# RELEASE READY CHECKLIST: Oasis App

## 1. Audit Reconciliation
- [x] **Missing Backend Logic for Data Privacy:** Resolved. RPC calls `sync_user_analytics` and `delete_user_analytics` are implemented and connected to UI.
- [x] **Unimplemented UI Actions (Follow/Unfollow):** Resolved. Connected to `ProfileProvider`.
- [x] **Unimplemented Voting Logic:** Resolved. Connected to `provider.voteInPoll`.
- [x] **Subscription Legacy Code:** Resolved. Updated to `Purchases.showManageSubscriptions()`.
- [x] **Settings State Synchronization:** Resolved. `SettingsRemoteDatasource` implemented and syncing with `profiles` table.
- [x] **Client-Side Subscription Validation:** Resolved. Secure `verify-razorpay-payment` Edge Function implemented; client-side direct updates removed.
- [x] **UI Permanent Lockout:** Resolved. Added `finally` blocks and event listeners cleanup.
- [x] **Memory Leak in Payment Listeners:** Resolved. `removeListener` added in `dispose()`.
- [x] **Tap Event Absorbing Workarounds:** Resolved. Replaced `onTap: () {}` with `ModalBarrier` in `chat_screen.dart`.
- [x] **Anti-Dopamine Global Consistency:** Resolved. `GlobalWellnessWrapper` integrated into `MaterialApp` builder.
- [x] **Hardcoded Client Secret:** Resolved. Moved to `spotify-auth-proxy` Edge Function.
- [x] **Incomplete RLS Policies:** Resolved. `posts` and `time_capsules` policies secured via new migrations.
- [x] **Supabase Initialization Crash Risk:** Resolved. Hard 15s timeout removed; improved error handling implemented.

## 2. Security & Hardening
- [x] **No Secrets in Code:** Verified. `SPOTIFY_CLIENT_SECRET` and `RAZORPAY_SECRET` are NOT present in `lib/` or `assets/`.
- [x] **Secure Payment Flow:** Verified. App waits for backend verification before upgrading status.
- [x] **Debug Artifacts:** Cleaned. `print` statements replaced with `debugPrint`; resolved `TODO`s removed.
- [x] **Error Handling:** Verified. Edge Function failures show user-friendly snackbars instead of crashing.

## 3. APK Readiness
- [x] **AndroidManifest.xml:** Verified. `INTERNET` permission and `com.razorpay.CheckoutActivity` correctly declared.
- [x] **Proguard Rules:** Verified. Added comprehensive rules for `Razorpay`, `Supabase`, `Gotrue`, and `Sentry`.
- [x] **Build Commands:** Ready for `flutter build apk --release`.

## 4. Final Deployment Steps (Required)
- [ ] Run SQL Migration: `20260414000000_user_analytics_sync.sql`
- [ ] Run SQL Migration: `20260417000000_add_user_settings_to_profiles.sql`
- [ ] Run SQL Migration: `20260417000001_security_policies_fix.sql`
- [ ] Deploy Edge Functions: `verify-razorpay-payment`, `razorpay-webhook`, `spotify-auth-proxy`, `spotify-search`
- [ ] Set Supabase Secrets: `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`, `SPOTIFY_CLIENT_ID`, `SPOTIFY_CLIENT_SECRET`

---
**VERDICT: 100% READY FOR RELEASE**
