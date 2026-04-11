# Core Modules

Overview of `lib/core/` building blocks and how they fit together.

## Network

| Piece | Path / role |
|-------|----------------|
| **`ApiClient`** | `core/network/api_client.dart` — owns `Dio`, base options, attaches interceptors |
| **Interceptors** | `auth_interceptor.dart` (headers / token refresh hooks), `connectivity_interceptor.dart`, `retry_interceptor.dart`, optional `TalkerDioLogger` |
| **`BaseAPI`** | `core/network/base_api.dart` — helpers such as `handleApiCall` returning `Either<Failure, T>` |
| **Token pipeline** | `token/token_manager.dart`, `token_storage.dart`, `single_token_strategy.dart`, `dual_token_strategy.dart` — read/write tokens and attach authorization |
| **Errors** | `network_error.dart`, `network_error_notifier.dart` — surface connectivity or HTTP issues to the app |
| **Supporting** | `network_info.dart`, `api_response_handler.dart`, `log_sanitizer.dart`, `auth_config.dart` |

**Flow:** `ApiClient` executes requests → interceptors add auth / log / retry → datasources call `apiClient.get/post` → `BaseAPI` normalizes responses into `Either`.

## Storage

| Piece | Path / role |
|-------|----------------|
| **`HiveService`** | `core/storage/local/hive_service.dart` — initializes Hive boxes |
| **`SharedPrefsService`** | typed access to `SharedPreferences` |
| **`SecureStorageService`** | wraps `flutter_secure_storage` for secrets |
| **`StorageService`** | `core/storage/storage_service.dart` — facade composed in `RegisterModule` |
| **`storage_keys.dart`** | shared key constants |

Use **`StorageService`** from DI when a feature needs cached flags or non-sensitive blobs; use **secure** storage for tokens (often coordinated with `TokenStorage`).

## Logger (Talker)

| Piece | Path / role |
|-------|----------------|
| **`talker_config.dart`** | Talker instance, filters, Riverpod observer wiring |
| **`app_logger.dart`** | App-facing logging API |
| **Observers** | `observers/console_observer.dart`, `observers/file_observer.dart` |
| **Filters / formatters** | redact sensitive data, control verbosity |

Dio traffic can be logged via **`talker_dio_logger`** inside `ApiClient`. The template may include a **Logger Viewer** route for debugging builds.

## Router (AutoRoute)

| Piece | Path / role |
|-------|----------------|
| **`app_router.dart`** | Declares `AutoRoute` tree, `part 'app_router.gr.dart'` |
| **`AuthGuard` / `DebouncerGuard`** | `core/router/guards/` — block unauthenticated routes (dual-mode) or rapid duplicate navigation |
| **`router_provider.dart`** | Exposes router instance to Riverpod / MaterialApp |

Pages use **`@RoutePage()`** on widgets; after changes, run codegen to refresh **`app_router.gr.dart`**.

### AuthGuard Dual Mode

`AuthGuard` reads **`AppConfig.authMode`** (sourced from the `AUTH_MODE` env variable) to decide how strictly to enforce authentication:

| Mode | Behavior |
|------|----------|
| `AuthMode.required` | Every route (except `unauthRequiredRoutes`) requires a valid token. Unauthenticated users are redirected to `LoginRoute`. |
| `AuthMode.optional` | Only routes listed in `AuthGuard.authRequiredRoutes` (e.g. `ProfileRoute`) require login. All other routes are freely accessible. |

To protect additional routes in `optional` mode, add their route names to the `authRequiredRoutes` list in `auth_guard.dart`.

### Mock Authentication

When **`AppConfig.mockAuth`** is `true` (`MOCK_AUTH=true` in `.env`):

- `AuthRepositoryImpl.phoneLogin()` returns a hardcoded mock token instead of calling the remote API.
- `AuthRepositoryImpl.getCurrentUser()` returns a mock user profile.
- The **Login page** displays a "Demo Login" button for one-tap access.
- `logout()` skips the remote logout call and only clears local tokens.

This allows the template to function end-to-end without a live backend.

## DI (GetIt + Injectable)

| Piece | Path / role |
|-------|----------------|
| **`service_locator.dart`** | `getIt` singleton, `@InjectableInit()`, `configureDependencies()` |
| **`service_locator.config.dart`** | Generated registrations |
| **`RegisterModule`** | Manual `@module` for async singletons (storage, `ApiClient`, token manager) |

Annotate classes with **`@Singleton(as: Interface)`**, **`@singleton`**, or **`@Injectable()`**; then run **`just gen`**.

## Environment (dotenv)

| Piece | Path / role |
|-------|----------------|
| **`app_config.dart`** | Static access to base URLs, feature flags loaded from env |
| **`env_config_manager.dart`** | Loads the correct `.env.*` file for `ENVIRONMENT` |
| **Assets** | `assets/env/` — keep one file per flavor; referenced in `pubspec.yaml` |

Run the app with **`--dart-define=ENVIRONMENT=development|staging|production`** (see `justfile` recipes).

## Theme (Material 3)

| Piece | Path / role |
|-------|----------------|
| **`app_theme.dart`** | Light/dark `ThemeData`, color scheme |
| **`theme_mode_provider.dart`** | Riverpod-controlled `ThemeMode` |

Widgets should read colors and text styles from **`Theme.of(context)`** whenever possible.

## Error Handling (Failure, Exception)

| Piece | Path / role |
|-------|----------------|
| **`failures.dart`** | Freezed **`sealed class Failure`** — `ServerFailure`, `NetworkFailure`, `ValidationFailure`, `AuthFailure`, etc. |
| **`exceptions.dart`** | Throwables mapped to failures inside datasources/repositories |
| **`global_error_handler.dart`**, **`error_recovery.dart`**, **`error_utils.dart`** | Centralized handling, mapping, recovery helpers |

**Guideline:** throw **exceptions** at the IO boundary; return **`Either<Failure, T>`** from repositories so presentation stays declarative.

## App Resources (Launcher Icons & Native Splash)

| Piece | Path / role |
|-------|-------------|
| **`flutter_launcher_icons.yaml`** | Config for generating platform launcher icons from a single source image |
| **`flutter_native_splash.yaml`** | Config for generating native splash screens (shown before Flutter renders) |
| **`AppInitializer`** | `core/initializers/app_initializer.dart` — calls `FlutterNativeSplash.preserve()` to keep the native splash visible during async setup |
| **`SplashPage`** | `features/app/.../splash_page.dart` — calls `FlutterNativeSplash.remove()` when initialization completes |

Commands: **`just gen-icon`** for icons, **`just gen-splash`** for splash screens.

For detailed usage, asset preparation, and platform-specific notes, see [app_resources.md](app_resources.md).
