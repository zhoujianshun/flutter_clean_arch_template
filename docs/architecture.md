# Architecture

This template organizes code by **feature** and applies **Clean Architecture** ideas: stable domain-facing interfaces, infrastructure at the edges, and UI that stays thin.

## Architecture Principles

1. **Feature-first** — Business capabilities are grouped under `lib/features/<feature>/` instead of technical layers at the root.
2. **Dependency inversion** — High-level modules (presentation) depend on abstractions (`abstract class XRepository`) implemented in the data layer.
3. **Single direction of dependencies** — UI → domain contracts ← data implementations. Data does not import presentation.
4. **Explicit errors** — Repository methods return `Future<Either<Failure, T>>` so callers handle failures deliberately.
5. **Pragmatic domain** — Not every response needs a separate “entity”; introduce domain types when mapping or business rules justify them.
6. **No use-case layer by default** — Providers orchestrate validation and calls to repositories directly (keeps the template approachable).

## Layer Description

### Core (`lib/core/`)

Infrastructure shared by the whole app:

- Networking, token strategy, global error types
- Router, route guards, theme, environment loading
- Storage facades (Hive, SharedPreferences, secure storage)
- Logging, DI bootstrap, app initialization

Core must not contain feature-specific business rules.

### Shared (`lib/shared/`)

Reusable **non-feature** building blocks:

- Generic widgets (lists, buttons, empty/error states)
- Shared DTO helpers (e.g. `ApiResponse`, pagination types)
- Cross-cutting utilities and optional shared APIs

Use shared code when two or more features need the same thing; otherwise keep types inside the feature.

### Features (`lib/features/<name>/`)

Each feature is a vertical slice:

| Subfolder | Role |
|-----------|------|
| `data/` | Datasources, repository implementations, API models/requests |
| `domain/` | Repository interfaces, entities (when needed) |
| `presentation/` | Pages, widgets, Riverpod providers |

## Feature Internal Structure

Typical layout:

```text
features/orders/
├── data/
│   ├── datasources/
│   │   └── order_remote_datasource.dart
│   ├── models/
│   │   └── order_item_model.dart
│   └── repositories/
│       └── order_repository_impl.dart
├── domain/
│   ├── entities/          # optional
│   └── repositories/
│       └── order_repository.dart
└── presentation/
    ├── pages/
    ├── providers/
    └── widgets/
```

## Dependency Direction (Text Diagram)

```text
┌─────────────────────────────────────────────────────────┐
│                    presentation                          │
│  (Pages, Widgets, @riverpod / Riverpod notifiers)        │
└───────────────────────────┬─────────────────────────────┘
                            │ uses
                            ▼
┌─────────────────────────────────────────────────────────┐
│                      domain                              │
│  (Repository interfaces, optional entities)             │
└───────────────────────────▲─────────────────────────────┘
                            │ implements
┌───────────────────────────┴─────────────────────────────┐
│                        data                              │
│  (Datasources, models, repository implementations)       │
└───────────────────────────┬─────────────────────────────┘
                            │ uses
                            ▼
┌─────────────────────────────────────────────────────────┐
│              core + shared infrastructure                │
│  ApiClient, storage, Failure, shared widgets, etc.       │
└─────────────────────────────────────────────────────────┘
```

Presentation may import **domain** and **core/shared**.  
Data may import **domain**, **core**, and **shared**.  
Domain should stay minimal—prefer depending on `Failure` and simple value types.

## Data Flow

1. **User action** triggers a method on a Riverpod notifier or a one-off `FutureProvider`/`AsyncNotifier`.
2. The provider resolves dependencies with **`getIt<SomeRepository>()`** (or constructor injection for test doubles).
3. The **repository** coordinates **datasources** (remote/local), maps JSON to models, and returns **`Either<Failure, T>`**.
4. The provider maps `Left` to user-visible errors (snackbars, inline messages) and `Right` to state updates.
5. **Widgets** `ref.watch` providers and rebuild when `AsyncValue` or notifier state changes.

Optional: `BaseAPI` / `ApiClient` apply interceptors (auth header, logging, retry, connectivity) before data reaches datasources.

## State Management with Riverpod

- Providers are declared with **`@riverpod`** or **`@Riverpod(keepAlive: true)`** and `riverpod_generator`.
- **Feature state** (e.g. authenticated user, paginated list) lives next to the feature under `presentation/providers/`.
- **Global app state** (theme mode, locale) may live under `core/` when it is not owned by a single feature.
- Generated `*.g.dart` files must be committed or regenerated with `just gen` after edits.

## Error Handling with Dartz `Either`

- **`Right(value)`** — success.
- **`Left(failure)`** — domain-level failure, usually a **`Failure`** sealed type (`ServerFailure`, `NetworkFailure`, …).

Example handling in a notifier:

```dart
final result = await _repository.load();
result.fold(
  (failure) => state = AsyncValue.error(failure, StackTrace.current),
  (data) => state = AsyncValue.data(data),
);
```

Datasources may use `handleApiCall` helpers that already return `Either<Failure, T>` so repositories stay thin.

## Dependency Injection with GetIt

- **`configureDependencies()`** in `lib/core/di/service_locator.dart` initializes **`getIt.init()`** from generated `service_locator.config.dart`.
- Classes register with **`@injectable` / `@singleton` / `@Singleton(as: Interface)`**.
- **`RegisterModule`** provides async/manual singletons (e.g. composite `StorageService`).
- In providers, prefer **`getIt<AuthRepository>()`** for a consistent lookup pattern across the app.

After adding or changing registrations, run **`just gen`** so Injectable and Riverpod outputs stay in sync.
