# Debug Session: postgrest-cast-error-on-call

## Symptoms
- When initiating a call via `chat_screen.dart`, a `PostgrestException` is thrown: `cannot cast type record to http_request, code: 42846, details: Cannot cast type record[] to http_header[] in column 3.`.
- This occurs immediately after clicking the voice/video call button.
- The UI stays responsive but showing a snackbar error.

## Hypotheses
1. A database trigger on `calls` or `call_participants` is using the `pg_net` or `http` extension incorrectly.
2. A recent migration introduced a type mismatch in a notification function.

## Investigation
- Searched for `net.http_post` and `http(` in all SQL files.
- Identified a very recent migration: `supabase\migrations\20260409000002_call_notifications_trigger.sql`.
- This migration introduced a trigger `call_participants_notification_trigger` on the `call_participants` table.
- The trigger calls `handle_call_notification()`, which uses the `http` extension to directly invoke an Edge Function.
- The call in the migration file:
  ```sql
  PERFORM http((
    'POST',
    '/functions/v1/push-notifications',
    ARRAY[('Content-Type', 'application/json')],
    json_build_object(...)::text
  )::http_request);
  ```
- This call had multiple issues:
  1. It tried to cast a 4-field anonymous record to a 5-field `http_request` type.
  2. It didn't explicitly cast the array elements to `http_header`, resulting in the `record[]` vs `http_header[]` cast error.
  3. It used a relative URL which the `http` extension does not support.
  4. It was redundant because an `INSERT INTO notifications` was already performed, and there is a global trigger on that table that sends the same push notification using a robust, catch-all function.

## Resolution
- Modified `supabase\migrations\20260409000002_call_notifications_trigger.sql` to remove the redundant and malformed `PERFORM http(...)` block.
- Removed the unnecessary `CREATE EXTENSION IF NOT EXISTS http;` call.
- The functionality is preserved via the existing `notify_push_service` trigger on the `notifications` table.

## Status: Resolved
The fix is applied to the migration file. The user needs to apply this change to their Supabase database.
