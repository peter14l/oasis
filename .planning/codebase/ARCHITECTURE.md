# Architecture

**Analysis Date:** 2026-04-09

## Pattern Overview

**Overall:** Clean Architecture with Feature-Driven Structure

**Key Characteristics:**
- **Vertical Feature Slicing:** Each major functionality (Auth, Feed, Messages, etc.) is isolated in `lib/features/` with its own data, domain, and presentation layers.
- **Layered Decoupling:** Uses the Repository pattern to decouple the UI from data sources, ensuring that the domain logic remains pure.
- **Adaptive UI Architecture:** A common shell (`MainLayout`) in `lib/routes/app_router.dart` adapts the navigation and layout based on the platform (Mobile Bottom Nav vs. Desktop Nav Rail).

## Layers

**Presentation Layer:**
- Purpose: Handles UI logic and state management.
- Location: `lib/features/[feature]/presentation/` and `lib/screens/`
- Contains: Flutter Widgets, Screens, and Providers (`ChangeNotifier`).
- Depends on: Domain Layer (Use Cases and Entities).
- Used by: Flutter Framework (Entry points).

**Domain Layer:**
- Purpose: Contains business logic and high-level abstractions.
- Location: `lib/features/[feature]/domain/`
- Contains: Entities (Models), Repository Interfaces, and Use Cases.
- Depends on: None (Independent).
- Used by: Presentation Layer.

**Data Layer:**
- Purpose: Handles data retrieval and persistence.
- Location: `lib/features/[feature]/data/`
- Contains: Repository implementations, Datasources (Remote/Local), and DTOs (Data Transfer Objects).
- Depends on: Core (Network/Storage clients) and Domain (for Repository Interfaces).
- Used by: Domain Layer (via Interface implementation).

**Services Layer:**
- Purpose: Global logic that spans multiple features or provides infrastructure services.
- Location: `lib/services/`
- Contains: Singletons or global service classes like `AuthService`, `NotificationManager`, and `WellnessService`.
- Depends on: Core and Data layers.
- Used by: Presentation Layer (via Providers).

## Data Flow

**Standard Request Flow:**

1. **UI** (Screen/Widget) triggers an action in a **Provider** (`lib/features/[feature]/presentation/providers/`).
2. **Provider** calls a **Use Case** (`lib/features/[feature]/domain/usecases/`).
3. **Use Case** calls the **Repository Interface** (`lib/features/[feature]/domain/repositories/`).
4. **Repository Implementation** (`lib/features/[feature]/data/repositories/`) fetches data from a **Datasource** (`lib/features/[feature]/data/datasources/`).
5. **Datasource** uses a **Network Client** (`lib/core/network/supabase_client.dart`) or **Storage** (`lib/core/storage/prefs_storage.dart`).
6. Data flows back up as **Entities**, and the **Provider** updates the state, triggering a UI rebuild.

**State Management:**
- Uses the `provider` package.
- State is typically held in `ChangeNotifier` classes within `presentation/providers/`.
- Global state (Auth, Theme, Settings) is managed at the root in `lib/services/app_initializer.dart`.

## Key Abstractions

**Repository:**
- Purpose: Abstract interface for data operations.
- Examples: `lib/features/auth/domain/repositories/auth_repository.dart`
- Pattern: Repository Pattern.

**Use Case:**
- Purpose: Encapsulates a single business action.
- Examples: `lib/features/auth/domain/usecases/sign_in_with_email.dart`
- Pattern: Command Pattern / Use Case Pattern.

**Provider:**
- Purpose: Bridges the UI and business logic, managing local or global state.
- Examples: `lib/features/feed/presentation/providers/feed_provider.dart`
- Pattern: Observer Pattern / ChangeNotifier.

## Entry Points

**App Main Entry:**
- Location: `lib/main.dart`
- Triggers: Flutter engine startup.
- Responsibilities: Initializes bindings, triggers `AppInitializer`, and runs `MyApp`.

**App Initializer:**
- Location: `lib/services/app_initializer.dart`
- Triggers: Called by `main()`.
- Responsibilities: Configures Supabase, Firebase, Sentry, and constructs the `MultiProvider` tree.

**App Router:**
- Location: `lib/routes/app_router.dart`
- Triggers: `MaterialApp.router` initialization.
- Responsibilities: Defines the route hierarchy, auth-gated redirects, and the adaptive `MainLayout` shell.

## Error Handling

**Strategy:** Result wrapper and custom AppExceptions.

**Patterns:**
- **Result Object:** `lib/core/result/result.dart` wraps success and failure states.
- **Custom Exceptions:** `lib/core/errors/app_exception.dart` provides typed error handling across layers.
- **Global Monitoring:** Sentry integration for crash reporting and error tracking.

## Cross-Cutting Concerns

**Logging:** Uses `debugPrint` and Sentry for error tracking.
**Validation:** Handled within Use Cases or specifically designed Validators (though some were removed in recent versions).
**Authentication:** Managed via `AuthService` and `AuthProvider`, with Supabase as the identity provider.
**Encryption:** End-to-end encryption for messaging using `libsignal_protocol_dart` via `lib/features/messages/data/signal/signal_service.dart`.
**Digital Wellbeing:** Integrated screen time and focus mode tracking via `ScreenTimeService` and `WellnessService`.

---

*Architecture analysis: 2026-04-09*
