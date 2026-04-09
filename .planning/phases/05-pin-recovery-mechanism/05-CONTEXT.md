# Phase 5: PIN Recovery Mechanism - Context

**Gathered:** 2026-04-09
**Status:** Ready for planning
**Source:** User request via plan-phase

<domain>
## Phase Boundary

Implement a PIN recovery mechanism for users who have BOTH forgotten their PIN AND lost their recovery codes. Since the previous encryption keys cannot be accessed without either, set up a mechanism for setting a new PIN so that new messages are not lost. The old messages will remain encrypted/inaccessible - this is an accepted trade-off.

</domain>

<decisions>
## Implementation Decisions

### Recovery Flow Design
- **D-01:** Users with lost PIN + lost recovery codes can reset PIN by authenticating via email/password (Supabase auth)
- **D-02:** PIN reset flow must clearly warn that old encrypted messages will become permanently inaccessible
- **D-03:** After PIN reset, user should be able to continue using the app normally with a new PIN

### New PIN Requirements
- **D-04:** New PIN must be 4 digits (match existing vault PIN format)
- **D-05:** User must confirm new PIN (type twice)
- **D-06:** New PIN must be different from old PIN (but since we can't verify, skip this check - user explicitly accepts)

### UX/UI Requirements
- **D-07:** PIN reset screen should be accessible from the login screen ("Forgot PIN?" link)
- **D-08:** Recovery code entry should have a "Lost your recovery code?" link to the email-based reset flow
- **D-09:** Clear warning UI before confirming PIN reset about data loss

### Data Handling
- **D-10:** Old encrypted messages remain inaccessible - encryption keys are not recoverable
- **D-11:** New messages after PIN reset should be encrypted with the NEW key
- **D-12:** User's vault items (if any) should be cleared/reset since the old PIN cannot unlock them

### Security
- **D-13:** Email/password verification via Supabase Auth is required before PIN reset
- **D-14:** Rate limiting should apply to prevent brute-force PIN attempts (if possible)
- **D-15:** After successful PIN reset, old recovery key should be invalidated (user must set up new recovery key)

### the agent's Discretion
- Implementation of the PIN reset UI (modal, bottom sheet, or full screen)
- Exact warning text wording (within the constraints above)
- Whether to auto-generate new recovery key after PIN reset or prompt user to do it manually

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing Security Code
- `lib/services/vault_service.dart` — Current PIN storage and verification logic
- `lib/services/key_management_service.dart` — Encryption key derivation
- `lib/widgets/recovery_key_sheet.dart` — Recovery key UI pattern
- `lib/features/settings/presentation/screens/vault_settings_screen.dart` — Vault settings UI
- `lib/features/auth/` — Authentication screens and Supabase auth integration

</canonical_refs>

<specifics>
## Specific Ideas

**User scenario:**
1. User forgets their 4-digit PIN
2. User also lost their 24-character recovery code
3. User goes to login screen → sees "Forgot PIN?" 
4. User clicks → enters email + password to verify identity
5. System shows warning: "Resetting PIN will make your old encrypted messages permanently inaccessible"
6. User confirms → enters new 4-digit PIN
7. User can now access app with new PIN
8. User is prompted to set up new recovery code (optional but recommended)

</specifics>

<deferred>
## Deferred Ideas

- Biometric-based PIN recovery (future enhancement)
- Account recovery via trusted contacts (future enhancement)
- Social recovery (future enhancement)

</deferred>

---

*Phase: 05-pin-recovery-mechanism*
*Context gathered: 2026-04-09 via plan-phase*
