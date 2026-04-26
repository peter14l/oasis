---
status: investigating
trigger: "vault-lock-logic-issue"
created: 2024-05-24T10:00:00Z
updated: 2024-05-24T10:00:00Z
---

## Current Focus

hypothesis: The vault lock logic in the chat screen doesn't check the lock mode correctly or doesn't trigger the lock when the chat is closed.
test: Examine the code responsible for locking and unlocking the vault, specifically looking for where 'Lock on Chat Close' is handled.
expecting: To find a missing check or an incorrect condition that prevents the vault from locking when a chat is closed.
next_action: Search for vault-related logic and services in the codebase.

## Symptoms

expected: When 'Lock on Chat Close' is selected, it should ask for biometrics every time the chat is opened after being closed.
actual: It only asks for biometrics when the app is backgrounded and resumed.
errors: Unknown (release build)
reproduction: 1. Turn on vault in chat details. 2. Select 'Lock on Chat Close'. 3. Close chat and go to DM screen. 4. Re-open chat. Observation: No biometric prompt.
started: A long time ago

## Eliminated

## Evidence

## Resolution

root_cause: 
fix: 
verification: 
files_changed: []
