---
status: investigating
trigger: "Investigate issue: call-participants-duplicate-key"
created: 2024-05-24T12:00:00Z
updated: 2024-05-24T12:00:00Z
---

## Current Focus

hypothesis: The `CallService.joinCall` method uses `upsert` without specifying `onConflict`, causing it to attempt an `insert` because the primary key `id` is missing from the payload. Since `call_participants` has a `UNIQUE(call_id, user_id)` constraint, and the host is already added to this table by `CallRepository.createCall`, the insertion fails.
test: Add `onConflict: 'call_id,user_id'` to the `upsert` call in `CallService.joinCall`.
expecting: The duplicate key error should be resolved as the `upsert` will now correctly identify the existing record and update it instead of trying to insert a new one.
next_action: Apply the fix to `lib/services/call_service.dart`.

## Symptoms

expected: A successful call is supposed to be initialized between the two users and the calling screen is supposed to show up.
actual: A snackbar shows PostgrestException(message: duplicate key value violates unique constraint "call_participants_call_id_user_id_key", code: 23505, details: Conflict, hint: null).
errors: PostgrestException(code: 23505, message: duplicate key value violates unique constraint "call_participants_call_id_user_id_key")
reproduction: Click the voice call option in @lib/features/messages/presentation/screens/chat_screen.dart.
started: Started recently, specifically likely after commit be4c6ff.

## Eliminated


## Evidence

- Checked `lib/features/messages/presentation/screens/chat_screen.dart`: Calls `callProvider.initiateCall`.
- Checked `lib/features/calling/presentation/providers/call_provider.dart`: `initiateCall` calls `_initiateCall.call` then `_callService.joinCall`.
- Checked `lib/features/calling/data/repositories/call_repository_impl.dart`: `createCall` inserts host into `call_participants` with status 'joined'.
- Checked `lib/services/call_service.dart`: `joinCall` calls `upsert` on `call_participants` without `onConflict`.
- Checked `supabase/migrations/027_calls_schema.sql`: `call_participants` has `UNIQUE(call_id, user_id)` constraint.
- Conclusion: `joinCall`'s `upsert` defaults to conflict on `id` (PK). Since `id` isn't provided, it acts as an `insert`, violating the `UNIQUE(call_id, user_id)` constraint because the record was already created by the repository.


root_cause: 
fix: 
verification: 
files_changed: []
