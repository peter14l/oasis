# Coding Conventions

**Analysis Date:** 2024-04-18

## Naming Patterns

**Files:**
- `snake_case.dart`: All source and test files use lowercase with underscores.
- Examples: `ripple_repository_impl.dart`, `message_reaction_test.dart`.

**Classes:**
- `PascalCase`: All class names and types.
- Examples: `FeedProvider`, `AppUser`, `SupabaseService`.

**Functions:**
- `camelCase`: All methods and functions.
- Examples: `loadFeed()`, `signIn()`, `buildProviderTree()`.

**Variables:**
- `camelCase`: Local variables and class members.
- Examples: `_isLoading`, `currentUser`, `forYouPosts`.
- `_camelCase`: Private class members (standard Dart).

**Constants:**
- `camelCase` or `kCamelCase`: Prefixed with `k` for global constants or just `static const`.
- Examples: `_themeKey`, `DefaultFirebaseOptions.currentPlatform`.

## Code Style

**Formatting:**
- Dart standard formatter (configured via IDE or `dart format`).
- Guidelines enforced by `analysis_options.yaml`.

**Linting:**
- `flutter_lints` package (version ^5.0.0).
- Configured in `analysis_options.yaml`.
- Key rules enabled:
  - `avoid_print: true`
  - `prefer_const_constructors: true`
  - `always_declare_return_types: true`
  - `prefer_single_quotes: true`
  - `prefer_final_locals: true`

## Import Organization

**Order:**
1. Dart core libraries (`import 'dart:...'`)
2. Flutter framework libraries (`import 'package:flutter/...'`)
3. Third-party packages (`import 'package:provider/...'`)
4. Local project files with full package paths (`import 'package:oasis/...'`)

**Path Aliases:**
- Not explicitly used; absolute package imports are preferred: `package:oasis/features/...`.

## Error Handling

**Patterns:**
- `try-catch` blocks in services and providers to catch exceptions from external sources (Supabase, Firebase).
- `debugPrint` used for logging errors in development: `debugPrint('[Feature] Error: $e');`.
- Sentry integrated for production error tracking via `AppInitializer.runWithSentry`.

## Logging

**Framework:** `Sentry` and `debugPrint`.

**Patterns:**
- Service-level errors are caught and logged with feature-specific tags in the string.
- Sentry captures fatal errors and exceptions in production.

## Comments

**When to Comment:**
- Header comments for complex classes describing their purpose.
- Logical section separators in large files (e.g., `main.dart`, `app_initializer.dart`).
- `// ─── Section Name ───────────────────────────────────` style for grouping methods.

**JSDoc/TSDoc:**
- Dart documentation comments `///` used for public API and complex logic.

## Function Design

**Size:** Generally focused, but some provider methods handle multiple state updates (e.g., `loadFeed` in `lib/features/feed/presentation/providers/feed_provider.dart`).

**Parameters:** Use of named parameters for constructors and methods with multiple arguments to improve readability.

**Return Values:** Explicit return types are required. `Future<void>` for async side effects, `Future<T>` for data fetching.

## Module Design

**Exports:** Limited use of barrel files; exports used within features to expose state or models (e.g., `lib/features/feed/presentation/providers/feed_provider.dart` exports `FeedType`).

**Feature Structure:**
- Clean Architecture inspired layout per feature:
  - `domain/`: Business logic, entities, repository interfaces.
  - `data/`: Implementation details, datasources, repository implementations.
  - `presentation/`: UI logic, providers (ChangeNotifier), screens, and widgets.

---

*Convention analysis: 2024-04-18*
