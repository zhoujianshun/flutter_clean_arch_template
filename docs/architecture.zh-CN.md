# 架构说明

本模版按**功能优先**组织代码，并应用**整洁架构**思想：稳定的领域接口、基础设施位于边缘、UI 层尽量轻薄。

## 架构原则

1. **功能优先（Feature-First）** — 业务功能按 `lib/features/<feature>/` 分组，而非在根目录按技术层级分组
2. **依赖反转** — 上层模块（表现层）依赖抽象（`abstract class XRepository`），由数据层实现
3. **单向依赖** — UI → 领域契约 ← 数据实现。数据层不引用表现层
4. **显式错误处理** — Repository 方法返回 `Future<Either<Failure, T>>`，调用方主动处理失败
5. **务实的领域层** — 并非每个 API 响应都需要独立的 Entity；仅在需要映射或业务规则时才引入
6. **默认无 UseCase 层** — Provider 直接调用 Repository 完成参数校验和请求编排（保持模版简洁）

## 层级说明

### Core 层（`lib/core/`）

全应用共享的基础设施：

- 网络请求、Token 策略、全局错误类型
- 路由、路由守卫、主题、环境配置加载
- 存储门面（Hive、SharedPreferences、SecureStorage）
- 日志、DI 引导、应用初始化

**Core 层不得包含任何功能模块的业务逻辑。**

### Shared 层（`lib/shared/`）

跨功能模块复用的**非业务**构建块：

- 通用组件（列表、按钮、空状态/错误状态）
- 共享 DTO 助手（如 `ApiResponse`、分页类型）
- 跨模块工具类和可选的共享 API

当两个或更多功能模块需要相同的东西时使用 Shared；否则保留在功能模块内部。

### Features 层（`lib/features/<name>/`）

每个功能模块是一个垂直切片：

| 子目录 | 职责 |
|--------|------|
| `data/` | 数据源、Repository 实现、API Model / Request |
| `domain/` | Repository 接口、Entity（需要时） |
| `presentation/` | 页面、组件、Riverpod Provider |

## 功能模块内部结构

典型布局：

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
│   ├── entities/          # 可选
│   └── repositories/
│       └── order_repository.dart
└── presentation/
    ├── pages/
    ├── providers/
    └── widgets/
```

## 依赖方向图

```text
┌─────────────────────────────────────────────────────────┐
│                    表现层 Presentation                     │
│  （页面、组件、@riverpod / Riverpod Notifier）              │
└───────────────────────────┬─────────────────────────────┘
                            │ 依赖
                            ▼
┌─────────────────────────────────────────────────────────┐
│                     领域层 Domain                         │
│  （Repository 接口、可选 Entity）                           │
└───────────────────────────▲─────────────────────────────┘
                            │ 实现
┌───────────────────────────┴─────────────────────────────┐
│                      数据层 Data                          │
│  （数据源、Model、Repository 实现）                         │
└───────────────────────────┬─────────────────────────────┘
                            │ 依赖
                            ▼
┌─────────────────────────────────────────────────────────┐
│              Core + Shared 基础设施                        │
│  ApiClient、存储、Failure、共享组件等                        │
└─────────────────────────────────────────────────────────┘
```

- 表现层可导入 **Domain** 和 **Core/Shared**
- 数据层可导入 **Domain**、**Core** 和 **Shared**
- 领域层尽量保持精简 — 优先依赖 `Failure` 和简单值类型

## 数据流

1. **用户操作** 触发 Riverpod Notifier 的方法或一次性的 `FutureProvider` / `AsyncNotifier`
2. Provider 通过 **`getIt<SomeRepository>()`** 解析依赖（或使用构造函数注入以方便测试）
3. **Repository** 协调**数据源**（远程/本地），将 JSON 映射为 Model，返回 **`Either<Failure, T>`**
4. Provider 将 `Left` 映射为用户可见的错误（Snackbar、内联提示），将 `Right` 映射为状态更新
5. **Widget** 通过 `ref.watch` 监听 Provider，在 `AsyncValue` 或 Notifier 状态变化时重建

可选：`BaseAPI` / `ApiClient` 在数据到达数据源之前应用拦截器（认证头、日志、重试、连接检测）。

## Riverpod 状态管理

- Provider 使用 **`@riverpod`** 或 **`@Riverpod(keepAlive: true)`** 注解，配合 `riverpod_generator`
- **功能状态**（如已认证用户、分页列表）放在功能模块的 `presentation/providers/` 下
- **全局应用状态**（主题模式、语言）可放在 `core/` 下（当不属于单一功能模块时）
- 生成的 `*.g.dart` 文件需要提交或在编辑后通过 `just gen` 重新生成

## Dartz Either 错误处理

- **`Right(value)`** — 成功
- **`Left(failure)`** — 领域层失败，通常是 **`Failure`** sealed 类型（`ServerFailure`、`NetworkFailure` 等）

在 Notifier 中的典型用法：

```dart
final result = await _repository.load();
result.fold(
  (failure) => state = AsyncValue.error(failure, StackTrace.current),
  (data) => state = AsyncValue.data(data),
);
```

数据源可使用 `handleApiCall` 助手方法直接返回 `Either<Failure, T>`，使 Repository 保持轻量。

## GetIt 依赖注入

- **`configureDependencies()`**（`lib/core/di/service_locator.dart`）从生成的 `service_locator.config.dart` 初始化 **`getIt.init()`**
- 类使用 **`@injectable`** / **`@singleton`** / **`@Singleton(as: Interface)`** 注册
- **`RegisterModule`** 提供异步/手动单例（如组合的 `StorageService`）
- 在 Provider 中，统一使用 **`getIt<AuthRepository>()`** 获取服务

添加或修改注册后，运行 **`just gen`** 以保持 Injectable 和 Riverpod 输出同步。
