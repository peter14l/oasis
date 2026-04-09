# Phase 5: PIN Recovery Mechanism - Updated Context

**Gathered:** 2026-04-09
**Status:** Ready for planning
**Source:** User request via plan-phase

<domain>
## Phase Boundary

Implement a PIN recovery mechanism for users who have BOTH forgotten their 6-digit chat encryption PIN AND lost their recovery codes. Since the previous encryption keys cannot be accessed without either, set up a mechanism for setting a new PIN so that new messages are not lost. The old messages will remain encrypted/inaccessible - this is an accepted trade-off.

**IMPORTANT:** This is for the 6-digit CHAT ENCRYPTION PIN, NOT the 4-digit Vault PIN.

</domain>

<decisions>
## Implementation Decisions

### Recovery Flow Design
- **D-01:** Users with lost PIN + lost recovery codes can reset by authenticating via Supabase email/password
- **D-02:** PIN reset flow must clearly warn that old encrypted messages will become permanently inaccessible
- **D-03:** After PIN reset, user gets NEW encryption keys (cannot recover old ones)
- **D-04:** User should be prompted to save a NEW recovery key

### New PIN Requirements
- **D-05:** New PIN must be 6 digits (matching existing chat encryption PIN format)
- **D-06:** User must confirm new PIN (type twice)
- **D-07:** New PIN is used to derive NEW encryption keys

### UX/UI Requirements
- **D-08:** PIN reset screen should be accessible from the login screen ("Forgot PIN?" link)
- **D-09:** Recovery code entry should have a "Lost your recovery code?" link to the email-based reset flow
- **D-10:** Clear warning UI before confirming PIN reset about data loss

### Data Handling
- **D-11:** Old encrypted messages remain inaccessible - encryption keys are not recoverable
- **D-12:** New messages after PIN reset should be encrypted with the NEW key
- **D-13:** Server-side: Upload new encrypted private key with NEW PIN and NEW recovery key
- **D-14:** Invalidate old recovery key on server (clear encrypted_private_key_recovery)

### Security
- **D-15:** Email/password verification via Supabase Auth is required before PIN reset
- **D-16:** Rate limiting should apply (existing Supabase auth handles this)
- **D-17:** After successful PIN reset, user must set up new recovery key

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing Security Code
- `lib/features/messages/data/encryption_service.dart` — Current encryption setup/restore logic (READ FIRST)
- `lib/services/key_management_service.dart` — Key derivation (Argon2id)
- `lib/widgets/security_pin_sheet.dart` — 6-digit PIN UI pattern
- `lib/widgets/recovery_key_sheet.dart` — Recovery key UI pattern
- `lib/features/messages/presentation/screens/encryption_setup_screen.dart` — Encryption setup flow

### Key Methods in EncryptionService
```dart
class EncryptionService {
  // Setup new encryption with PIN
  Future<({bool success, String? recoveryKey})> setupEncryption({String? pin}) async {...}
  
  // Restore with PIN
  Future<bool> restoreSecureKeys(String pin) async {...}
  
  // Restore with recovery key  
  Future<bool> restoreWithRecoveryKey(String recoveryKey) async {...}
  
  // Generate new keys (for fresh start, loses old messages)
  Future<bool> generateNewKeys() async {...}
}
```

### Key Methods in KeyManagementService
```dart
class KeyManagementService {
  // Derive key from PIN
  encrypt.Key deriveSecureBackupKey(String pin, String saltBase64) {...}
  
  // Generate salt
  String generateSalt() {...}
  
  // Generate recovery key
  String generateRecoveryKey() {...}
  
  // Encrypt/decrypt
  String encryptWithKey(String data, encrypt.Key key) {...}
  String? decryptWithKey(String encryptedDataBase64, encrypt.Key key) {...}
}
```

</canonical_refs>

<specifics>
## User Scenario

1. User forgets their 6-digit chat encryption PIN
2. User also lost their 24-character recovery code
3. User goes to login screen → sees "Forgot PIN?" (currently in needsRestore state)
4. User clicks → enters email + password to verify identity via Supabase Auth
5. System shows warning: "Resetting PIN will make your old encrypted messages permanently inaccessible"
6. User confirms → enters new 6-digit PIN (twice)
7. System generates NEW encryption keys (user accepts old messages lost)
8. User is shown NEW recovery key to save
9. User can now access app with new PIN, new messages work normally

</specifics>

<deferred>
## Deferred Ideas

- Biometric-based PIN recovery (future enhancement)
- Account recovery via trusted contacts (future enhancement)
- Social recovery (future enhancement)
- PIN reset via admin/manual verification (future enhancement)

</deferred>

---

*Phase: 05-pin-recovery-mechanism*
*Context gathered: 2026-04-09 via plan-phase*
*Updated: Fixed to target 6-digit chat encryption PIN instead of 4-digit vault PIN*
