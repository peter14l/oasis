---
status: investigating
trigger: "Investigate issue: windows-platform-thread-errors"
created: 2025-05-14T10:00:00Z
updated: 2025-05-14T10:00:00Z
---

## Current Focus

hypothesis: Native code for FlutterWebRTC and audioplayers is invoking platform channel methods from background threads without dispatching to the main platform thread.
test: Examine the native Windows implementation for FlutterWebRTC and audioplayers plugins.
expecting: Find calls to `MethodChannel.InvokeMethod` or `EventChannel.Sink.Success` (or equivalent C++ methods) being called directly from callbacks that run on background threads.
next_action: Search for FlutterWebRTC and audioplayers native Windows code.

## Symptoms

expected: Audio should work and screen sharing should function during calls.
actual: Audio doesn't work and screen sharing doesn't work.
errors: [ERROR:flutter/shell/common/shell.cc(1183)] The 'FlutterWebRTC/peerConnectionEvent...' channel sent a message from native to Flutter on a non-platform thread. Platform channel messages must be sent on the platform thread.
reproduction: Start a call, try to talk or place a sound, or click on the share screen button.
started: This has never worked correctly on Windows.

## Eliminated

## Evidence

## Resolution

root_cause:
fix:
verification:
files_changed: []
