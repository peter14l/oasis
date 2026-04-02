# Technical Debt Resolution Plan
## Morrow V2 - Code Audit Implementation Guide

---

## Document Overview

This document tracks the implementation of fixes for technical debt identified during the code audit of the Morrow V2 Flutter application. It serves as both a specification guide and a dynamic progress tracker.

**Date Created**: April 2, 2026  
**Target**: Production Release  
**Total Issues**: 8 (excluding AudioRoom feature - decision pending)

---

## Executive Summary

The Morrow V2 codebase has been audited for technical debt, incomplete features, and error handling issues. This document provides detailed implementation specifications for all identified issues.

### Categorization

| Category | Count | Priority |
|----------|-------|----------|
| Critical (Empty Catches) | 4 | 🔴 High |
| Feature Gaps (TODOs) | 4 | 🟡 Medium |
| **Total** | **8** | - |

---

## Part 1: Critical Issues - Empty Catch Blocks

### Issue 1.1: Empty Catch Block in GlowingNote
**File**: `lib/widgets/canvas/glowing_note.dart`  
**Line**: 100  
**Priority**: 🔴 Critical

#### Current Code
```dart
Color _hexToColor(String hex) {
  try {
    final code = hex.replaceAll('#', '');
    if (code.length == 6) {
      return Color(int.parse('FF$code', radix: 16));
    } else if (code.length == 8) {
      return Color(int.parse(code, radix: 16));
    }
  } catch (_) {}
  return const Color(0xFF3B82F6); // Default blue
}
```

#### Problem
- Hex color parsing failures are silently ignored
- Falls back to default color without logging
- Makes debugging impossible when invalid colors are passed

#### Fix Specification
```dart
Color _hexToColor(String hex) {
  try {
    final code = hex.replaceAll('#', '');
    if (code.length == 6) {
      return Color(int.parse('FF$code', radix: 16));
    } else if (code.length == 8) {
      return Color(int.parse(code, radix: 16));
    }
  } catch (e) {
    debugPrint('GlowingNote: Invalid hex color "$hex" - ${e.toString()}');
  }
  return const Color(0xFF3B82F6); // Default blue
}
```

---

### Issue 1.2: Empty Catch Block in PresenceService
**File**: `lib/services/presence_service.dart`  
**Priority**: 🔴 Critical

#### Problem
- Realtime presence updates silently fail
- User online status may be incorrectly displayed
- No error propagation to UI

#### Fix Specification
Add proper error handling that:
- Logs the error for debugging
- Notifies the callback with 'offline' status as fallback
- Optionally triggers error callback if available

---

### Issue 1.3: Empty Catch Block in ChatScreen
**File**: `lib/screens/messages/chat_screen.dart`  
**Priority**: 🔴 Critical

#### Problem
- Chat message loading/sending failures are hidden
- User gets no feedback when messages fail
- May cause sync issues with database

#### Fix Specification
Wrap in try-catch that:
- Sets error state
- Shows user-friendly error via SnackBar
- Retries mechanism for transient failures

---

### Issue 1.4: Empty Catch Block in ChatDetailsScreen
**File**: `lib/screens/messages/chat_details_screen.dart`  
**Priority**: 🔴 Critical

#### Problem
- Chat details loading fails silently
- User cannot see chat details when errors occur

#### Fix Specification
Same pattern as ChatScreen - propagate error to UI

---

## Part 2: Feature Gaps - TODO Items

### Issue 2.1: PostCard Callbacks Not Wired
**File**: `lib/screens/hashtag_screen.dart`  
**Lines**: 174-176  
**Priority**: 🟡 Medium

#### Current Code
```dart
return PostCard(
  post: _posts[index],
  onLike: () {}, // TODO: Implement
  onComment: () {}, // TODO: Implement
  onShare: () {}, // TODO: Implement
);
```

#### Fix Specification
Implement callbacks that:
- **onLike**: Call post service like endpoint, update local state
- **onComment**: Navigate to comments screen/modal
- **onShare**: Open share sheet with post content

---

### Issue 2.2: Data Export Not Implemented
**File**: `lib/screens/settings/download_data_screen.dart`  
**Line**: 30  
**Priority**: 🟡 Medium

#### Current Code
```dart
onPressed: () {
  // TODO: Trigger data export request
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Request submitted! Check your email.')),
  );
},
```

#### Fix Specification
- Call backend API to initiate data export
- Show loading state while processing
- Handle success/error responses
- Show appropriate feedback

---

### Issue 2.3: Cache Clearing Not Implemented
**File**: `lib/screens/settings/storage_usage_screen.dart`  
**Line**: 50  
**Priority**: 🟡 Medium

#### Current Code
```dart
onPressed: () async {
  // TODO: Logic to Clear Cache
  // For now, simulator success
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Cache cleared!'))
  );
},
```

#### Fix Specification
- Call cache service clear method
- Clear image cache (cached_network_image)
- Clear any local storage caches
- Show loading indicator during clear
- Refresh storage usage after clear

---

### Issue 2.4: Change PIN Not Implemented
**File**: `lib/screens/settings/vault_settings_screen.dart`  
**Line**: 245  
**Priority**: 🟡 Medium

#### Current Code
```dart
onTap: () {
  // TODO: Implement change PIN
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Feature coming soon')),
  );
},
```

#### Fix Specification
- Verify current PIN
- Prompt for new 4-digit PIN
- Confirm new PIN
- Call vault service to update PIN
- Show success/error feedback

---

## Part 3: Excluded - Pending Decision

### AudioRoomService
**File**: `lib/services/audio_room_service.dart`

**Status**: ⏸️ EXCLUDED - Feature decision pending

**Note**: This service is entirely stubbed and throws UnimplementedError. Excluded from this implementation round until product decision is made.

---

## Progress Tracker

### Implementation Status

| # | Issue | Status | Notes |
|---|-------|--------|-------|
| 1.1 | GlowingNote catch block | ✅ Completed | Added debugPrint logging |
| 1.2 | PresenceService catch | ✅ Completed | Added debugPrint logging |
| 1.3 | ChatScreen catch | ✅ Completed | Already had proper error handling |
| 1.4 | ChatDetailsScreen catch | ✅ Completed | Already had proper error handling |
| 2.1 | PostCard callbacks | ✅ Completed | Wired up like/comment/share |
| 2.2 | Data export | ✅ Completed | Implemented API call |
| 2.3 | Cache clearing | ✅ Completed | Implemented cache clear |
| 2.4 | Change PIN | ✅ Completed | Full dialog flow |

### Legend
- ⬜ Not Started
- 🔄 In Progress
- ✅ Completed
- ⏸️ Blocked/Pending Decision

### Progress Metrics

```
Critical Issues:   4/4 (100%)
Feature Gaps:      4/4 (100%)
Overall:           8/8 (100%)
```

---

## Implementation Notes

### Dependencies Required
- `post_service.dart` - for like/share operations
- `cache_service.dart` - for cache clearing
- `vault_service.dart` - for PIN change

### Testing Requirements
- Unit tests for catch block error scenarios
- Integration tests for feature flows
- Error state UI verification

---

## Document Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | April 2, 2026 | Sisyphus | Initial document creation |

---

*End of Technical Debt Resolution Plan*
