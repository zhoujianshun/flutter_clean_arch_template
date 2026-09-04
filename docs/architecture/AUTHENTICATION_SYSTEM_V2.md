# 认证系统架构文档 V2

> Your App - 基于 Clean Architecture 的认证系统设计

## 📋 概述

本项目采用基于 **Clean Architecture + DDD + Feature-First** 的认证架构，通过网络错误通知系统实现网络层与应用层的解耦，确保了高内聚、低耦合的设计。

**架构版本**: V2.4（AuthInterceptor 增加 401 自愈恢复：刷新 + 重放；通知语义收敛）  
**架构风格**: Clean Architecture + DDD + Event-Driven

## 🏗️ 架构设计

### 整体架构图

```
┌─────────────────────────────────────────────────────────────┐
│ Presentation Layer │
│ ┌──────────────────────────────────────┐ │
│ │ AuthProvider │ │
│ │ - 管理认证状态 (AuthState) │ │
│ │ - 监听网络认证错误 │ │
│ │ - 登录：参数校验与请求组装（内联） │ │
│ │ - 统一直接调用 AuthRepository │ │
│ └──────────────┬───────────────────────┘ │
│ │ │
│ ▼ │
│ ┌──────────────────────────────────────┐ │
│ │ AuthNavigationListener │ │
│ │ - 监听 AuthState 变化 │ │
│ │ - 处理 UI 副作用（导航、提示） │ │
│ └──────────────────────────────────────┘ │
└───────────────────┬─────────────────────────────────────────┘
 │
 ▼ Provider 统一直接调用 Repository（不使用 UseCase 层）
┌─────────────────────────────────────────────────────────────┐
│ Domain Layer │
│ ┌──────────────────────────────────────┐ │
│ │ AuthRepository (接口) │ │
│ │ - phoneLogin() │ │
│ │ - logout() │ │
│ │ - getCurrentUser() │ │
│ │ - handleTokenExpiry() │ │
│ │ - handleAuthenticationFailure() │ │
│ └──────────────────────────────────────┘ │
└───────────────────┬─────────────────────────────────────────┘
 │
 ▼ 实现接口
┌─────────────────────────────────────────────────────────────┐
│ Data Layer │
│ ┌──────────────────────────────────────┐ │
│ │ AuthRepositoryImpl │ │
│ │ - 实现 AuthRepository 接口 │ │
│ │ - 调用 DataSource 获取数据 │ │
│ │ - 清理本地数据 │ │
│ └──────────────┬───────────────────────┘ │
│ │ │
│ ▼ │
│ ┌──────────────────────────────────────┐ │
│ │ UserRemoteDataSource │ │
│ │ - API 调用 │ │
│ │ - 数据转换 │ │
│ └──────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ Network Layer │
│ ┌──────────────────────────────────────┐ │
│ │ AuthInterceptor │ │
│ │ - 添加认证头 │ │
│ │ - 检测 401 错误 │ │
│ │ - 401 自愈：刷新+重放（双 Token）│ │
│ │ - 恢复失败才通知 │ │
│ └──────────────┬───────────────────────┘ │
│ │ │
│ ▼ 通知错误 │
│ ┌──────────────────────────────────────┐ │
│ │ NetworkErrorNotifier │ │
│ │ - 广播网络错误 │ │
│ │ - 提供过滤流 (authErrorStream) │ │
│ └──────────────┬───────────────────────┘ │
└─────────────────┼─────────────────────────────────────────┘
 │
 └──────────────┐
 │
 ▼ Stream<NetworkAuthError>
 ┌────────────────────────┐
 │ AuthProvider │
 │ (监听并处理) │
 └────────────────────────┘
```

## 📦 核心组件

### 1. AuthState (认证状态)

**位置**: `lib/features/auth/presentation/providers/models/auth_state.dart`

**职责**: 表示应用的认证状态

