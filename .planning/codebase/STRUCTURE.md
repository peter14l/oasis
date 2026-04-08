# Codebase Structure

**Analysis Date:** 2026-04-09

## Directory Layout

```
[project-root]/
├── assets/          # Static assets (images, fonts, etc.)
├── build/           # Build artifacts (ignored)
├── lib/             # Source code
│   ├── core/        # Common utilities, base classes, and infrastructure
│   ├── features/    # Business logic and UI split by feature
│   ├── models/      # Global data models
│   ├── painters/    # Custom Canvas painters
│   ├── providers/   # Global state providers
│   ├── routes/      # Navigation and routing configuration
│   ├── screens/     # Shared or high-level screen widgets
│   ├── services/    # Backend services and logic
│   ├── themes/      # App styling and theme configurations
│   └── widgets/     # Reusable UI components
├── supabase/        # Supabase migrations, edge functions, and config
├── test/            # Unit, integration, and widget tests
├── scripts/         # Automation and utility scripts
└── pubspec.yaml     # Dependencies and project config
```

## Directory Purposes

**lib/core/:**
- Purpose: Infrastructure and foundational logic.
- Contains: Network clients, storage wrappers, base errors, extensions, and common utils.
- Key files: `lib/core/network/supabase_client.dart`, `lib/core/result/result.dart`.

**lib/features/:**
- Purpose: Feature-specific vertical slices.
- Contains: Data, Domain, and Presentation subdirectories for each feature.
- Key features: `auth`, `feed`, `messages`, `ripples`, `profile`, `wellness`.

**lib/services/:**
- Purpose: Singletons or global service managers.
- Contains: Logic for notifications, auth, vault, screen time, and more.
- Key files: `lib/services/app_initializer.dart`, `lib/services/auth_service.dart`.

**lib/routes/:**
- Purpose: Application routing and layout definition.
- Contains: Router configuration and shell layouts.
- Key files: `lib/routes/app_router.dart`.

**lib/themes/:**
- Purpose: Visual styling of the app.
- Contains: Light/Dark themes and color schemes.
- Key files: `lib/themes/app_theme.dart`.

**supabase/:**
- Purpose: Backend-as-a-Service configuration and migrations.
- Contains: SQL migrations, edge function source code, and configuration files.

## Key File Locations

**Entry Points:**
- `lib/main.dart`: Main Flutter entry point.
- `lib/services/app_initializer.dart`: App-level dependency injection and startup.

**Configuration:**
- `pubspec.yaml`: App dependencies and assets.
- `firebase.json`: Firebase configuration.
- `.env`: Environment variables (injected at build time).

**Core Logic:**
- `lib/core/network/supabase_client.dart`: Database client.
- `lib/features/messages/data/signal/signal_service.dart`: Encryption logic.

**Testing:**
- `test/`: Project-wide test suite.
- `test/features/`: Feature-specific tests.

## Naming Conventions

**Files:**
- Lowercase with underscores (snake_case): `app_router.dart`, `feed_provider.dart`.

**Directories:**
- Lowercase with underscores (snake_case): `presentation/`, `datasources/`.

**Classes:**
- PascalCase: `FeedProvider`, `AppRouter`.

**Variables/Functions:**
- camelCase: `loadSettings()`, `isLoggedIn`.

## Where to Add New Code

**New Feature:**
1. Create a new folder in `lib/features/`.
2. Implement subdirectories for `data`, `domain`, and `presentation`.
3. Register any new Providers in `lib/services/app_initializer.dart`.
4. Define new routes in `lib/routes/app_router.dart`.

**New Component/Module:**
- Shared components: `lib/widgets/`.
- Feature-specific widgets: `lib/features/[feature]/presentation/widgets/`.

**Utilities:**
- General helpers: `lib/core/utils/`.
- Shared models: `lib/models/` or the relevant feature's `domain/models`.

## Special Directories

**lib/painters/:**
- Purpose: Custom painters for complex UI elements like gradients, charts, or specialized backgrounds.
- Committed: Yes.

**stubs/:**
- Purpose: Local overrides or platform-specific stub implementations for compatibility (e.g., Windows mocks).
- Committed: Yes.

**scripts/:**
- Purpose: Automation for building, testing, or database management.
- Committed: Yes.

---

*Structure analysis: 2026-04-09*
