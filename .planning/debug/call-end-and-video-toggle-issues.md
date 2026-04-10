---
status: investigating
trigger: "Investigate and fix call termination, video toggle issues, and improve the 'waiting' UI for audio/video-off calls."
created: 2025-01-24T16:00:00Z
updated: 2025-01-24T16:00:00Z
---

## Current Focus

hypothesis: Call termination fails because the navigation logic or state update after ending the call is not correctly triggering the screen to close, or it's being immediately reopened/restored.
test: Examine call termination logic in CallService and CallScreen.
expecting: Identify why the screen persists after clicking end call.
next_action: Search for call-related files and examine CallService and CallScreen.

## Symptoms

expected: 
- Clicking end call terminates the session and closes the call screen.
- Toggling video "on" starts the video stream during an active call.
- Audio calls/Waiting screen should show recipient profile info with a pulsating effect instead of a black screen.
actual: 
- Call screen flickers and persists on end call.
- Video stream doesn't start on toggle.
- Screen is black during waiting/audio calls.
errors: None observed (release builds).
reproduction: Android to Windows. Start call, accept, try to end or toggle video.
started: Observed after recent calling features implementation.

## Eliminated

## Evidence

## Resolution

root_cause: 
fix: 
verification: 
files_changed: []
