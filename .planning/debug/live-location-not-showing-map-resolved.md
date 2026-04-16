---
status: fixing
trigger: "Investigate issue: live-location-not-showing-map"
created: 2025-01-24T12:00:00Z
updated: 2025-01-24T12:15:00Z
---

## Current Focus

hypothesis: The message type was not being correctly identified when receiving a message from Supabase because the `message_type` column is missing from the database, and the `Message._normalizeJson` method did not check for `location_data`.
test: Verified that `Message._normalizeJson` was missing `location_data`, `poll_data`, and `story_id` checks.
expecting: Fixing `_normalizeJson` will cause `MessageType.location` to be correctly assigned, which in turn will cause `ChatMessageList` to render `LocationBubble` instead of `TextBubble`.
next_action: Verify if `LocationBubble` can be improved to show a real map or if the placeholder is sufficient for "more than just text".

## Symptoms

expected: Map preview or more than just text.
actual: Only text "Live location shared" is sent.
errors: none
reproduction: Click on attachments -> location -> select duration.
timeline: never worked.

## Eliminated

## Evidence

- timestamp: 2025-01-24T12:05:00Z
  checked: lib/features/messages/presentation/providers/chat_provider.dart
  found: `shareLiveLocation` sends a message with `MessageType.location` and `locationData`.
  implication: The data is being sent correctly to the service.

- timestamp: 2025-01-24T12:10:00Z
  checked: lib/services/chat_messaging_service.dart
  found: `sendMessage` inserts `location_data` but doesn't insert a `message_type` column (because it doesn't exist in the DB).
  implication: The message type must be derived upon retrieval.

- timestamp: 2025-01-24T12:12:00Z
  checked: lib/features/messages/domain/models/message.dart
  found: `_normalizeJson` derives `MessageType` from URL fields but was missing checks for `location_data`, `poll_data`, and `story_id`.
  implication: All these message types were defaulting to `MessageType.text`, causing them to be rendered as simple text.

## Resolution

root_cause: `Message._normalizeJson` was missing detection for `MessageType.location`, `MessageType.poll`, and `MessageType.storyReply` when the `message_type` column is absent in the database.
fix: Updated `Message._normalizeJson` to detect these types based on the presence of `location_data`, `poll_data`, and `story_id`.
verification: 
files_changed: ["lib/features/messages/domain/models/message.dart"]
