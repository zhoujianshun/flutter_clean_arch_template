# 编码规范

## 文件命名

- 所有 Dart 文件使用 **`snake_case`** 命名
- 常见后缀约定：
  - `*_page.dart` — 可路由的页面（`@RoutePage()`）
  - `*_widget.dart` — 可复用 UI 组件
  - `*_provider.dart` — Riverpod Provider（含 `part '*.g.dart'`）
  - `*_repository.dart` / `*_repository_impl.dart` — 领域层接口 / 数据层实现
  - `*_remote_datasource.dart` — REST 数据源（或 `*_local_datasource.dart`）
  - `*_request.dart` — API 请求载荷（命名格式：`{Action}{Feature}Request`）
  - `*_model.dart` — JSON 友好的 DTO，跨层使用（无需独立 Entity 时）
  - `*_entity.dart` — 领域层专用类型（可选）

**示例：** `phone_login_request.dart`、`auth_repository_impl.dart`、`example_list_page.dart`

## 类命名

| 类型 | 风格 | 示例 |
|------|------|------|
| 页面 | `PascalCase` + `Page` | `LoginPage` |
| 组件 | `PascalCase` + `Widget`（通用时） | `AuthNavigationListener` |
| Repository 接口 | `PascalCase` + `Repository` | `AuthRepository` |
| Repository 实现 | 同上 + `Impl` | `AuthRepositoryImpl` |
| 数据源 | `PascalCase` + `RemoteDataSource` | `UserRemoteDataSource` |
| Riverpod Notifier | `PascalCase`（匹配功能名） | `Auth`（生成 `authProvider`） |
| Freezed 模型 | `PascalCase` | `AuthInfoModel` |

## 导入顺序

按以下顺序分组，组间用**空行**分隔：

1. `dart:*`
2. `package:flutter/...` 和其他 `package:`（按字母排序）
3. 项目内部导入 — `package:flutter_clean_arch_template/...`（按字母排序）

示例：

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_clean_arch_template/core/di/service_locator.dart';
import 'package:flutter_clean_arch_template/features/auth/domain/repositories/auth_repository.dart';
```

## Freezed 模式

| 场景 | 模式 |
|------|------|
| 单一数据类（一个主 `factory`） | `@freezed abstract class User with _$User { ... }` |
| 联合类型（状态 / 错误等） | `@freezed sealed class Session with _$Session { ... }` |

始终添加 `.freezed.dart` 和使用 JSON 时的 `.g.dart` 的 `part` 指令：

```dart
part 'user.freezed.dart';
part 'user.g.dart';
```

## Provider 模式

- 优先使用**代码生成**：`@riverpod` 用于函数/简单异步，`@Riverpod` class 用于带方法的 Notifier
- **`keepAlive: true`** 仅在状态需要在 Widget 销毁后保留时使用（如全局会话）
- 在 Notifier 或顶层 Provider 中通过 **`getIt<T>()`** 解析服务
- 编辑后运行 **`just gen`** 刷新 `*.g.dart`

骨架代码：

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

## 错误处理模式

- **Repository** 对可能出现用户可见失败的操作返回 **`Future<Either<Failure, T>>`**
- 在数据源或 Repository 实现中将 Dio 或平台 **异常** 映射为 **`Failure`**
- 在 UI/Notifier 中使用 **`fold`** 或 `lib/core/extensions/dartz/` 下的扩展方法

```dart
final result = await _repository.load();
return result.fold(
  (failure) => throw failure, // 或映射为 AsyncValue.error
  (data) => data,
);
```

- UI 分支判断时优先使用**具体** `Failure` 变体（`NetworkFailure`、`ServerFailure` 等），而非通用字符串
