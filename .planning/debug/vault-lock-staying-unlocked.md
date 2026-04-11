---
status: investigating
trigger: "The Vault chat lock remains unlocked after the first time it is opened, even if \"Lock on Chat Exit\" is selected."
created: 2024-05-24T12:00:00Z
updated: 2024-05-24T12:00:00Z
---

## Current Focus

hypothesis: The Vault lock state is not being correctly reset to 'locked' when the user exits the chat screen.
test: Examine the navigation logic and state management for Vault chats, specifically where "Lock on Chat Exit" is handled.
expecting: Find a missing or incorrect state update when navigating away from a Vault chat.
next_action: Search for "Vault" and "Lock on Chat Exit" to identify relevant code.

## Symptoms

expected: If the selected option is "Lock chat on exit", then the chat should immediately be locked as soon as the user exits the chat screen and navigates to the direct_message_screen. If the user tries to enter the chat_screen again, then they should be asked to unlock it and after unlocking they will be taken to the chat_screen to view the chats.
actual: The chat stays unlocked, no matter how many times I close and reopen the chat.
errors: None reported.
reproduction: 1. Go to Chat Details Screen. 2. Turn on Vault and choose "Lock on Chat Exit".
started: Noticed recently, possibly always broken.

## Eliminated

<!-- APPEND only - prevents re-investigating -->

## Evidence

<!-- APPEND only - facts discovered -->

## Resolution

root_cause: 
fix: 
verification: 
files_changed: []