**设计**:
```dart
@freezed
abstract class AuthState with _$AuthState {
 const factory AuthState({
 UserEntity? user,
 String? accessToken,
 String? errorMessage,
 @Default(false) bool isLoading,

 // 状态变化追踪
 AuthStateChangeReason? changeReason,
 DateTime? changeTime,
 String? changeContext,
 }) = _AuthState;
}
```

**状态变化原因**:
```dart
enum AuthStateChangeReason {
 appInitializedNoToken, // 应用启动 - 无 Token
 appInitializedWithToken, // 应用启动 - 有 Token
 loginSuccess, // 登录成功
 loginFailed, // 登录失败
 logoutCompleted, // 退出登录完成
 tokenExpired, // Token 过期
 authenticationFailed, // 认证失败（401）
 userInfoLoaded, // 用户信息加载成功
 userInfoLoadFailed, // 用户信息加载失败
 dataCleared, // 数据清理
 userInitiated, // 用户主动操作
}
```

### 2. AuthProvider (状态管理)

**位置**: `lib/features/auth/presentation/providers/auth_provider.dart`

**职责**:
- 管理 AuthState
- 监听网络认证错误
- **登录**：在 Provider 内联完成手机号/验证码校验与 `PhoneLoginRequest` 组装，再调用 `AuthRepository.phoneLogin(request)`
- **登出、拉取用户信息、Token 校验、本地恢复**等直接调用 `AuthRepository`
- 网络认证错误场景下调用 `AuthRepository` 清理数据
- 更新状态，触发 UI 更新

**核心方法**:
```dart
@Riverpod(keepAlive: true)
class Auth extends _$Auth {
 late final AuthRepository _authRepository = getIt<AuthRepository>();

 // 监听网络认证错误
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

 // 登录（参数校验与请求组装在 Provider 内联；直接处理 Repository 返回值，不通过事件）
 Future<void> phoneLogin({
 required String phonenumber,
 required String smsCode,
 }) async {
 state = state.copyWith(errorMessage: null, isLoading: true);

 final phone = phonenumber.trim();
 final phoneErrMsg = ValidatorsCheck.checkPhoneNumber(phone);
 if (ValidatorsCheck.hasError(phoneErrMsg)) {
 state = state.copyWith(
 isLoading: false,
 errorMessage: phoneErrMsg,
 changeReason: AuthStateChangeReason.loginFailed,
 changeTime: DateTime.now(),
 changeContext: phoneErrMsg ?? '',
 );
 return;
 }

 final code = smsCode.trim();
 final codeErrMsg = ValidatorsCheck.checkSMSCode(code);
 if (ValidatorsCheck.hasError(codeErrMsg)) {
 state = state.copyWith(
 isLoading: false,
 errorMessage: codeErrMsg,
 changeReason: AuthStateChangeReason.loginFailed,
 changeTime: DateTime.now(),
 changeContext: codeErrMsg ?? '',
 );
 return;
 }

 final request = PhoneLoginRequest(
 clientId: AppConfig.clientId,
 grantType: 'sms',
 phonenumber: phone,
 smsCode: code,
 );

 final result = await _authRepository.phoneLogin(request);

 result.fold(
 (failure) => state = state.copyWith(
 isLoading: false,
 errorMessage: failure.message,
 changeReason: AuthStateChangeReason.loginFailed,
 changeTime: DateTime.now(),
 changeContext: failure.message,
 ),
 (authResponse) {
 state = state.copyWith(
 accessToken: authResponse.accessToken,
 user: null,
 errorMessage: null,
 isLoading: false,
 changeReason: AuthStateChangeReason.loginSuccess,
 changeTime: DateTime.now(),
 );
 // 登录成功后获取用户信息
 _refreshUserInfo();
 },
 );
 }

 // 登出（直接更新状态，不通过事件；直调 Repository）
 Future<void> logout() async {
 await _authRepository.logout();
 state = AuthState(
 changeReason: AuthStateChangeReason.logoutCompleted,
 changeTime: DateTime.now(),
 changeContext: LogoutReason.userInitiated.name,
 );
 }

 // 处理 Token 过期（来自网络层通知）
 Future<void> _handleTokenExpiredAsync(TokenExpiredError error) async {
 await _authRepository.handleTokenExpiry(message: error.message);

 state = AuthState(
 changeReason: AuthStateChangeReason.tokenExpired,
 changeTime: DateTime.now(),
 changeContext: error.message,
 );
 }

 // 处理认证失败（来自网络层通知）
 Future<void> _handleAuthenticationFailedAsync(
 AuthenticationFailedError error,
 ) async {
 await _authRepository.handleAuthenticationFailure(message: error.message);

 state = AuthState(
 changeReason: AuthStateChangeReason.authenticationFailed,
 changeTime: DateTime.now(),
 changeContext: error.message,
 );
 }
}
```

