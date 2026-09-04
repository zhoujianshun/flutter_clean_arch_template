# 网络错误通知系统架构文档

> Your App - 网络层错误通知机制设计与实现

## 📋 文档概述

本文档记录了网络错误通知系统的架构设计、实现细节和演进历程。该系统提供了一个通用的、可扩展的机制，用于将网络层检测到的错误通知给应用层处理。

**版本**: v1.1.0

## 🎯 设计目标

### 核心目标

1. **解耦网络层与应用层**：避免 Interceptor 直接依赖 Repository 或 Provider
2. **统一错误通知机制**：提供标准化的错误通知方式
3. **支持多种错误类型**：不仅限于认证错误，支持扩展
4. **类型安全**：使用 sealed class 确保编译时类型检查
5. **易于扩展**：添加新错误类型无需修改核心代码

### 非功能性目标

- **性能**：使用广播流，支持多个订阅者，无性能损耗
- **可测试性**：组件职责单一，易于单元测试
- **可维护性**：代码结构清晰，文档完善
- **向后兼容**：现有功能不受影响

## 🏗️ 架构设计

### 整体架构

```
┌─────────────────────────────────────────────────────────────┐
│ Network Layer │
│ │
│ ┌──────────────┐ ┌──────────────┐ │
│ │AuthInterceptor│ │Other │ │
│ │ │ │Interceptors │ │
│ │- 检测 401 │ │- 检测其他错误 │ │
│ │- 自愈:刷新+重放│ │ │ │
│ │- 失败才通知 │ │ │ │
│ └──────┬───────┘ └──────┬───────┘ │
│ │ │ │
│ └────────┬───────────────┘ │
│ ▼ │
│ ┌─────────────────────────┐ │
│ │ NetworkErrorNotifier │ │
│ │ - notify() │ │
│ │ - notifyAuthError() │ │
│ │ - stream │ │
│ │ - authErrorStream │ │
│ └────────────┬────────────┘ │
└───────────────────┼─────────────────────────────────────┘
 │
 ▼ Stream<NetworkError>
┌─────────────────────────────────────────────────────────────┐
│ Presentation Layer │
│ │
│ ┌──────────────────────────────────────┐ │
│ │ networkAuthErrorStreamProvider │ │
│ │ - 过滤 authErrorStream │ │
│ └──────────────┬───────────────────────┘ │
│ │ │
│ ▼ │
│ ┌──────────────┐ ┌──────────────┐ │
│ │ AuthProvider │ │ Other │ │
│ │ │ │ Providers │ │
│ │- 监听错误 │ │- 监听错误 │ │
│ │- 调用 Repo │ │- 处理逻辑 │ │
│ │- 更新状态 │ │ │ │
│ └──────────────┘ └──────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### 核心组件

#### 1. NetworkError (错误类型)

**位置**: `lib/core/network/errors/network_error.dart`

**设计**:

```dart
// 基类
sealed class NetworkError {
 const NetworkError();
}

// 认证错误（当前已实现）
sealed class NetworkAuthError extends NetworkError {
 const NetworkAuthError();
 const factory NetworkAuthError.tokenExpired(String message) = TokenExpiredError;
 const factory NetworkAuthError.authenticationFailed(String message) = AuthenticationFailedError;
}

// 未来可扩展的错误类型
// - NetworkConnectionError（网络连接错误）
// - NetworkServerError（服务器错误）
// - NetworkRateLimitError（限流错误）
```

**设计要点**:

- 使用 `sealed class` 确保类型安全
- 层次化设计，支持错误分类
- 每个错误携带必要的上下文信息

#### 2. NetworkErrorNotifier (错误通知器)

**位置**: `lib/core/network/errors/network_error_notifier.dart`

**设计**:

```dart
@singleton
class NetworkErrorNotifier {
 // 广播流控制器
 final StreamController<NetworkError> _controller =
 StreamController<NetworkError>.broadcast();

 /// 所有网络错误的流
 Stream<NetworkError> get stream => _controller.stream;

