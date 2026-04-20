# Security Whitepaper: Oasis

Oasis is designed with a **Security-First** and **Privacy-by-Design** philosophy. This document outlines the technical architecture of our security model, specifically focusing on our End-to-End Encryption (E2EE) implementation and backend security.

## 1. End-to-End Encryption (E2EE)
Oasis uses a multi-layered encryption approach to ensure that only the sender and the recipient can read message content. Not even the Oasis servers or Supabase database administrators can access private communication.

### Encryption Protocols
*   **Signal Protocol Support:** We utilize the Double Ratchet Algorithm for forward secrecy and post-compromise security in real-time communication.
*   **Asymmetric Encryption (RSA):** Used for initial key exchange and identity verification.
*   **Symmetric Encryption (AES-256-GCM):** Used for high-performance encryption of message payloads and media attachments.

### Key Management
*   **Local Vault:** User private keys are stored in the device's secure enclave (iOS Keychain / Android Keystore) and are never transmitted to our servers.
*   **Identity Keys:** Each device generates a unique long-term identity key pair.
*   **PIN-based Recovery:** Users can securely migrate keys to new devices using a zero-knowledge PIN-based recovery mechanism.

## 2. Backend Security (Supabase & RLS)
Our backend is powered by Supabase, leveraging PostgreSQL's **Row Level Security (RLS)** as a primary defense.

*   **Zero-Access Policies:** RLS policies are strictly enforced on every table. Users can only read or write data they explicitly own or have been granted access to (e.g., within a Circle or Conversation).
*   **JWT Authentication:** All requests are authenticated via Supabase Auth using cryptographically signed JSON Web Tokens.
*   **Encrypted Storage:** Any metadata or non-E2EE data that requires high sensitivity is encrypted at rest using industry-standard protocols.

## 3. Communication Security
*   **WebRTC:** Audio and video calls are transmitted over peer-to-peer (P2P) connections using SRTP (Secure Real-time Transport Protocol).
*   **TLS 1.3:** All client-server communication is encrypted using TLS 1.3, protecting data in transit from man-in-the-middle attacks.

## 4. Digital Wellbeing and Safety
Oasis goes beyond encryption to provide security through safety features:
*   **Whisper Mode:** Support for ephemeral messaging with customizable expiration times.
*   **Local Authentication:** Optional biometric (FaceID/TouchID) or PIN lock for the app itself.
*   **Moderation:** Decentralized moderation tools for Circles to prevent abuse while maintaining privacy.

---
*For security researchers: If you find a vulnerability, please contact us at security@oasis.app.*