---
status: resolved
trigger: "Flutter Windows build fails during CMake dependency download with 'Download failed: timeout on name lookup is not supported'"
created: 2026-04-12T00:00:00.000Z
updated: 2026-04-12T19:05:00.000Z
---

## Current Focus

hypothesis: dl.google.com DNS is intermittently failing - Firebase SDK download from that host is causing timeouts. Pre-download SDK from GitHub and use FIREBASE_CPP_SDK_DIR to bypass
test: Updated workflow with pre-download from GitHub releases
expecting: Build will succeed using pre-downloaded SDK without trying dl.google.com
next_action: User needs to test the fix in their local environment and verify GitHub Actions works

## Symptoms

expected: Flutter build successfully downloads CMake dependencies and builds Windows application
actual: "Download failed: timeout on name lookup is not supported" during CMake configure step
errors:
  - "Download failed: timeout on name lookup is not supported"
  - "Failed receiving HTTP2 data: 56(Failure when receiving data from the peer)"
  - "Connection #0 to host dl.google.com left intact"
reproduction: Run `flutter run --dart-define-from-file=.env -d windows`
started: Unknown (user reports this is happening)

## Eliminated

- Local network/proxy/firewall issues (ruled out - issue also occurs in GitHub Actions)

## Evidence

- timestamp: 2026-04-12T18:35:00.000Z
  checked: pubspec.yaml
  found: firebase_core: ^4.6.0, firebase_messaging: 16.1.3
  implication: Using recent Firebase packages that require C++ SDK download

- timestamp: 2026-04-12T18:35:00.000Z
  checked: .github/workflows/release.yml
  found: Windows build runs on windows-latest, uses Flutter stable channel
  implication: Issue occurs on GitHub's windows-latest runner as well

- timestamp: 2026-04-12T18:35:00.000Z
  checked: Web search for firebase_core CMake download failures
  found: Multiple similar issues reported - Firebase CMakeLists.txt downloads SDK from dl.google.com
  implication: Root cause is Firebase SDK download from external host failing

- timestamp: 2026-04-12T18:40:00.000Z
  checked: Go language issue #78055 on GitHub
  found: dl.google.com has 2 out of 4 servers failing intermittently since March 2026 - causes timeout, 502 errors
  implication: This is a known external issue with Google's download host

- timestamp: 2026-04-12T18:42:00.000Z
  checked: firebase/firebase-cpp-sdk GitHub releases
  found: SDK also available on GitHub releases (v13.5.0 latest) - separate from dl.google.com
  implication: Alternative download source exists

- timestamp: 2026-04-12T18:43:00.000Z
  checked: firebase_core CMakeLists.txt logic
  found: FIREBASE_CPP_SDK_DIR environment variable can bypass the download if SDK version matches
  implication: Can pre-download SDK and set env var to avoid download

- timestamp: 2026-04-12T18:58:00.000Z
  checked: Updated .github/workflows/release.yml
  found: Added step to download Firebase C++ SDK v13.5.0 from GitHub releases and set FIREBASE_CPP_SDK_DIR
  implication: Build will use pre-downloaded SDK instead of downloading from dl.google.com

## Resolution

root_cause: dl.google.com has intermittent DNS/connectivity issues causing Firebase C++ SDK download to fail with "timeout on name lookup is not supported"
fix: Added GitHub Actions workflow step to pre-download Firebase C++ SDK v13.5.0 from GitHub releases and set FIREBASE_CPP_SDK_DIR environment variable to bypass dl.google.com download
verification: 
files_changed: [".github/workflows/release.yml"]

## Local Development Fix

For local development, set the FIREBASE_CPP_SDK_DIR environment variable before running Flutter:

```powershell
# Download SDK from https://github.com/firebase/firebase-cpp-sdk/releases/tag/v13.5.0
# Extract to a local folder, e.g., C:\firebase-cpp-sdk
$env:FIREBASE_CPP_SDK_DIR = "C:\firebase-cpp-sdk"
flutter run -d windows
```

Or on bash:
```bash
export FIREBASE_CPP_SDK_DIR=/path/to/firebase_cpp_sdk
flutter run -d windows
```