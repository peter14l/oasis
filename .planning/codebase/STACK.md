# Technology Stack

**Analysis Date:** 2026-04-08

## Languages

**Primary:**
- Dart ^3.7.2 - Entire Flutter application codebase.

**Secondary:**
- SQL (PostgreSQL) - Supabase database schema, migrations, and functions in `supabase/`.

## Runtime

**Environment:**
- Flutter SDK - Multi-platform UI framework.

**Package Manager:**
- pub - Dart package manager.
- Lockfile: `pubspec.lock` present.

## Frameworks

**Core:**
- Flutter - Cross-platform UI development for Android, iOS, and Windows.
- Provider ^6.1.1 - Primary state management for the application.
- GoRouter ^13.2.5 - Declarative routing and navigation.

**Testing:**
- flutter_test - Built-in Flutter testing framework.
- mockito ^5.4.4 - Mocking library for unit tests.
- integration_test - Flutter integration testing.

**Build/Dev:**
- build_runner - Code generation for Freezed and JSON Serializable.
- msix - Windows app packaging.
- sentry_dart_plugin - Sentry debug symbol uploads.

## Key Dependencies

**Critical:**
- supabase_flutter ^2.3.4 - Primary backend integration (Auth, DB, Realtime, Storage).
- firebase_core ^4.6.0 - Required for Firebase Messaging (Push Notifications).
- libsignal_protocol_dart 0.7.2 - Implementation of the Signal Protocol for End-to-End Encryption.
- dio ^5.4.0 - Powerful HTTP client for API requests.

**Infrastructure:**
- sentry_flutter ^9.8.0 - Error tracking and performance monitoring.
- flutter_dotenv ^5.1.0 - Environment variable management (local development).
- shared_preferences ^2.2.2 - Simple local key-value storage.
- flutter_secure_storage ^9.0.0 - Secure storage for sensitive data (keys, tokens).

## Configuration

**Environment:**
- Configured via `.env` file (loaded in `lib/services/app_initializer.dart`).
- Firebase options in `lib/firebase_options.dart`.
- Supabase config in `lib/core/config/supabase_config.dart`.

**Build:**
- `pubspec.yaml` - Main dependency and asset configuration.
- `analysis_options.yaml` - Linting and static analysis rules.
- `msix_config` in `pubspec.yaml` for Windows builds.

## Platform Requirements

**Development:**
- Flutter SDK (latest stable).
- Supabase CLI for local backend development.
- Python (for icon generation scripts).

**Production:**
- Android 5.0+ (API 21).
- iOS 12.0+.
- Windows 10/11.
- Supabase Cloud hosting.

---

*Stack analysis: 2026-04-08*
