# Flutter Clean Architecture Template

<!-- Badges: add CI, license, Flutter/Dart versions, etc. -->
<!--
[![Flutter](https://img.shields.io/badge/Flutter-3.8+-02569B?logo=flutter)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
-->

A production-ready Flutter project template featuring **Feature-First** structure, **DDD-oriented** boundaries, and **Clean Architecture**, with Riverpod, AutoRoute, GetIt, Freezed, Dio, and shared UI building blocks.

## Features

- **Clean Architecture** — clear separation of concerns and testable boundaries
- **Feature-First structure** — each capability lives under `lib/features/<feature>/`
- **Riverpod 3.0+** — codegen providers (`riverpod_annotation` / `riverpod_generator`)
- **AutoRoute** — type-safe, declarative navigation and generated routes
- **GetIt + Injectable** — compile-time friendly dependency injection
- **Dio** — HTTP client with interceptors, retry, connectivity checks, and token hooks
- **Freezed** — immutable models and algebraic data types
- **Dartz `Either`** — explicit success/failure flows in repositories
- **Multi-environment** — `development` / `staging` / `production` via `--dart-define`
- **30+ reusable UI components** — buttons, lists, states, dialogs, and more under `lib/shared/widgets/`
- **Talker** — structured logging, Dio integration, and optional Riverpod observer
- **flutter_screenutil** — responsive layout against a design baseline
- **l10n** — Flutter gen-l10n with ARB files (`lib/l10n/`)

## Tech Stack

| Library | Version (constraint) | Purpose |
|--------|----------------------|---------|
| Flutter SDK | ≥ 3.8 (see `environment`) | UI framework |
| Dart SDK | ≥ 3.8.0 | Language |
| flutter_riverpod | ^3.0.0 | State management |
| riverpod_annotation / riverpod_generator | ^4.0.0 / ^4.0.0+1 | Provider codegen |
| auto_route / auto_route_generator | ^11.1.0 / ^10.2.4 | Routing & codegen |
| dio | ^5.9.0 | Networking |
| get_it / injectable | ^9.2.1 / ^2.5.1 | Service locator & DI codegen |
| freezed / freezed_annotation | ^3.2.3 / ^3.1.0 | Immutable models & unions |
| json_serializable / json_annotation | ^6.11.1 / ^4.9.0 | JSON codegen |
| dartz | ^0.10.1 | `Either` for errors |
| flutter_dotenv | ^6.0.0 | Environment files |
| hive / hive_flutter | ^2.2.3 / ^1.1.0 | Local NoSQL |
| shared_preferences | ^2.5.3 | Key-value preferences |
| flutter_secure_storage | ^10.0.0 | Secure token storage |
| talker_flutter / talker_dio_logger / talker_riverpod_logger | ^5.x | Logging & integrations |
| flutter_screenutil | ^5.9.3 | Screen adaptation |
| intl + flutter_localizations | SDK / ^0.20.2 | Internationalization |
| build_runner | ^2.5.4 | Code generation orchestration |

## Quick Start

1. **Clone** this repository (or use it as a GitHub template) and open the project folder.
2. **Setup** — install dependencies and run the interactive renamer if you are starting a new app:
   ```bash
   flutter pub get
   dart run tool/setup.dart   # optional: rename package, org, display name
   just gen                   # or: dart run build_runner build --delete-conflicting-outputs
   ```
3. **Run** the app (development environment):
   ```bash
   just dev
   ```
   Or: `flutter run --dart-define=ENVIRONMENT=development`

## Project Structure

```text
lib/
├── core/                 # App-wide infrastructure (no feature business rules)
│   ├── constants/
│   ├── di/
│   ├── env/
│   ├── errors/
│   ├── extensions/
│   ├── initializers/
│   ├── l10n/
│   ├── logger/
│   ├── network/
│   ├── router/
│   ├── storage/
│   └── theme/
├── shared/               # Cross-feature reuse (widgets, utils, shared APIs/models)
│   ├── apis/
│   ├── cache/
│   ├── models/
│   ├── services/
│   ├── utils/
│   └── widgets/
├── features/             # Vertical slices (example: auth, app shell, _example)
│   ├── <feature>/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── ...
├── l10n/                 # ARB translation sources
└── main.dart
```

Reference implementations:

- `lib/features/auth/` — authentication, remote datasource, repository, Riverpod notifier
- `lib/features/_example/` — list/detail flow with pagination-style repository (mock data)
- `lib/features/app/` — shell, splash, onboarding, settings, dev tools routes

## Architecture Overview

- **Presentation** — pages, widgets, and Riverpod providers/notifiers. Calls **repository interfaces** from the domain layer (typically via `getIt<YourRepository>()`).
- **Domain** — repository contracts and optional entities when the API shape does not match UI needs.
- **Data** — datasources (REST, local), DTOs/models, and repository **implementations** registered with Injectable.

Dependency rule: **Presentation → Domain ← Data**. The UI never depends on concrete repository or datasource classes—only on abstractions and shared/core utilities.

See [docs/architecture.md](docs/architecture.md) for a deeper walkthrough.

## Available Commands

Commands are defined in the [`justfile`](justfile). Install [just](https://github.com/casey/just) to use them.

| Command | Description |
|---------|-------------|
| `just` | List all recipes (default) |
| `just dev` | Run app with `ENVIRONMENT=development` |
| `just staging` | Run with `ENVIRONMENT=staging` |
| `just prod-debug` | Run with `ENVIRONMENT=production` (debug) |
| `just release` | Run release build with `ENVIRONMENT=production` |
| `just android-build-debug` | Build debug APK (arm64) |
| `just android-build-release` | Build release APK (arm64) |
| `just ios-build` | Build iOS release |
| `just gen` | `dart run build_runner build --delete-conflicting-outputs` |
| `just gen-watch` | Watch mode code generation |
| `just clean` | `flutter clean && flutter pub get` |
| `just reset` | `clean` then `gen` |
| `just gen-icon` | Generate launcher icons |
| `just gen-splash` | Generate native splash |
| `just analyze` | `flutter analyze --no-fatal-infos` |
| `just test` | `flutter test` |
| `just deps` | `flutter pub get` |
| `just deps-upgrade` | `flutter pub upgrade` |
| `just devices` | `flutter devices` |
| `just run <env> <device>` | Run with custom env and `--device-id` |
| `just check` | Print Flutter version, list `assets/env/`, sample deps |

## Creating a New Feature

1. Create `lib/features/<name>/{data,domain,presentation}/` with the usual subfolders (`datasources`, `models`, `repositories`, `pages`, `providers`, `widgets` as needed).
2. Add Freezed models/requests under `data/models/`, repository interface under `domain/repositories/`, implementation + datasource under `data/`.
3. Annotate implementations with `@Singleton(as: YourRepository)` or `@Injectable()` and run `just gen`.
4. Add `@RoutePage()` screens and register routes in `lib/core/router/app_router.dart`.
5. Expose state with `@riverpod` / `@Riverpod` providers that call `getIt<YourRepository>()`.

Step-by-step tutorial: [docs/create_new_feature.md](docs/create_new_feature.md).

## Documentation

| Document | Description |
|----------|-------------|
| [docs/getting_started.md](docs/getting_started.md) | Prerequisites, setup, codegen, run, env |
| [docs/architecture.md](docs/architecture.md) | Layers, dependency flow, Riverpod & Either |
| [docs/create_new_feature.md](docs/create_new_feature.md) | End-to-end feature tutorial |
| [docs/conventions.md](docs/conventions.md) | Naming, imports, Freezed, providers |
| [docs/core_modules.md](docs/core_modules.md) | Core packages (network, storage, router, …) |

## License

MIT