 /// 认证错误流（过滤后）
 Stream<NetworkAuthError> get authErrorStream =>
 _controller.stream
 .where((error) => error is NetworkAuthError)
 .cast<NetworkAuthError>();

 /// 通知网络错误（通用方法）
 void notify(NetworkError error) { ... }

 /// 通知认证错误（便捷方法）
 void notifyAuthError(NetworkAuthError error) { ... }

 /// 清理资源
 void dispose() { ... }
}
```

**设计要点**:

- 单例模式，全局唯一实例
- 广播流，支持多个订阅者
- 提供过滤流，各 Provider 只接收关心的错误
- 提供便捷方法，增强类型安全

#### 3. AuthInterceptor (错误检测 + 401 自愈恢复)

**位置**: `lib/core/network/interceptors/auth_interceptor.dart`

**职责**:

- Token 为空时拒绝请求（`handler.reject`），不发出无 auth 请求
- 检测 HTTP 401 状态码（服务器拒绝带 token 的请求）
- 检测业务层 code=401
- **401 自愈恢复**（双 Token 模式）：`forceRefresh`（单飞锁合并并发刷新 + 30s 冷却）→ 成功则走完整拦截链重放一次（`extra['auth_retried']` 标记防死循环）
- **仅恢复失败/不可恢复时**通过 NetworkErrorNotifier 发送错误通知（防抖由 NetworkErrorNotifier 统一处理）
- 通知语义：致命刷新失败由策略层 `onAuthExpired` 发 `tokenExpired`；重放后仍 401 / 单 Token 401 由拦截器发 `authenticationFailed`；刷新临时失败（网络/5xx）不通知

**关键代码**:

```dart
class AuthInterceptor extends Interceptor {
  late final TokenManager _tokenManager = getIt<TokenManager>();
  late final NetworkErrorNotifier _errorNotifier =
      getIt<NetworkErrorNotifier>();
  // AuthConfig 运行时会被 AuthProvider 重注册，必须实时解析不可缓存
  AuthConfig get _authConfig => getIt<AuthConfig>();

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // 先自愈：刷新 + 重放（仅双 Token 模式）
      if (await _tryRefreshAndReplayOnError(err, handler)) return;
      // 恢复失败才通知终态登出
      _notifyTerminalAuthFailure(err.requestOptions, err.message ?? 'HTTP auth failed');
    }
    handler.next(err);
  }
}
```

#### 4. AuthProvider (错误处理)

**位置**: `lib/features/auth/presentation/providers/auth_provider.dart`

**职责**:

- 监听网络认证错误流
- 调用 Repository 清理数据
- 更新 AuthState
- 触发 UI 更新

**关键代码**:

```dart
@Riverpod(keepAlive: true)
Stream<NetworkAuthError> networkAuthErrorStream(Ref ref) {
 final errorNotifier = getIt<NetworkErrorNotifier>();
 return errorNotifier.authErrorStream; // 只接收认证错误
}

@Riverpod(keepAlive: true)
class Auth extends _$Auth {
 void _listenToAuthEvents() {
 ref.listen(networkAuthErrorStreamProvider, (previous, next) {
 next.when(
 data: (error) {
 switch (error) {
 case TokenExpiredError():
 _handleTokenExpiredAsync(error);
 case AuthenticationFailedError():
 _handleAuthenticationFailedAsync(error);
 }
 },
 loading: () {},
 error: (error, stack) {
 AppLogger.e('AuthProvider: 监听网络认证错误时发生异常', error: error);
 },
 );
 });
 }
}
```

## 🔄 演进历程

### 阶段 1: AuthEventBus (已废弃)

**时间**: - **位置**: `lib/features/auth/infrastructure/events/auth_event/`

**设计**:

```dart
sealed class AuthEvent {
 const factory AuthEvent.loginSuccess(...) = LoginSuccessEvent;
 const factory AuthEvent.loginFailed(...) = LoginFailedEvent;
 const factory AuthEvent.logoutCompleted(...) = LogoutCompletedEvent;
 const factory AuthEvent.tokenExpired(...) = TokenExpiredEvent;
 const factory AuthEvent.authenticationFailed(...) = AuthenticationFailedEvent;
}