### 3. AuthNavigationListener (UI 副作用)

**位置**: `lib/features/auth/presentation/widgets/auth_navigation_listener.dart`

**职责**:
- 监听 AuthState 变化
- 处理 UI 副作用（导航、提示）
- 防止重复处理

**核心逻辑**:
```dart
class AuthNavigationListener extends ConsumerStatefulWidget {
 void _handleAuthStateChange(AuthState? previous, AuthState next) {
 if (next.changeReason == null) return;

 // 防止重复处理
 if (next.changeTime != null && next.changeTime == _lastProcessedChangeTime) return;
 _lastProcessedChangeTime = next.changeTime;

 // 根据状态变化原因处理副作用
 switch (next.changeReason!) {
 case AuthStateChangeReason.loginSuccess:
 _handleLoginSuccess(); // 当前为空实现，登录跳转由 LoginPage 负责
 case AuthStateChangeReason.logoutCompleted:
 _handleLogoutCompleted(next.logoutReason, next.changeContext);
 case AuthStateChangeReason.tokenExpired:
 _handleTokenExpired(next.changeContext);
 case AuthStateChangeReason.authenticationFailed:
 _handleAuthenticationFailed(next.changeContext);
 // 其他状态不需要特殊处理
 default:
 break;
 }
 }
}
```

> **注意**：`_handleLoginSuccess()` 当前为空实现（跳转代码已注释），登录成功后的页面跳转由 `LoginPage` 中 `ref.listen(authProvider)` 直接处理。

### 4. NetworkErrorNotifier (错误通知)

**位置**: `lib/core/network/errors/network_error_notifier.dart`

**职责**:
- 接收网络层错误通知
- 广播错误给应用层
- 提供过滤流

**核心功能**:
```dart
@singleton
class NetworkErrorNotifier {
 /// 所有网络错误的流
 Stream<NetworkError> get stream;

 /// 认证错误流（过滤后）
 Stream<NetworkAuthError> get authErrorStream;

 /// 通知网络错误
 void notify(NetworkError error);

 /// 通知认证错误（便捷方法）
 void notifyAuthError(NetworkAuthError error);
}
```

### 5. AuthInterceptor (错误检测 + 401 自愈恢复)

**位置**: `lib/core/network/interceptors/auth_interceptor.dart`

**职责**:
- 通过 TokenManager 获取有效 token，添加认证头
- Token 为空时拒绝请求（`handler.reject`），不发出无 auth 请求
- 检测认证错误（HTTP 401、业务层 401）
- **双 Token 模式下的 401 自愈恢复**：检测到 401 → `forceRefresh`（内部 Completer 单飞锁合并并发刷新，冷却期内直接返回 null 防刷新风暴）→ 刷新成功则重放原请求一次（走完整拦截链）
- 通过 NetworkErrorNotifier 发送通知（**仅在恢复失败/不可恢复时**，防抖由 NetworkErrorNotifier 统一处理）

**401 处理三层模型**:

