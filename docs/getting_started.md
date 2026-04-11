# Getting Started

## Prerequisites

- **Flutter** 3.8 or newer (stable channel recommended)
- **Dart** 3.8.0+ (bundled with Flutter; must satisfy `pubspec.yaml` `environment.sdk`)
- **just** (optional but recommended) — [https://github.com/casey/just](https://github.com/casey/just)
- Xcode / Android Studio tooling as needed for iOS and Android targets

Verify versions:

```bash
flutter --version
dart --version
```

## Clone and Setup

```bash
git clone <your-fork-or-template-url> flutter_clean_arch_template
cd flutter_clean_arch_template
flutter pub get
```

If you are creating a **new** application from the template, run the interactive setup script **before** heavy customization:

```bash
dart run tool/setup.dart
```

The script will prompt for:

- Project name (snake_case)
- Organization (reverse domain)
- Display name and description

It updates Dart package imports, Android/iOS identifiers, and related metadata. Afterward run code generation (next section).

## Running the Setup Script

```bash
dart run tool/setup.dart
```

Follow the prompts; confirm with `y` to apply changes. The script runs `flutter pub get` as part of the flow. If you skip renaming, you can still use the template as-is with package name `flutter_clean_arch_template`.

## Code Generation

This project relies on **build_runner** for:

- Riverpod (`*.g.dart`)
- Freezed / json_serializable (`*.freezed.dart`, `*.g.dart`)
- Injectable (`service_locator.config.dart`)
- AutoRoute (`app_router.gr.dart`)

One-shot build:

```bash
just gen
```

Equivalent:

```bash
dart run build_runner build --delete-conflicting-outputs
```

During active development:

```bash
just gen-watch
```

## Running the App

**Development** (default backend/env flags):

```bash
just dev
```

Manual equivalent:

```bash
flutter run --dart-define=ENVIRONMENT=development
```

Other recipes from the root [`justfile`](../justfile):

- `just staging` — `ENVIRONMENT=staging`
- `just prod-debug` — `ENVIRONMENT=production` in debug
- `just release` — release mode with production env
- `just run <env> <device-id>` — custom combination

## Environment Configuration

- Environment files live under **`assets/env/`** (e.g. `.env.development`). They are loaded via **`flutter_dotenv`** through **`AppConfig`** / env managers in `lib/core/env/`.
- Select the active set at run time with **`--dart-define=ENVIRONMENT=...`** (`development` | `staging` | `production`).
- Ensure the matching file exists and is listed under `flutter.assets` in `pubspec.yaml` if you add new env files.

### Auth & Demo Environment Variables

| Variable | Values | Default | Description |
|----------|--------|---------|-------------|
| `AUTH_MODE` | `required` / `optional` | `required` | `required` = all pages need login; `optional` = home page is guest-accessible, only certain pages require login |
| `MOCK_AUTH` | `true` / `false` | `true` (dev) | When `true`, login uses mock data and a "Demo Login" button appears; set `false` for real API calls |

Example `.env.development`:

```env
AUTH_MODE=required
MOCK_AUTH=true
```

Never commit secrets; use CI variables or local untracked overrides for sensitive values.

## App Resources (Icons & Splash)

The template includes configuration for two code-generation tools that produce platform-native assets:

- **`flutter_launcher_icons.yaml`** — generates launcher icons for all platforms from a single source PNG.
- **`flutter_native_splash.yaml`** — generates native splash screens displayed before Flutter renders.

```bash
just gen-icon     # Generate launcher icons
just gen-splash   # Generate native splash screens
```

Place your source images under `assets/icon/` and `assets/splash/`. For detailed configuration options, asset preparation, and platform-specific notes, see [app_resources.md](app_resources.md).

## Development Workflow

1. Create a branch for your work.
2. Implement changes in `lib/features/...` following [architecture.md](architecture.md).
3. Run **`just gen`** after changing annotated classes (Riverpod, Freezed, Injectable, routes).
4. Run **`just analyze`** and **`just test`** before opening a PR.
5. Use **`just clean`** if codegen or plugins get out of sync, then **`just gen`** again.

For a guided feature walkthrough, see [create_new_feature.md](create_new_feature.md).
