# Morrow 2FA and Subscription Implementation Plan

This document details the technical and strategic roadmap for implementing Multi-Factor Authentication (MFA/2FA) and a localized global revenue system for Morrow.

---

## 1. Multi-Factor Authentication (MFA/2FA)
We will utilize Supabase's native MFA (TOTP) support to secure user accounts.

### Technical Implementation (Supabase TOTP)
1. **Enrollment Flow**:
   - User navigates to `Settings > Two-Factor Authentication`.
   - App calls `supabase.auth.mfa.enroll({ factorType: 'totp' })`.
   - Supabase returns a QR code URI and a secret key.
   - App displays the QR code (using `qr_flutter`) and the manual entry key.
2. **Verification & Activation**:
   - User enters the 6-digit code from their authenticator app (Google Authenticator, Authy, etc.).
   - App calls `supabase.auth.mfa.challenge({ factorId })` then `supabase.auth.mfa.verify({ factorId, challengeId, code })`.
   - Upon success, MFA is marked as `active` for the user session.
3. **Login Integration**:
   - If MFA is enabled, the initial login returns an `AMR` (Authentication Method Reference) indicating further factors are required.
   - App redirects the user to an MFA verification screen before granting full access.

### UI Implementation
- **File**: `lib/screens/settings/two_factor_auth_screen.dart`
- **Elements**: 
  - Status indicator (Enabled/Disabled).
  - Setup wizard (QR Code display, Secret key copy).
  - Verification input field.
  - Backup codes generation and storage.

---

## 2. Revenue & Global Subscription System
The pricing model is designed to be affordable worldwide using Purchasing Power Parity (PPP) while ensuring we cover Supabase's 2026 Pro infrastructure costs ($25/mo base + compute).

### Tier Structure
| Feature | Free | Plus (Essential) | Pro (Elite) |
| :--- | :--- | :--- | :--- |
| **Ads** | With Ads | Ad-Free | Ad-Free |
| **Vaults** | 1 Vault | 5 Vaults | Unlimited |
| **Canvas** | Standard | High-Res | Ultra-HD + AI Tools |
| **MFA** | Standard | Advanced | Priority Support |
| **Storage** | 1GB | 10GB | 100GB |

### Regional Pricing Strategy (Monthly)
*Prices are calculated based on 2026 PPP factors to maximize conversion in emerging markets.*

| Region | Currency | Plus Tier | Pro Tier |
| :--- | :--- | :--- | :--- |
| **Global/USA** | USD | **$4.99** | **$9.99** |
| **Europe** | EUR | **€4.99** | **€9.99** |
| **India** | INR | **₹149** | **₹299** |
| **UK** | GBP | **£4.49** | **£8.99** |

*Rationale: ₹299 in India (approx. $3.55 market value) has the equivalent "feel" of a $9.99 subscription in the US, aligning with services like Netflix and Spotify India.*

---

## 3. Payment Gateway Integration

### India: UPI (Unified Payments Interface)
- **Provider**: Razorpay or PayU (Flutter SDK).
- **Flow**:
  - User selects UPI.
  - App triggers the UPI intent (PhonePe, Google Pay, Paytm).
  - Transaction status is verified via server-side webhooks.
- **Why**: UPI is the dominant payment method in India, offering near-zero friction for mobile users.

### International: PayPal
- **Provider**: PayPal Braintree SDK.
- **Flow**:
  - Standard PayPal Express Checkout or Credit/Debit card processing.
  - Webhook integration to update subscription status in Supabase.

---

## 4. Scalability & Cost Alignment
- **Infrastructure Coverage**: Supabase Pro ($25/mo) supports up to 100,000 Monthly Active Users (MAU).
- **Profitability Threshold**: With an average revenue per user (ARPU) of $2.50 (low estimate accounting for PPP), we reach break-even for infrastructure costs with just **10 paying users**.
- **Database Scaling**: As the Pro tier exceeds 8GB or requires more compute, the subscription revenue will fund "Small" (+$40/mo) or "Medium" (+$90/mo) compute upgrades automatically.

---

## 5. Implementation Roadmap
1. **Phase 1 (MFA)**: Update `TwoFactorAuthScreen` to handle Supabase enrollment and verification.
2. **Phase 2 (Subscription Logic)**: Create a `SubscriptionProvider` that detects user location (via IP or Locale) and displays the correct PPP-adjusted price.
3. **Phase 3 (Payment Gateways)**: Implement Razorpay SDK for India and PayPal for the rest of the world.
---

## 6. Sustainability & Risk Mitigation (The "Free User" Shield)
To support a permanent chat history (Instagram/WhatsApp style) for free users without incurring excessive costs, we will implement the following strategies:

### A. Tiered Media Quality (Storage & Bandwidth)
- **Free Users**: All media (images, videos, voice-notes) is automatically compressed on the client-side before upload using `flutter_image_compress` and `video_compress`. Max resolution: 1080p.
- **Pro Users**: Can toggle "Original Quality" uploads, utilizing more of the 100GB Supabase storage quota they help pay for.
- **Impact**: Reduces storage consumption by ~70% for free users, ensuring the 100GB bucket lasts significantly longer.

### B. Security Hardening (Pro Status Integrity)
- **Problem**: The current `is_pro` check in the codebase allows the client to update its own metadata.
- **Solution**: 
  1. Remove `debugToggleProStatus` from the production build.
  2. The `is_pro` status in `public.profiles` will be made **read-only** for users via RLS (Row Level Security).
  3. Status updates will ONLY occur via a server-side Supabase Edge Function that verifies a valid transaction ID from Razorpay or PayPal.

### C. Database Optimization (8GB Limit)
- **Lean Indexing**: We will index only essential columns (id, conversation_id, sender_id, created_at) to keep the 8GB database quota focused on message content.
- **Metadata Archiving**: For free users, older metadata (e.g., who reacted to a message 2 years ago) may be flattened to save space, while the message content remains untouched.

### E. Storage Management & User Cleanup Tools
To empower users and maintain a lean infrastructure, we will implement a "Storage Dashboard":
1. **Visual Breakdown**: A "Storage Usage" screen in Settings showing a breakdown of space used by Images, Videos, and Voice Messages.
2. **Bulk Cleanup Tools**:
   - **"Clear Old Media"**: One-tap option to delete all media attachments older than 3, 6, or 12 months (while keeping the text history intact).
   - **"Large Chat Cleanup"**: A list of conversations ranked by storage size, allowing users to clear media from specific high-volume chats.
3. **Database & Storage Sync**: Deleting a media record from the dashboard will trigger a `storage.remove()` call in Supabase to permanently free up the physical space.
4. **Benefit**: This allows free users to "reset" their 2GB threshold manually, preventing them from being forced to upgrade if they'd rather just clean their history, while directly lowering your Supabase Storage bill.