@singleton
class AuthEventBus {
 Stream<AuthEvent> get stream;
 void publishNetworkAuthError(AuthEvent event);
}
```

**问题**:

- ❌ 命名误导：暗示是通用的认证事件系统
- ❌ 位置不当：在 `features/auth/infrastructure/`，但主要服务于 `shared/network/`
- ❌ 职责混乱：既用于网络错误，又用于业务事件
- ❌ 扩展性差：添加新错误类型需要修改核心代码

### 阶段 2: NetworkAuthErrorNotifier (过渡)

**时间**: - **位置**: `lib/core/network/auth/`

**改进**:

- ✅ 移到 `shared/network/` 层
- ✅ 重命名为 `NetworkAuthErrorNotifier`
- ✅ 只保留网络认证错误

**仍存在的问题**:

- ⚠️ 命名仍然局限于认证错误
- ⚠️ 不支持其他类型的网络错误

### 阶段 3: NetworkErrorNotifier (当前)

**时间**: - **位置**: `lib/core/network/errors/`

**最终设计**:

- ✅ 通用命名：`NetworkErrorNotifier`
- ✅ 合理位置：`lib/core/network/errors/`
- ✅ 层次化错误类型：`NetworkError` → `NetworkAuthError` / `NetworkConnectionError` / ...
- ✅ 完全可扩展：添加新错误类型无需修改通知器
- ✅ 类型安全：使用 sealed class 和过滤流

**重构内容**:

1. 创建 `NetworkError` 基类
2. `NetworkAuthError` 继承自 `NetworkError`
3. 重命名 `NetworkAuthErrorNotifier` → `NetworkErrorNotifier`
4. 移动到 `lib/core/network/errors/`
5. 提供过滤流（`authErrorStream`）
6. 更新所有引用

## 📊 架构对比

### 改进前（直接依赖）

```
AuthInterceptor (检测 401)
 ↓ 直接调用
AuthRepository (清理数据)
 ↓
AuthProvider (可能不知道状态变化)
```

**问题**:

- ❌ 循环依赖风险：Interceptor → Repository → API → Interceptor
- ❌ 职责混乱：Interceptor 处理业务逻辑
- ❌ 难以扩展：添加新错误类型需要修改多处
- ❌ 测试困难：组件耦合度高

### 改进后（事件驱动 + 401 先自愈）

```
AuthInterceptor (检测 401)
 ↓ 双 Token 模式：先自愈（刷新 + 重放一次，成功则流程终止，用户无感）
 ↓ 恢复失败 / 单 Token
NetworkErrorNotifier (广播)
 ↓ 过滤流
AuthProvider (监听)
 ↓ 调用 Repository
 ↓ 更新状态
AuthNavigationListener (监听状态)
 ↓ 处理 UI 副作用
```

**优势**:

- ✅ 解耦彻底：各组件职责单一
- ✅ 职责清晰：网络层检测，应用层处理
- ✅ 易于扩展：添加新错误类型只需修改错误定义
- ✅ 易于测试：可以独立测试各组件

## 🎯 设计模式

### 1. 观察者模式 (Observer Pattern)

**应用**:

- `NetworkErrorNotifier` 是被观察者（Subject）
- `AuthProvider` 等是观察者（Observer）
- 通过 Stream 实现发布-订阅

**优势**:

- 一对多依赖关系
- 松耦合
- 动态订阅

### 2. 单例模式 (Singleton Pattern)

**应用**:

- `NetworkErrorNotifier` 使用 `@singleton` 注解
- 全局唯一实例
- 通过依赖注入管理

**优势**:

- 全局访问点
- 资源共享
- 避免重复创建

### 3. 策略模式 (Strategy Pattern)

**应用**:

- 不同类型的错误（认证、连接、服务器等）
- 统一的通知接口
- 可扩展的错误处理策略

**优势**:

- 算法族封装
- 易于切换
- 易于扩展

## 🚀 扩展指南

### 添加新错误类型的步骤

#### 1. 定义错误类型

```dart
// 在 network_error.dart 中添加
sealed class NetworkConnectionError extends NetworkError {
 const NetworkConnectionError();

