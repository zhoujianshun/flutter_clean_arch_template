# Core 层模块说明

`lib/core/` 各构建块的概览及其协作方式。

## 网络层（Network）

| 组件 | 路径 / 职责 |
|------|------------|
| **`ApiClient`** | `core/network/api_client.dart` — 持有 `Dio` 实例、基础配置、挂载拦截器 |
| **拦截器** | `auth_interceptor.dart`（认证头/Token 刷新钩子）、`connectivity_interceptor.dart`（连接检测）、`retry_interceptor.dart`（失败重试）、可选 `TalkerDioLogger` |
| **`BaseAPI`** | `core/network/base_api.dart` — 提供 `handleApiCall` 等助手方法，返回 `Either<Failure, T>` |
| **Token 管线** | `token/token_manager.dart`、`token_storage.dart`、`single_token_strategy.dart`、`dual_token_strategy.dart` — 读写 Token、挂载 Authorization |
| **错误** | `network_error.dart`、`network_error_notifier.dart` — 将连接或 HTTP 问题通知给应用 |
| **辅助** | `network_info.dart`（网络状态）、`api_response_handler.dart`（响应处理）、`log_sanitizer.dart`（日志脱敏）、`auth_config.dart`（公开路径配置） |

**请求流程：** `ApiClient` 发起请求 → 拦截器添加认证/日志/重试 → DataSource 调用 `apiClient.get/post` → `BaseAPI` 将响应标准化为 `Either`。

## 存储层（Storage）

| 组件 | 路径 / 职责 |
|------|------------|
| **`HiveService`** | `core/storage/local/hive_service.dart` — 初始化 Hive Box |
| **`SharedPrefsService`** | 对 `SharedPreferences` 的类型安全封装 |
| **`SecureStorageService`** | 封装 `flutter_secure_storage` 用于敏感数据 |
| **`StorageService`** | `core/storage/storage_service.dart` — 门面类，在 `RegisterModule` 中组合 |
| **`storage_keys.dart`** | 共享键名常量 |

功能模块需要缓存标志或非敏感数据时，通过 DI 获取 **`StorageService`**；Token 等敏感数据使用 **SecureStorage**（通常由 `TokenStorage` 协调）。

## 日志系统（Talker）

| 组件 | 路径 / 职责 |
|------|------------|
| **`talker_config.dart`** | Talker 实例创建、过滤器、Riverpod 观察器配置 |
| **`app_logger.dart`** | 面向应用的日志 API（`AppLogger.debug/info/warning/error`） |
| **观察器** | `observers/console_observer.dart`（控制台）、`observers/file_observer.dart`（文件） |
| **过滤器/格式化器** | 脱敏敏感数据、控制日志详细级别 |

Dio 请求日志通过 `ApiClient` 中的 **`talker_dio_logger`** 实现。模版包含 **Logger Viewer** 路由用于调试构建。

## 路由（AutoRoute）

| 组件 | 路径 / 职责 |
|------|------------|
| **`app_router.dart`** | 声明 `AutoRoute` 路由树，`part 'app_router.gr.dart'` |
| **`AuthGuard` / `DebouncerGuard`** | `core/router/guards/` — 拦截未认证路由（双模式）或防止快速重复导航 |
| **`router_provider.dart`** | 通过 Riverpod 暴露路由实例给 MaterialApp |

页面使用 **`@RoutePage()`** 注解；修改后运行代码生成以刷新 **`app_router.gr.dart`**。

### AuthGuard 双认证模式

`AuthGuard` 读取 **`AppConfig.authMode`**（来源于 `AUTH_MODE` 环境变量）决定认证的严格程度：

| 模式 | 行为 |
|------|------|
| `AuthMode.required` | 除 `unauthRequiredRoutes` 外，所有路由均需有效 Token。未认证用户跳转到 `LoginRoute` |
| `AuthMode.optional` | 仅 `AuthGuard.authRequiredRoutes` 中列出的路由（如 `ProfileRoute`）需要登录。其余路由自由访问 |

在 `optional` 模式下保护更多路由，只需将路由名称添加到 `auth_guard.dart` 的 `authRequiredRoutes` 列表中。

### Mock 认证

当 **`AppConfig.mockAuth`** 为 `true`（`.env` 中 `MOCK_AUTH=true`）时：

- `AuthRepositoryImpl.phoneLogin()` 返回硬编码的 Mock Token，不调用远程 API
- `AuthRepositoryImpl.getCurrentUser()` 返回 Mock 用户信息
- **登录页**显示「Demo Login」按钮，一键即可登录
- `logout()` 跳过远程登出调用，仅清除本地 Token

这使得模版无需真实后端即可完整运行。

## 依赖注入（GetIt + Injectable）

| 组件 | 路径 / 职责 |
|------|------------|
| **`service_locator.dart`** | `getIt` 全局实例、`@InjectableInit()`、`configureDependencies()` |
| **`service_locator.config.dart`** | 生成的注册代码 |
| **`RegisterModule`** | `@module` 手动注册异步单例（存储、`ApiClient`、Token 管理器） |

使用 **`@Singleton(as: Interface)`**、**`@singleton`** 或 **`@Injectable()`** 注解类；然后运行 **`just gen`**。

## 环境配置（dotenv）

| 组件 | 路径 / 职责 |
|------|------------|
| **`app_config.dart`** | 静态访问基础 URL、功能开关（从环境变量加载） |
| **`env_config_manager.dart`** | 根据 `ENVIRONMENT` 加载正确的 `.env.*` 文件 |
| **资源文件** | `assets/env/` — 每个环境一个文件；在 `pubspec.yaml` 中引用 |

通过 **`--dart-define=ENVIRONMENT=development|staging|production`** 运行应用（参见 `justfile` 命令）。

## 主题（Material 3）

| 组件 | 路径 / 职责 |
|------|------------|
| **`app_theme.dart`** | 浅色/深色 `ThemeData`、配色方案、`AppColors`、`AppAdaptiveColors`、`AppTextStyles` |
| **`theme_mode_provider.dart`** | Riverpod 控制的 `ThemeMode` 切换 |

组件应尽量从 **`Theme.of(context)`** 读取颜色和文本样式。

## 错误处理（Failure / Exception）

| 组件 | 路径 / 职责 |
|------|------------|
| **`failures.dart`** | Freezed **`sealed class Failure`** — `ServerFailure`、`NetworkFailure`、`ValidationFailure`、`AuthFailure` 等 |
| **`exceptions.dart`** | 在数据源/Repository 中映射为 Failure 的可抛异常 |
| **`global_error_handler.dart`** / **`error_recovery.dart`** / **`error_utils.dart`** | 集中处理、映射、恢复助手 |

**原则：** 在 IO 边界抛出 **异常**；从 Repository 返回 **`Either<Failure, T>`**，使表现层保持声明式。
