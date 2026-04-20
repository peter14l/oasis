# Oasis: The Future of Private Social Connection

[![Flutter CI](https://github.com/your-repo/oasis/actions/workflows/pr_checks.yml/badge.svg)](https://github.com/peter14l/oasis/actions/workflows/pr_checks.yml)
[![Security: E2EE](https://img.shields.io/badge/Security-E2EE-blueviolet)](SECURITY.md)
[![Platform: Cross-Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Windows-blue)](https://flutter.dev)

Oasis is a privacy-first social platform built to foster genuine connections without compromising user data. We combine state-of-the-art encryption with a focus on digital wellbeing to create a "safe haven" in the social media landscape.

## 🚀 The Vision
In an era of invasive data harvesting, Oasis provides a decentralized and encrypted alternative for communities, creators, and individuals. Our mission is to return ownership of digital life to the users.

## ✨ Core Features
*   **Feed & Ripples:** A curated, high-performance social feed with short-form content interactions.
*   **Circles:** Privacy-centric groups with granular access control.
*   **Spaces:** Live, real-time voice and audio hangouts powered by WebRTC.
*   **Whisper Mode:** End-to-end encrypted messaging with self-destructing messages.
*   **Digital Wellbeing:** Built-in energy metering and screen-time tracking to encourage healthy usage patterns.

## 🛠 Technical Stack
*   **Frontend:** [Flutter](https://flutter.dev) (Dart) - Single codebase supporting Android, iOS, and Windows (Fluent UI).
*   **Backend:** [Supabase](https://supabase.com) (PostgreSQL) - Leveraging RLS policies for robust data isolation.
*   **Real-time:** WebRTC for high-quality, low-latency communication.
*   **Security:** Signal Protocol, RSA/AES-256 for military-grade E2EE.

## 🔐 Privacy & Security
Security is not an afterthought at Oasis; it's our foundation.
*   **End-to-End Encryption:** Your messages are yours alone. Read our [Security Whitepaper](SECURITY.md) for a deep dive into our E2EE architecture.
*   **Zero-Knowledge Philosophy:** We don't store your private keys.
*   **Transparency:** Open-source friendly architecture designed for auditability.

## 🛠 Getting Started (Development)

### Prerequisites
*   Flutter SDK (Stable)
*   Supabase CLI (optional, for backend migrations)
*   Firebase CLI (for push notifications)

### Installation
1. Clone the repository: `git clone https://github.com/your-repo/oasis.git`
2. Install dependencies: `flutter pub get`
3. Set up environment variables: Copy `.env.example` to `.env` and fill in your Supabase/Firebase credentials.
4. Run the app: `flutter run`

## 📊 Roadmap
- [x] Core E2EE Messaging
- [x] Multi-platform Support (Mobile + Desktop)
- [x] Wellness Engine v1.0
- [ ] Decentralized File Storage
- [ ] Oasis API for Creators
- [ ] DAO-governed Community Moderation

---
*Built with ❤️ by the Oasis Team. Join us in reclaiming the digital world.*