```
1. 预刷（快路径）：TokenManager.getValidToken() 请求前主动续期
   ↓ 漏网场景：服务端提前作废 token（改密码/踢下线）/ 多端互踢 / 时钟偏移
2. 401 兜底恢复（慢路径）：onError/onResponse 双入口检测 401
   → forceRefresh（单飞锁 + 30s 冷却）
   → 成功则 dio.fetch 重放一次（extra['auth_retried'] 标记防死循环）
   ↓ 重放后仍 401
3. 登出（终态）：通知 NetworkErrorNotifier.authenticationFailed
```

**五重防死循环防护**: 公共路径不恢复 / 单 Token 模式不恢复 / `auth_retried` 标记防二次重放 / 刷新端点自身 401 不恢复 / 已取消的请求不重放。

**通知语义收敛（避免双登出）**:
- 刷新致命失败（refresh token 过期/不存在）→ 策略层 `onAuthExpired` 发 `tokenExpired`
- 重放后仍 401（新 token 也被拒）→ 拦截器发 `authenticationFailed`
- 刷新临时失败（网络/5xx）→ 不通知不登出，请求按原错误返回
- 单 Token 模式 401 → 通知登出（无恢复手段）

**依赖获取注意**: `TokenManager`/`NetworkErrorNotifier` 用 `late final` 延迟缓存；**`AuthConfig` 必须用 getter 实时解析**——AuthProvider 启动时会重注册带 `publicPaths` 的实例，缓存会把空配置永久固化导致公共路径被误判为需认证。

**核心逻辑**:
```dart
class AuthInterceptor extends Interceptor {
  late final TokenManager _tokenManager = getIt<TokenManager>();
  late final NetworkErrorNotifier _errorNotifier =
      getIt<NetworkErrorNotifier>();
  // AuthConfig 运行时会被重注册，不可缓存
  AuthConfig get _authConfig => getIt<AuthConfig>();

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // 先尝试刷新 + 重放恢复；失败才走终态登出通知
      if (await _tryRefreshAndReplayOnError(err, handler)) return;
      _notifyTerminalAuthFailure(...);
    }
    handler.next(err);
  }
}
```

## 🔄 认证流程

### 1. 登录流程（不使用事件通知）

```
用户输入
 ↓
AuthProvider.phoneLogin(phonenumber, smsCode)
 ↓
Provider 内联：手机号/验证码校验 + 组装 PhoneLoginRequest
 ↓
AuthRepository.phoneLogin(request)
 ↓
UserRemoteDataSource.phoneLogin(request)
 ↓
API 调用
 ↓
返回 Either<Failure, AuthInfo>
 ↓
AuthProvider 直接处理返回值
 ↓
更新 AuthState (changeReason: loginSuccess)
 ↓
_refreshUserInfo() 获取用户信息
 ↓
LoginPage 中 ref.listen(authProvider) 检测 loginSuccess
 ↓
LoginPage 负责跳转到 AppShellRoute（首页）
```

**关键点**:
- ✅ 不使用事件通知
- ✅ 直接处理 Repository 返回值
- ✅ 状态更新通过 `changeReason` 标识
- ✅ 登录成功后由 LoginPage 负责跳转（非 AuthNavigationListener）
- ✅ 登录成功后自动调用 `_refreshUserInfo()` 获取用户详情

### 2. 登出流程（不使用事件通知）

```
用户点击退出
 ↓
AuthProvider.logout()
 ↓
AuthRepository.logout()
 ↓
清理本地数据
 ↓
返回结果
 ↓
AuthProvider 直接更新状态
 ↓
更新 AuthState (changeReason: logoutCompleted)
 ↓
AuthNavigationListener 监听状态变化
 ↓
导航到登录页 + 显示提示
```

**关键点**:
- ✅ 不使用事件通知
- ✅ **直调** `AuthRepository.logout()`
- ✅ 直接更新状态
- ✅ 通过 `changeContext` 传递登出原因

### 3. Token 过期流程（先自愈恢复，失败才事件通知）

