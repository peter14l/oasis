# Phase 3: Advanced Video/Voice Calling Experience

**Goal:** Implement a robust, multi-participant video/voice calling system with E2EE signaling, screen sharing, and media controls, integrated into the Oasis theme.

## 1. Research & Architecture Confirmation
- [ ] **Confirm Mesh Scalability:** Validate that Mesh WebRTC (P2P) is sufficient for up to 4-6 participants.
- [ ] **Screen Sharing API:** Confirm `flutter_webrtc` implementation details for `getDisplayMedia` on Android, iOS, and Windows.
- [ ] **E2EE Signaling Design:** Design the flow for encrypting SDP/ICE candidates using `SignalService` for multiple recipients.
- [ ] **Design Review:** Map the `AppTheme` to the new `CallingScreen` components.

## 2. Domain & Data Layer Updates
- [ ] **Update `CallEntity` and `CallParticipantEntity`**:
    - Add support for room-based calling.
    - Add `is_muted`, `is_video_on`, and `is_sharing_screen` flags to `CallParticipantEntity`.
- [ ] **Update `CallRepository`**:
    - Implement methods for joining/leaving rooms and updating participant status.
    - Implement methods for sending/receiving encrypted signaling messages.
- [ ] **Supabase Schema Update**:
    - Ensure `call_signaling` can handle encrypted payloads (already has `candidate` text, but might need a `type` for Signal message type).
    - Add `is_muted`, `is_video_on` to `call_participants` table.

## 3. `CallService` (WebRTC) Implementation
- [ ] **Refactor to Multi-Peer Mesh**:
    - Use `Map<String, RTCPeerConnection>` to manage connections to multiple peers.
    - Implement logic to establish new P2P connections when a participant joins.
- [ ] **Integrate E2EE Signaling**:
    - Wrap signaling messages (Offer/Answer/ICE) with `SignalService.encryptMessage` before sending.
    - Decrypt incoming signaling with `SignalService.decryptMessage`.
- [ ] **Media Controls**:
    - Implement `toggleMute()`, `toggleVideo()`.
    - Implement `startScreenShare()` and `stopScreenShare()`.
- [ ] **Participant Management**:
    - Handle `onTrack` for each peer and manage a map of `remoteStreams`.

## 4. Presentation Layer (UI/UX)
- [ ] **`CallingScreen` Implementation**:
    - Dynamic grid layout for participants (1, 2, 3, 4+ layouts).
    - Local video preview (floating or in grid).
    - Control bar: Mute, Camera, Screen Share, Switch Camera, End Call.
    - Participant list / Invite button.
- [ ] **`CallOverlay` / `MinimizedCall`**:
    - Allow users to navigate the app while in a call (PiP-like experience).
- [ ] **Incoming Call UI**:
    - Full-screen notification for incoming calls with Accept/Decline.
- [ ] **Theme Integration**:
    - Use `AppColors` and `AppTheme` for all calling components.
    - Ensure dark/light mode compatibility.

## 5. Verification & Testing
- [ ] **Unit Tests**:
    - Mock WebRTC and SignalService to verify signaling encryption/decryption.
- [ ] **Integration Tests**:
    - Verify call initiation and participant joining flow.
- [ ] **Manual Verification**:
    - Test 1:1 call (E2EE).
    - Test 3-way call (Mesh).
    - Test Screen Share.
    - Test Mute/Video toggles.
