# Oasis Technical Stack Manifest

**Oasis** is built as a high-performance, privacy-first relational platform. The architecture emphasizes **Data Sovereignty**, **End-to-End Encryption (E2EE)**, and **Cross-Platform Consistency**.

---

## 🏗️ Core Architecture

### Frontend: Flutter (3.24+)
- **Cross-Platform:** Single codebase targeting **Android, iOS, and Windows**.
- **State Management:** `Provider` for lightweight, predictable reactive state.
- **Navigation:** `go_router` for declarative routing and deep-linking support.
- **Persistence:** 
  - `sqflite` for high-volume relational local data (Chats, Feed).
  - `flutter_secure_storage` for cryptographic keys and sensitive tokens.
  - `shared_preferences` for non-sensitive application settings.
- **Real-time:** Integrated with Supabase Realtime for instant messaging and presence updates.

### Backend: Supabase (PostgreSQL + Go)
- **Database:** PostgreSQL with Row Level Security (RLS) enforcing multi-tenant isolation at the engine level.
- **Authentication:** GoTrue-based auth supporting Email/Password, Unique Usernames, Google Sign-In, and Apple Sign-In.
- **Serverless Logic:** Supabase Edge Functions (Deno/TypeScript) for:
  - Secure payment verification (Razorpay/PayPal).
  - Voice-to-Text transcription (OpenAI Whisper).
  - Push Notification dispatching (FCM).
- **Storage:** Supabase Storage buckets with fine-grained RLS for media and encrypted backups.

---

## 🔒 Security & Privacy Model

### End-to-End Encryption (E2EE)
- **Protocol:** Hybrid RSA-2048 and AES-256 (CBC mode).
- **Key Derivation:** **Argon2id** (3 iterations, 32MB memory) used for deriving 256-bit AES keys from 6-digit user PINs.
- **Identity:** Public keys are hashed and stored on-server; private keys are encrypted locally with Argon2id-derived keys before being optionally backed up to the cloud (Data Sovereignty).
- **Recovery:** 24-character high-entropy recovery codes used as an alternative derivation path for key restoration.

### Signaling & Metadata
- **E2EE Signaling:** All call signaling (WebRTC offers/answers/candidates) is encrypted using **Signal Protocol** (libsignal) before entering the Supabase Realtime channel.
- **Metadata Protection:** No likes, view counts, or global engagement metrics are stored or transmitted.

---

## 📞 Communications Infrastructure

- **WebRTC:** Peer-to-peer (Mesh) architecture for voice and video calling.
- **SFU Readiness:** Signaling designed to facilitate a future move to an SFU (Selective Forwarding Unit) for large-scale calls.
- **Codecs:** VP8/H.264 for video; Opus for high-fidelity audio.
- **Features:** Screen sharing, background ringtones, and participant management.

---

## 💰 Monetization & Payments

- **Primary Gateway (India):** **Razorpay** (Fully Integrated via Edge Functions) supporting UPI, Cards, and Netbanking.
- **Global Scalability:** **RevenueCat** backbone is implemented; full integration scheduled for Play Store/App Store rollout.
- **Security:** HMAC-SHA256 signature verification performed in isolated Edge Functions to prevent paywall bypasses.

---

## 🌿 Intentionality & Wellness

- **Digital Wellbeing:** Native background services for tracking screen time and "Digital Energy" consumption.
- **Ambient UI:** Dynamic theme engine that responds to session duration and time-of-day.
- **Intentional Friction:** Procedural "Landing Moments" and "Session Summaries" designed to break reflexive app usage.

---

## 📈 Dev-Ops & Tooling

- **Error Tracking:** Sentry (Flutter + Native).
- **CI/CD:** GitHub Actions for automated APK and Windows MSIX builds.
- **Analytics:** Privacy-first, user-controlled analytics sync (optional opt-in).
