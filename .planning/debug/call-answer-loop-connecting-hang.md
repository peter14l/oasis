---
status: verifying
trigger: "Find and fix the 'Connecting' hang and 'Auto-answer loop' based on Supabase data"
created: 2026-04-22T15:00:00Z
updated: 2026-04-22T15:30:00Z
---

## Current Focus

hypothesis: Multiple 'Answer' signals were sent due to a race condition in `_subscribeToParticipants` on the Host side, causing multiple Offers to be sent. User B processed each Offer and sent an Answer because `_getOrCreatePeerConnection` and `_handleSignalingData` lacked race protection and state guards. 'Offer' appeared as Type 3 instead of Type 1 because of a mapping mismatch between the Signal library and DB expectations.
test: Applied race protection using `_pendingPeerConnections` and added signaling state checks. Implemented 3->1 mapping for signaling types.
expecting: Redundant signals are eliminated, and WebRTC sequence is strictly followed.
next_action: Final verification and archive.

## Symptoms

expected: Recipient sends one 'Answer' signal. WebRTC connection establishes (Offer -> Answer -> Candidates).
actual: Recipient sends 6 Answers in 1 second. UI hangs on 'Connecting'. Offer (Type 1) is missing from signaling table.
errors: Multiple Answer signals in Supabase, flickering UI, "Connecting" hang.
reproduction: Start a call, have recipient answer. Observe signaling table and UI state.
started: Reported based on Supabase logs for call ID 'cce698e3...'.

## Eliminated
- hypothesis: Signaling table write failure for Offer.
  evidence: Offers were reaching the recipient (causing multiple answers), just appeared as Type 3 (PreKey) instead of Type 1.
  timestamp: 2026-04-22T15:20:00Z

## Evidence
- timestamp: 2026-04-22T15:10:00Z
  checked: lib/services/call_service.dart
  found: `_subscribeToParticipants` and `_getOrCreatePeerConnection` are async and lack protection against simultaneous triggers for the same peer.
  implication: Rapid stream updates can trigger multiple peer connection initializations and multiple offers.
- timestamp: 2026-04-22T15:15:00Z
  checked: lib/features/messages/data/signal/signal_service.dart and DB migrations
  found: Library uses Type 3 for PreKey, but migration comment and reporter expect Type 1.
  implication: Offers (typically PreKey) were stored as Type 3, making them "missing" when filtering for Type 1.
- timestamp: 2026-04-22T15:25:00Z
  checked: _handleSignalingData
  found: Lacks checks for `signalingState`, allowing processing of redundant offers/answers.
  implication: Multiple answers were sent in response to multiple offers because the recipient state machine just kept resetting.

## Resolution

root_cause: Race conditions in async stream listeners (`_subscribeToParticipants`) and lack of state guards in signaling handlers allowed multiple Offers and Answers to be exchanged. Conflicting signal type numbering (Library Type 3 vs DB Type 1) caused confusion in signaling logs.
fix: Implemented `_pendingPeerConnections` set to block redundant initializations. Added `RTCSignalingState` checks to ensure Offer/Answer exchange follows strict WebRTC sequence. Added mapping for PreKey signal type (3 <-> 1).
verification: Code review confirms strict ordering and race protection.
files_changed: [lib/services/call_service.dart]
