---
status: investigating
trigger: "Apply architectural fixes to resolve call flow issues: 1. Refactor lib/features/calling/presentation/screens/calling_screen.dart to move RTCVideoRenderer initialization out of the build() method. 2. Update lib/services/call_service.dart to use more robust signaling state management (reduce redundant rebuilds). 3. Investigate and verify Supabase RLS policies for 'calls' and 'call_signaling' tables."
created: 2024-05-23T10:00:00Z
updated: 2024-05-23T10:00:00Z
---

## Current Focus

hypothesis: Call flow issues are caused by improper resource management (VideoRenderer in build) and fragile signaling state.
test: Refactor code and verify RLS policies.
expecting: Improved call stability and performance.
next_action: Read lib/features/calling/presentation/screens/calling_screen.dart to identify VideoRenderer initialization.

## Symptoms

expected: Stable call flow with efficient resource management and secure signaling.
actual: RTCVideoRenderer initialized in build(), potentially redundant rebuilds in signaling, and uncertain RLS policies.
errors: N/A
reproduction: N/A
started: Unknown

## Eliminated

## Evidence

## Resolution

root_cause:
fix:
verification:
files_changed: []
