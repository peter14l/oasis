---
status: investigating
trigger: "Investigate and fix 5 items: PostgrestException for 'public.data_export_requests', Ripples UI: Remove Waves logo, add pre-suggested minute options (15, 30, 45 mins), GoException for '/zen-breath', GoException for ToS and Privacy Policy. Move these from Settings to About Oasis subpages, Create a Changelog page for About Oasis matching the app theme."
created: 2024-05-24T12:00:00Z
updated: 2024-05-24T12:00:00Z
---

## Current Focus

hypothesis: Missing table 'data_export_requests' and missing routes.
test: Searching codebase for table name and routes to find missing definitions.
expecting: Find missing SQL migration and router definitions.
next_action: Search for 'data_export_requests' and '/zen-breath' in the codebase.

## Symptoms

expected: 
- Clicking 'Export Data' works without PostgrestException.
- Ripples tab has no Waves logo and includes 15, 30, 45 min suggested options.
- Navigation to '/zen-breath', ToS, and Privacy Policy works.
- ToS and Privacy Policy are accessible from About Oasis, not Settings.
- A new Changelog page exists with placeholders for version numbers, fixes, and new features.

actual: 
- PostgrestException (PGRST205) when clicking 'Export Data'.
- Ripples tab has Waves logo and no suggested minutes.
- GoException for '/zen-breath', ToS, and Privacy Policy.
- ToS and Privacy Policy are currently in Settings (or failing there).
- No Changelog page exists.

errors: 
- PostgrestException(message: Could not find the table 'public.data_export_requests' in the schema cache, code: PGRST205, details: Not Found, hint: Perhaps you meant the table 'public.call_participants')
- GoException : No routes for location : /zen-breath
- GoException : No routes for location : /terms-of-service (presumably)
- GoException : No routes for location : /privacy-policy (presumably)

reproduction: 
- Trigger 'Export Data' in Settings Screen.
- Navigate to Ripples tab in Feed Screen.
- Click 'Mindful Breathing' in Wellness Center Screen.
- Navigate to ToS/Privacy Policy from About Oasis.

started: Getting ready for production.

## Eliminated


## Evidence


## Resolution

root_cause: 
fix: 
verification: 
files_changed: []