```
网络请求
 ↓
AuthInterceptor 检测到 401（HTTP 状态码或业务层 code）
 ↓
双 Token 模式？
 ├─ 是 → forceRefresh（Completer 单飞锁合并并发刷新，冷却期防风暴）
 │       ├─ 刷新成功 → 走完整拦截链重放原请求一次（auth_retried 防死循环）
 │       │       ├─ 重放成功 → 请求正常返回，用户无感，流程结束
 │       │       └─ 重放仍 401 → NetworkErrorNotifier 广播 authenticationFailed
 │       ├─ 致命失败（refresh token 过期）→ 策略层 onAuthExpired → tokenExpired
 │       └─ 临时失败（网络/5xx）→ 不通知，请求按原错误返回
 └─ 否（单 Token）→ NetworkErrorNotifier 广播 authenticationFailed
 ↓ 广播
networkAuthErrorStreamProvider
 ↓
AuthProvider 监听到错误
 ↓
调用 Repository.handleAuthenticationFailure()
 ↓
清理本地数据
 ↓
更新 AuthState (changeReason: authenticationFailed)
 ↓
AuthNavigationListener 监听状态变化
 ↓
导航到登录页
```

**关键点**:
- ✅ 优先自愈恢复（刷新 + 重放），恢复成功用户无感
- ✅ 事件通知仅在恢复失败/不可恢复时发出
- ✅ AuthProvider 负责调用 Repository
- ✅ 解耦 Interceptor 和 Repository

## 📦 数据流向

### 业务操作流向（登录、登出）

**登录**（含手机号/验证码校验，均在 Provider 内联）:

```
UI → Provider（校验与组装请求）→ AuthRepository → DataSource → API
```

**登出、获取用户信息、Token 校验、本地恢复等**:

```
UI → Provider → AuthRepository → DataSource → API（或本地存储）
```

```
Either 返回值 → Provider 更新 State → UI
```

**特点**:
- 单向数据流
- 通过返回值传递结果；**Presentation 层 Provider 统一直接调用 Repository，不使用 UseCase 层**
- 不使用事件通知

### 网络错误流向（Token过期、401错误）

```
API 返回 401
 ↓
AuthInterceptor 检测
 ↓
双 Token：先尝试刷新 + 重放恢复（成功则流程在此终止，用户无感）
 ↓ 恢复失败 / 单 Token
NetworkErrorNotifier 广播
 ↓
AuthProvider 监听
 ↓
调用 Repository 清理数据
 ↓
更新 State
 ↓
AuthNavigationListener 监听
 ↓
处理 UI 副作用
```

**特点**:
- 事件驱动
- 网络层 → 应用层单向通知
- 解耦彻底
- 恢复优先：可自愈的 401 不上升为登出事件

## 🎯 设计原则

### 1. Clean Architecture

- **Domain 层**：纯业务逻辑，不依赖外部框架
- **Data 层**：实现 Domain 层接口，处理数据访问
- **Presentation 层**：UI 和状态管理
- **依赖方向**：外层依赖内层，内层不依赖外层

### 2. 单一职责原则 (SRP)

- **AuthInterceptor**：只负责检测错误和通知
- **NetworkErrorNotifier**：只负责广播错误
- **AuthProvider**：只负责状态管理和业务协调
- **AuthNavigationListener**：只负责 UI 副作用

### 3. 依赖倒置原则 (DIP)

- Domain 层定义接口（AuthRepository）
- Data 层实现接口（AuthRepositoryImpl）
- Presentation 层依赖 `AuthRepository` 接口，不依赖 Data 实现类；**不使用 UseCase 层**

### 4. 开闭原则 (OCP)

- 添加新错误类型无需修改 NetworkErrorNotifier
- 添加新状态变化原因无需修改核心逻辑
- 扩展开放，修改关闭

## 🔧 关键技术

### 1. Riverpod 状态管理

```dart
@Riverpod(keepAlive: true)
class Auth extends _$Auth {
 @override
 AuthState build() {
 _listenToAuthErrors();
 _initializeAuth();
 return const AuthState(isLoading: true);
 }
}
```

**特点**:
- 类型安全
- 自动依赖管理
- 支持异步状态

