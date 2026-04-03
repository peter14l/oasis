# 📋 Morrow V2: Technical Debt & Feature Gap Implementation Plan

This document tracks the progress of structural improvements, bug fixes, and feature completions for Morrow V2.

## 🏗️ Dynamic Progress Tracker

| Category | Task | Status | Priority |
| :--- | :--- | :--- | :--- |
| **Linting** | Remove 10+ Unused Imports | ✅ Completed | High |
| **Linting** | Fix Deprecated Theme Members (`surfaceVariant`, `background`) | ✅ Completed | Medium |
| **Linting** | Resolve Duplicate Imports in `commitment_card.dart` | ✅ Completed | Low |
| **Linting** | Fix Naming Conventions (Constants to `lowerCamelCase`) | ✅ Completed | Low |
| **Logic** | Implement Post Like persistence in `hashtag_screen.dart` | ✅ Completed | High |
| **Refactor** | Decompose `MessagingService` (God Class) | ✅ Completed | High |
| **Refactor** | Decompose `EncryptionService` (God Class) | ✅ Completed | Medium |
| Refactor | Centralize Error Handling Strategy | ✅ Completed | Medium |
| **Docs** | Update/Correct `ALL_TODOS_RESOLVED.md` | ✅ Completed | Low |
| **Docs** | Create `NEXT_SESSION_PROMPT.md` | ✅ Completed | Low |

---

## 🛠️ Detailed Implementation Strategy

### 1. Lint & Noise Reduction (Phase 1)
- **Goal**: Clean up 427+ analyzer issues to make real bugs easier to spot.
- **Action**: Run `flutter analyze`, script the removal of unused imports, and update deprecated Material 3 properties.

### 2. Logic Completion: Hashtag Feed (Phase 2)
- **Goal**: Persist likes made from the hashtag search results.
- **Action**: Update `_handleLike` in `lib/screens/hashtag_screen.dart` to call `PostService().likePost()`.

### 3. Service Decomposition: Messaging & Encryption (Phase 3)
- **Goal**: Split 1500+ line `MessagingService` into modular units.
- **Modules**:
  - `ConversationService`: Handles listing and metadata.
  - `MessageService`: Handles sending, receiving, and state.
  - `MediaService`: Handles attachments.
- **Encryption**: Extract key migration and "healing" logic from `EncryptionService` into a `KeyMigrationManager`.

### 4. Error Handling & Documentation (Phase 4)
- **Goal**: Ensure no critical path fails silently.
- **Action**: Replace empty `catch` blocks with logging/reporting and add missing docstrings to complex encryption logic.

---

## 🚦 Status Definitions
- ⬜ **Pending**: Not started.
- 🚧 **In Progress**: Currently being worked on.
- ✅ **Completed**: Implemented and verified.
- ❌ **Blocked**: Requires external input or decision.
