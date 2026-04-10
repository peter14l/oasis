# Oasis Project - Full Codebase Security & Production Readiness Review

**Reviewer:** Senior Flutter Developer & Security Architect
**Date:** Current
**Scope:** Full codebase analysis (excluding the Calls feature)
**Verdict:** 🛑 **BLOCKER - NOT READY FOR PRODUCTION**

---

## 1. Executive Summary

Based on a comprehensive review of the current Flutter and Supabase codebase, **the application is currently not ready for a beta release on Google Play.** 

While the UI and features are taking shape, there are **critical security vulnerabilities** allowing instantaneous paywall bypasses, major **Google Play Store policy violations**, and the actual payment processing logic is either missing or deeply flawed. Furthermore, the database migration structure deviates from standard Supabase workflows.

Releasing this version would result in zero revenue due to trivial exploits and an immediate ban from the Google Play Store for payment policy violations.

---

## 2. Security & Paywall Vulnerabilities (CRITICAL)

### 🚨 Vulnerability: Trivial Paywall Bypass via `user_metadata`
**Severity:** CRITICAL
**Location:** Frontend (`lib/services/`, `lib/features/`) & Backend (`MASTER_DATABASE_SCHEMA_FINAL.sql`)

**Description:**
The entire premium/paywall logic in the Flutter frontend relies on checking the user's `userMetadata`:
```dart
final isPro = user?.userMetadata?['is_pro'] == true;
```
Simultaneously, the Supabase backend has a highly privileged trigger (`handle_user_metadata_update`) that executes with `SECURITY DEFINER`:
```sql
CREATE OR REPLACE FUNCTION public.handle_user_metadata_update()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.raw_user_meta_data->>'is_pro' IS NOT NULL THEN
    UPDATE public.profiles
    SET is_pro = (NEW.raw_user_meta_data->>'is_pro')::BOOLEAN
    WHERE id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**Exploit:**
In Supabase, `user_metadata` is fully controllable by the client. A malicious user (or anyone with a basic script) can simply call:
```javascript
supabase.auth.updateUser({ data: { is_pro: true } })
```
This instantly bypasses the paywall. The backend trigger then executes as a superuser and permanently syncs this forged Pro status to the strictly-protected `profiles` table.

**The "Metadata Ghost" Problem:**
Even after adding a `subscriptions` table, if this trigger remains, a user can forge their metadata to overwrite a valid (or expired) subscription record in the `profiles` table.

---

## 3. Cross-Platform Integration & Compliance (CRITICAL)

### 🚨 Issue: Google Play Store Policy Violation
**Severity:** CRITICAL (High Business Risk)
**Location:** `lib/screens/oasis_pro_screen.dart` (Redirection to web checkout)

**Description:**
The app currently redirects users to an external web portal (`web_landing`) to handle payments to avoid Google's fees.
Google Play's "Payments" policy strictly requires that **digital goods and services** consumed within an app (like Pro features) **MUST** use Google Play's Billing System.

**Consequence:**
The app will be **rejected** during review or **banned** shortly after release. This is a non-negotiable requirement for Google Play and the Apple App Store.

### 🚨 Issue: Insecure Edge Function Logic
**Severity:** CRITICAL
**Location:** `supabase/functions/paypal-verify/index.ts`

**Description:**
The verification function checks if a PayPal order is `COMPLETED`, but **does not verify if the amount paid matches the plan price**.

**Exploit:**
A user could create a PayPal order for $0.01 on their own site and send that `orderId` to the verify function. The function will see the order is "COMPLETED" and grant a full Pro subscription.

---

## 4. Flutter Code Inconsistencies

**Severity:** HIGH
**Location:** `lib/services/wellness_service.dart` (Line 172)

**Description:**
While `SubscriptionService.dart` has been partially updated, other services like `WellnessService.dart` still rely on the insecure `userMetadata?['is_pro']` check. This creates "soft spots" in the application where security is unevenly applied.

---

## 5. Backend Migration & Schema Fragmentation

**Severity:** MEDIUM
**Location:** Root SQL files vs. `supabase/migrations/`

**Description:**
`MASTER_DATABASE_SCHEMA_FINAL.sql` is missing the `subscriptions` table and the `increment_xp` RPC, which are required for the app to function. Keeping database schemas in the root directory rather than using the official Supabase CLI migration system is an anti-pattern that leads to this type of fragmentation.

---

## 6. Next Steps (REVISED)

Before proceeding with any release, you MUST:
1. **Branching:** Create a dedicated feature branch for the payment overhaul.
2. **Backend Hardening:**
    - Delete the `handle_user_metadata_update` trigger and function.
    - Move all SQL logic into `supabase/migrations/`.
    - Update Edge Functions to validate payment amounts/currency against plan definitions.
3. **In-App Purchase (IAP) Implementation:**
    - Integrate `in_app_purchase` for Android, iOS, and macOS.
    - Configure Google Play Console and App Store Connect products.
4. **Razorpay Windows Integration:**
    - Implement a secure Razorpay checkout flow specifically for the Windows MSIX version.
5. **Unified Security:** Replace all `userMetadata` checks in Flutter with a centralized, secure check via `SubscriptionService`.