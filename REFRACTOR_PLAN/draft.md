# Refactoring Draft: Heavy Flutter Refactor

## Objective
Break down large Dart files (e.g., `chat_screen.dart` - 3,661 lines) into smaller, manageable modules to improve maintainability and readability.

## Architecture
- Target Pattern: **Feature-First Architecture** (`lib/features/{feature}/...`)
- Current Pattern: Layer-based (`screens/`, `services/`, `widgets/`, `providers/`)
- State Management: **Riverpod**

## Prioritization
1.  **Immediate Focus:** `lib/screens/messages/chat_screen.dart` (3,661 lines).
2.  **Secondary Focus:** `lib/screens/messages/direct_messages_screen.dart` (1,714 lines) and `lib/themes/app_theme.dart` (1,532 lines).

## Strategy (Feature: Messages)
- **Create feature directory:** `lib/features/messages/`
- **Sub-directories:**
    - `presentation/screens/`
    - `presentation/widgets/` (sub-components for chat UI)
    - `presentation/controllers/` (Riverpod Notifiers for view state)
    - `domain/models/`
    - `data/repositories/`
- **Breakdown of chat_screen.dart:**
    - Extract chat list/timeline widget.
    - Extract input composer widget.
    - Extract app bar/header widget.
    - Extract single message bubble widgets.
    - Move business logic (sending/receiving) to Riverpod providers/notifiers.