### 2. Freezed 不可变数据

```dart
@freezed
abstract class AuthState with _$AuthState {
 const factory AuthState({
 UserEntity? user,
 String? accessToken,
 AuthStateChangeReason? changeReason,
 DateTime? changeTime,
 String? changeContext,
 }) = _AuthState;
}
```

**特点**:
- 不可变性
- copyWith 方法
- JSON 序列化

### 3. Dartz 函数式编程

```dart
Future<Either<Failure, AuthInfo>> phoneLogin(PhoneLoginRequest request);
```

**特点**:
- 显式错误处理
- 类型安全
- 函数式风格

### 4. Stream 事件驱动

```dart
Stream<NetworkAuthError> get authErrorStream =>
 _controller.stream
 .where((error) => error is NetworkAuthError)
 .cast<NetworkAuthError>();
```

**特点**:
- 响应式编程
- 解耦组件
- 支持多订阅者

## 🛡️ 安全特性

### 1. 防重复通知

**防抖统一在 `NetworkErrorNotifier.notifyAuthError()` 中处理（500ms，同类错误才去重）**，调用方无需额外防抖。

同时，两条认证通知路径互斥且有明确分工：
- `DualTokenStrategy.onAuthExpired`：刷新致命失败（refresh token 过期/缺失）→ `tokenExpired`
- `AuthInterceptor`：重放后仍 401（新 token 也被服务端拒绝）或单 Token 模式 401 → `authenticationFailed`

刷新临时失败（网络/5xx）不通知不登出。Token 为空时 AuthInterceptor 拒绝请求，不发出无 auth 请求。恢复成功时（刷新 + 重放成功）整个链路不发任何通知。

### 2. 防重复处理

**AuthNavigationListener 防重复**:
```dart
DateTime? _lastProcessedChangeTime;

void _handleAuthStateChange(AuthState next) {
 if (next.changeTime == _lastProcessedChangeTime) return;
 _lastProcessedChangeTime = next.changeTime;
 // 处理状态变化
}
```

### 3. 自动数据清理

- Token 过期时自动清理本地数据
- 认证失败时自动清理本地数据
- 登出时完整清理用户数据

### 4. Token 管理

- 使用 TokenManager 统一管理（纯编排器，不依赖 NetworkErrorNotifier）
- Token 持久化通过 `TokenStorage` 接口（`TokenStorageImpl` 使用 SecureStorage + 内存缓存）
- 当前使用 SingleTokenStrategy（单 Token 模式），Token 过期依赖服务器 401 检测
- 支持切换到 DualTokenStrategy（双 Token 自动刷新），通过 `onAuthExpired` 回调通知致命刷新失败
- DualTokenStrategy 支持可配置字段名（`accessTokenField`/`refreshTokenField`）
- `forceRefresh()` 带冷却保护：冷却期内直接返回 null，供 AuthInterceptor 的 401 兜底路径防刷新风暴（单飞锁只防"同时"的并发，冷却防"连续"的到来）
- `TokenStorageImpl.clearAll()` 并行清除两个 token（任一清除失败不影响另一个执行）

## 📊 架构对比

### V1 架构（旧版，已废弃 - UserService 已从项目中移除）

```
AuthInterceptor → UserService (发送事件) [已废弃]
 ↓
 AuthProvider (监听事件)
```

**问题**:
- ❌ UserService 职责过重（数据 + 业务 + 事件）
- ❌ 不符合 Clean Architecture
- ❌ 难以测试和维护

### V2 架构（当前，基于 Clean Architecture）

```
AuthInterceptor → NetworkErrorNotifier → AuthProvider → Repository
```

**优势**:
- ✅ 职责单一，符合 SRP
- ✅ 符合 Clean Architecture
- ✅ 易于测试和维护
- ✅ 解耦彻底

## 🚀 扩展性

### 当前支持

- ✅ 认证错误（401错误）

