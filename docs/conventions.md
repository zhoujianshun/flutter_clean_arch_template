# Coding Conventions

## File Naming

- Use **`snake_case`** for all Dart filenames.
- Typical suffixes:
  - `*_page.dart` — routable screens (`@RoutePage()`)
  - `*_widget.dart` — reusable UI pieces
  - `*_provider.dart` — Riverpod providers (with `part '*.g.dart'`)
  - `*_repository.dart` / `*_repository_impl.dart` — domain contract / data implementation
  - `*_remote_datasource.dart` — REST (or `*_local_datasource.dart`)
  - `*_request.dart` — API request payloads (`{Action}{Feature}Request`)
  - `*_model.dart` — JSON-friendly DTOs used across layers when no separate entity is needed
  - `*_entity.dart` — domain-only types (optional)

**Examples:** `phone_login_request.dart`, `auth_repository_impl.dart`, `example_list_page.dart`.

## Class Naming

| Kind | Style | Example |
|------|--------|---------|
| Page | `PascalCase` + `Page` | `LoginPage` |
| Widget | `PascalCase` + `Widget` when generic | `AuthNavigationListener` |
| Repository interface | `PascalCase` + `Repository` | `AuthRepository` |
| Repository impl | same + `Impl` | `AuthRepositoryImpl` |
| Datasource | `PascalCase` + `RemoteDataSource` | `UserRemoteDataSource` |
| Riverpod notifier | `PascalCase` matching feature | `Auth` (generated `authProvider`) |
| Freezed model | `PascalCase` | `AuthInfoModel` |

## Import Ordering

Group imports in this order, with a **blank line** between groups:

1. `dart:*`
2. `package:flutter/...` and other `package:` (alphabetical)
3. Project imports — `package:flutter_clean_arch_template/...` (alphabetical)

Example:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_clean_arch_template/core/di/service_locator.dart';
import 'package:flutter_clean_arch_template/features/auth/domain/repositories/auth_repository.dart';
```

## Freezed Patterns

| Use case | Pattern |
|----------|---------|
| Single product type (one main `factory`) | `@freezed abstract class User with _$User { ... }` |
| Discriminated union (states / errors) | `@freezed sealed class Session with _$Session { ... }` |

Always add `part` files for `.freezed.dart` and `.g.dart` when using JSON.

```dart
part 'user.freezed.dart';
part 'user.g.dart';
```

## Provider Patterns

- Prefer **codegen**: `@riverpod` for functions / simple async, `@Riverpod` class for notifiers with methods.
- Use **`keepAlive: true`** only when the state must survive widget disposal (e.g. global session).
- Resolve services with **`getIt<T>()`** inside notifiers or top-level providers.
- After edits, run **`just gen`** to refresh `*.g.dart`.

Skeleton:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'feature_provider.g.dart';

@riverpod
Future<MyData> myData(Ref ref) async { ... }

@Riverpod(keepAlive: true)
class FeatureController extends _$FeatureController {
  @override
  FutureOr<FeatureState> build() => const FeatureState.initial();
}
```

## Error Handling Patterns

- **Repositories** return **`Future<Either<Failure, T>>`** for operations that can fail in a user-visible way.
- Map **exceptions** from Dio or platform code to **`Failure`** in datasources or repository implementations.
- In UI/notifiers, use **`fold`** or extensions under `lib/core/extensions/dartz/` if present.

```dart
final result = await _repository.load();
return result.fold(
  (failure) => throw failure, // or map to AsyncValue.error
  (data) => data,
);
```

- Prefer **specific** `Failure` variants (`NetworkFailure`, `ServerFailure`, …) over generic strings when branching in the UI.