 const factory NetworkConnectionError.timeout(String message) = NetworkTimeoutError;
 const factory NetworkConnectionError.connectionFailed(String message) = ConnectionFailedError;
}
```

#### 2. 添加过滤流（可选）

```dart
// 在 NetworkErrorNotifier 中添加
Stream<NetworkConnectionError> get connectionErrorStream =>
 _controller.stream
 .where((error) => error is NetworkConnectionError)
 .cast<NetworkConnectionError>();
```

#### 3. 创建 Provider

```dart
@Riverpod(keepAlive: true)
Stream<NetworkConnectionError> networkConnectionErrorStream(Ref ref) {
 final errorNotifier = getIt<NetworkErrorNotifier>();
 return errorNotifier.connectionErrorStream;
}
```

#### 4. 在 Interceptor 中发送

```dart
class ConnectionInterceptor extends Interceptor {
 @override
 void onError(DioException err, ErrorInterceptorHandler handler) {
 if (err.type == DioExceptionType.connectionTimeout) {
 getIt<NetworkErrorNotifier>().notify(
 NetworkConnectionError.timeout('连接超时'),
 );
 }
 handler.next(err);
 }
}
```

#### 5. 在 Provider 中监听

```dart
@riverpod
class NetworkStatus extends _$NetworkStatus {
 void _listenToConnectionErrors() {
 ref.listen(networkConnectionErrorStreamProvider, (previous, next) {
 next.when(
 data: (error) => _handleConnectionError(error),
 loading: () {},
 error: (error, stack) {},
 );
 });
 }
}
```

## 📈 性能考虑

### 1. 广播流性能

- 使用 `StreamController.broadcast()`
- 支持多个订阅者，无性能损耗
- 订阅者数量不影响发送性能

### 2. 防抖机制

- 防抖统一在 `NetworkErrorNotifier.notifyAuthError()` 中实现（500ms，同类错误才去重）
- 调用方（AuthInterceptor、DualTokenStrategy.onAuthExpired）无需额外防抖
- 两条通知路径分工明确：`onAuthExpired`（刷新致命失败 → `tokenExpired`）与 AuthInterceptor（重放后仍 401 / 单 Token 401 → `authenticationFailed`）；刷新临时失败与恢复成功均不发通知

### 3. 过滤流优化

- 使用 `where` 和 `cast` 过滤
- 各 Provider 只接收关心的错误
- 避免不必要的处理

### 4. 内存管理

- 提供 `dispose` 方法清理资源
- 应用退出时调用
- 避免内存泄漏

## 🧪 测试策略

### 1. 单元测试

#### 测试 NetworkErrorNotifier

```dart
test('notify should add error to stream', () async {
 final notifier = NetworkErrorNotifier();
 final error = NetworkAuthError.tokenExpired('Token过期');

 expectLater(
 notifier.stream,
 emits(isA<TokenExpiredError>()),
 );

 notifier.notify(error);
});