> **注意**：`TokenExpiredError` 仅在双 Token 模式（DualTokenStrategy）下由策略层 `onAuthExpired` 回调触发（refresh token 过期/缺失的致命刷新失败）；当前项目使用 SingleTokenStrategy，故实际运行中不会触发。`AuthInterceptor` 对重放后仍 401、单 Token 模式 401 发出 `AuthenticationFailedError`；刷新临时失败（网络/5xx）不发通知。

### 未来可扩展

#### 1. 网络连接错误

```dart
sealed class NetworkConnectionError extends NetworkError {
 const factory NetworkConnectionError.timeout(String message);
 const factory NetworkConnectionError.connectionFailed(String message);
 const factory NetworkConnectionError.noInternet(String message);
}

// 创建 Provider
@Riverpod(keepAlive: true)
Stream<NetworkConnectionError> networkConnectionErrorStream(Ref ref) {
 return getIt<NetworkErrorNotifier>().connectionErrorStream;
}

// 创建监听器
@riverpod
class NetworkStatus extends _$NetworkStatus {
 void _listenToConnectionErrors() {
 ref.listen(networkConnectionErrorStreamProvider, ...);
 }
}
```

#### 2. 服务器错误

```dart
sealed class NetworkServerError extends NetworkError {
 const factory NetworkServerError.internalError(String message);
 const factory NetworkServerError.serviceUnavailable(String message);
}
```

#### 3. 限流错误

```dart
sealed class NetworkRateLimitError extends NetworkError {
 const factory NetworkRateLimitError.tooManyRequests(
 String message,
 Duration retryAfter,
 );
}
```

## 🧪 测试策略

### 1. 单元测试

#### 测试 NetworkErrorNotifier

```dart
test('should emit auth errors through authErrorStream', () async {
 final notifier = NetworkErrorNotifier();

 expectLater(
 notifier.authErrorStream,
 emits(isA<TokenExpiredError>()),
 );

 notifier.notifyAuthError(
 NetworkAuthError.tokenExpired('Token过期'),
 );
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

 await Future.delayed(Duration(milliseconds: 100));

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

## 📚 相关文档

- [网络错误通知系统](./NETWORK_ERROR_NOTIFICATION_SYSTEM.md)
- [Network 层文档](../../lib/core/network/README.md)
- [网络错误通知系统使用指南](../../lib/core/network/errors/README.md)
- [Riverpod 完整指南](../state-management/RIVERPOD_COMPLETE_GUIDE.md)
- [Clean Architecture 指南](./CLEAN_ARCHITECTURE_GUIDE.md)

## 🔄 更新日志

- **v2.3.0**
 - 移除 UseCase 层描述：登录校验与 `PhoneLoginRequest` 组装均在 `AuthProvider` 内联完成
 - 明确 **Presentation 层 Provider 统一直接调用 Repository，不使用 UseCase 层**
 - 更新架构图、示例代码、登录/数据流与 DIP 说明

- **v2.2.0**
 - 文档曾描述部分路径经 UseCase；已由 v2.3.0 与代码对齐为 **Provider → Repository** 全路径

- **v2.1.0**
 - 修正 phoneLogin 方法签名，与实际代码保持一致
 - 明确登录成功跳转由 LoginPage 负责（非 AuthNavigationListener）
 - 修正 Token 管理描述：当前使用 SingleTokenStrategy
 - 补充 TokenExpiredError 当前未被触发的说明
 - 补充 _handleAuthenticationFailedAsync 方法示例

- **v2.0.0**
 - 完全重构认证系统
 - 引入 NetworkErrorNotifier
 - 移除 AuthEventBus
 - 业务操作通过返回值，网络错误通过事件
 - 完善的文档和测试

- **v1.0.0** [已废弃]
 - 基于 UserService 的设计（UserService 已从项目中移除）
 - 使用 AuthEventBus
 - 所有操作都通过事件通知

## 维护者

Your App Team

**架构设计**: 技术架构组
**代码实现**: 认证模块开发组
**文档维护**: 技术文档组

如有问题或建议，请联系技术负责人。
