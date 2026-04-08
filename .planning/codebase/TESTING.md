# Testing Patterns

**Analysis Date:** 2024-04-18

## Test Framework

**Runner:**
- `flutter_test` (SDK provided)
- `test` (v1.24.10)

**Assertion Library:**
- `matcher` (Standard Dart/Flutter assertions)

**Run Commands:**
```bash
flutter test              # Run all unit and widget tests
flutter test test/path/to/test.dart  # Run specific test file
```

## Test File Organization

**Location:**
- Dedicated `test/` directory at project root.
- Mirroring structure: Some tests follow `lib/` directory structure:
  - `test/features/`
  - `test/models/`
  - `test/services/`
  - `test/widgets/`

**Naming:**
- Files end in `_test.dart`.
- Example: `message_reaction_test.dart`.

**Structure:**
```
test/
├── features/
│   └── messages/
├── models/
├── services/
├── test_utils/
│   ├── mocks.dart
│   └── test_helpers.dart
└── widgets/
```

## Test Structure

**Suite Organization:**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:oasis/features/messages/domain/models/message_reaction.dart';

void main() {
  group('MessageReactionModel Tests', () {
    test('fromJson should correctly parse message reaction', () {
      final json = { /* ... */ };
      final model = MessageReactionModel.fromJson(json);
      expect(model.id, '1');
    });
  });
}
```

**Patterns:**
- `group()`: Used for logical grouping within a test file.
- `test()`: Individual test case.
- `expect()`: Assertion with matchers (e.g., `equals`, `isTrue`, `isEmpty`, `findsOneWidget`).

## Mocking

**Framework:** `mockito` (v5.4.4) and custom manual mocks.

**Patterns:**
- Custom mock data classes in `test/test_utils/mocks.dart`:
```dart
class MockUser {
  static const String testUserId = 'test-user-id-12345';
  static AppUser get testAppUser => const AppUser(
    id: testUserId,
    email: 'test@example.com',
    // ...
  );
}
```
- Simplified mock services in `test/test_utils/mocks.dart` (e.g., `MockAuthServiceSimple`).

**What to Mock:**
- Database responses (Supabase)
- External services (Firebase, Auth)
- Local storage (SharedPreferences)

**What NOT to Mock:**
- Simple data entities/models (use real instances with mock data).
- Value objects.

## Fixtures and Factories

**Test Data:**
```dart
// Example from test/test_utils/mocks.dart
static Post get testPost => Post(
  id: 'test-post-id-1',
  userId: MockUser.testUserId,
  // ...
);
```

**Location:**
- `test/test_utils/mocks.dart` contains static factories for test entities (Post, User, Community).

## Coverage

**Requirements:** None explicitly enforced in CI configuration files, but broad coverage across core features (feed, messaging, auth, services).

**View Coverage:**
```bash
flutter test --coverage
```

## Test Types

**Unit Tests:**
- Most common: testing model serialization (`fromJson`/`toJson`) and business logic in services (e.g., `moderation_service_test.dart`).

**Widget Tests:**
- Used for theme validation (`test/widgets/theme_test.dart`) and UI interactions.
- Helpers in `test/test_utils/test_helpers.dart` assist with `pumpWidget` and `pumpAndSettle`.

**E2E Tests:**
- Not extensively used, but `integration_test` package is included in `pubspec.yaml`.

## Common Patterns

**Async Testing:**
- Using `await` within `test()` blocks for asynchronous operations.
- `pumpAndSettle()` for animations and async widget builds.

**Error Testing:**
- Verifying that services handle exceptions or return default values when data is missing (e.g., `fromJson` with missing fields).

---

*Testing analysis: 2024-04-18*