test('authErrorStream should only emit auth errors', () async {
 final notifier = NetworkErrorNotifier();

 expectLater(
 notifier.authErrorStream,
 emitsInOrder([
 isA<TokenExpiredError>(),
 isA<AuthenticationFailedError>(),
 ]),
 );

 notifier.notify(NetworkAuthError.tokenExpired('Token过期'));
 notifier.notify(NetworkAuthError.authenticationFailed('认证失败'));
});
```

#### 测试 AuthProvider

```dart
test('should handle token expired error', () async {
 final container = ProviderContainer(
 overrides: [
 networkAuthErrorStreamProvider.overrideWith((ref) {
 return Stream.value(NetworkAuthError.tokenExpired('Token过期'));
 }),
 ],
 );

 final provider = container.read(authProvider.notifier);

 // 等待处理
 await Future.delayed(Duration(milliseconds: 100));

 // 验证状态
 final state = container.read(authProvider);
 expect(state.changeReason, AuthStateChangeReason.tokenExpired);
});
```

### 2. 集成测试

```dart
testWidgets('should navigate to login on auth failure', (tester) async {
 await tester.pumpWidget(MyApp());

 // 模拟认证失败
 getIt<NetworkErrorNotifier>().notifyAuthError(
 NetworkAuthError.authenticationFailed('认证失败'),
 );

 await tester.pumpAndSettle();

 // 验证导航到登录页
 expect(find.byType(LoginPage), findsOneWidget);
});
```

## 📚 最佳实践

### 1. 错误类型设计

- ✅ 使用 `sealed class` 确保类型安全
- ✅ 层次化设计，便于分类和过滤
- ✅ 每个错误携带必要的上下文信息
- ❌ 避免过度细分错误类型

### 2. 错误通知

- ✅ 在 Interceptor 中检测错误并通知
- ✅ 使用类型安全的便捷方法
- ✅ 防抖由 `NetworkErrorNotifier.notifyAuthError()` 统一处理，调用方无需额外防抖
- ❌ 不要在通知器中处理业务逻辑

### 3. 错误监听

- ✅ 使用过滤流，只接收关心的错误
- ✅ 在 Provider 中处理错误，更新状态
- ✅ 使用 `switch` 表达式处理所有错误类型
- ❌ 不要在多个地方监听同一错误

### 4. 错误处理

- ✅ 在 Provider 中调用 Repository 处理数据
- ✅ 更新状态，触发 UI 更新
- ✅ 记录日志，便于调试
- ❌ 不要在 Interceptor 中直接处理业务逻辑

## 🔍 常见问题

### Q1: 为什么不直接在 Interceptor 中调用 Repository？

**A**: 为了避免循环依赖和职责混乱。Interceptor 属于网络层，不应该直接处理业务逻辑。通过事件通知机制，实现了网络层与应用层的解耦。

### Q2: 为什么要提供过滤流？

**A**: 不同的 Provider 关心不同类型的错误。过滤流可以避免 Provider 接收和处理不相关的错误，提高性能和代码清晰度。

### Q3: 如何避免重复通知？

**A**: 通过三层机制避免：1）架构层面，`DualTokenStrategy.onAuthExpired`（刷新致命失败）和 AuthInterceptor（重放后仍 401 / 单 Token 401）路径分工明确、不会对同一请求重复触发，刷新临时失败与恢复成功均不发通知；2）`NetworkErrorNotifier.notifyAuthError()` 内置 500ms 防抖（同类错误才去重），短时间内重复的认证错误会被过滤；3）`NetworkAuthError` 基类统一持有 `message` 字段，防抖比较基于 `runtimeType` 不受消息内容影响。

### Q4: 为什么使用 sealed class？

**A**: sealed class 提供了编译时的完整性检查。在 switch 表达式中，编译器会确保处理了所有可能的错误类型，避免遗漏。

### Q5: 如何测试错误通知？

**A**: 可以 Mock `NetworkErrorNotifier`，使用 `StreamController` 模拟错误流，验证 Provider 的行为。

## 📖 相关文档

- [网络错误通知系统使用指南](../../lib/core/network/errors/README.md)
- [Network 层文档](../../lib/core/network/README.md)
- [认证系统架构 V2](./AUTHENTICATION_SYSTEM_V2.md)
- [Riverpod 完整指南](../state-management/RIVERPOD_COMPLETE_GUIDE.md)

## 🔄 更新日志

- **v1.1.0**
 - 修正 AuthProvider 中的方法名（`_listenToAuthEvents`、`_handleTokenExpiredAsync`、`_handleAuthenticationFailedAsync`）
 - 修正相关文档链接（AUTHENTICATION_ARCHITECTURE → AUTHENTICATION_SYSTEM_V2）

- **v1.0.0**
 - 初始版本
 - 完整的架构设计文档
 - 演进历程记录
 - 扩展指南和最佳实践

## 维护者

Your App Team

**文档维护**: 技术架构组
**代码维护**: 网络层开发组

如有问题或建议，请联系技术负责人。
