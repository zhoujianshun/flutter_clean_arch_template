# 网络错误通知系统 - 快速参考

> 5分钟快速上手网络错误通知系统

## 🚀 快速开始

### 1. 在 Interceptor 中发送错误通知

```dart
import 'package:flutter_clean_arch_template/core/network/errors/network_error.dart';
import 'package:flutter_clean_arch_template/core/network/errors/network_error_notifier.dart';

class AuthInterceptor extends Interceptor {
 NetworkErrorNotifier get _errorNotifier => getIt<NetworkErrorNotifier>();

 @override
 void onError(DioException err, ErrorInterceptorHandler handler) {
 if (err.response?.statusCode == 401) {
 // 通知认证失败错误
 _errorNotifier.notifyAuthError(
 NetworkAuthError.authenticationFailed('认证失败'),
 );
 }
 handler.next(err);
 }
}
```

### 2. 创建 Provider 监听错误

```dart
import 'package:flutter_clean_arch_template/core/network/errors/network_error.dart';
import 'package:flutter_clean_arch_template/core/network/errors/network_error_notifier.dart';

/// 网络认证错误流 Provider
@Riverpod(keepAlive: true)
Stream<NetworkAuthError> networkAuthErrorStream(Ref ref) {
 final errorNotifier = getIt<NetworkErrorNotifier>();
 return errorNotifier.authErrorStream; // 过滤后的流
}
```

### 3. 在 Provider 中处理错误

```dart
@Riverpod(keepAlive: true)
class Auth extends _$Auth {
 @override
 AuthState build() {
 _listenToAuthEvents();
 _initializeAuth();
 return const AuthState(isLoading: true);
 }

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

 Future<void> _handleTokenExpiredAsync(TokenExpiredError error) async {
 // 1. 清理数据
 await getIt<AuthRepository>().handleTokenExpiry(message: error.message);

 // 2. 更新状态
 state = AuthState(
 changeReason: AuthStateChangeReason.tokenExpired,
 changeTime: DateTime.now(),
 changeContext: error.message,
 );
 }
}
```

## 📦 核心 API

### NetworkErrorNotifier

```dart
@singleton
class NetworkErrorNotifier {
 /// 所有网络错误的流
 Stream<NetworkError> get stream;

 /// 认证错误流（过滤后）
 Stream<NetworkAuthError> get authErrorStream;

 /// 通知网络错误（通用）
 void notify(NetworkError error);

 /// 通知认证错误（便捷）
 void notifyAuthError(NetworkAuthError error);
}
```

### NetworkAuthError

```dart
sealed class NetworkAuthError extends NetworkError {
 /// Token 过期
 const factory NetworkAuthError.tokenExpired(String message) = TokenExpiredError;

 /// 认证失败（401）
 const factory NetworkAuthError.authenticationFailed(String message) = AuthenticationFailedError;
}
```

## 🎯 使用场景

### 场景 1: 检测到 HTTP 401

```dart
@override
void onError(DioException err, ErrorInterceptorHandler handler) {
 if (err.response?.statusCode == 401) {
 _errorNotifier.notifyAuthError(
 NetworkAuthError.authenticationFailed('HTTP 401'),
 );
 }
 handler.next(err);
}
```

### 场景 2: 检测到业务层 401

```dart
@override
void onResponse(Response response, ResponseInterceptorHandler handler) {
 if (response.data is Map && response.data['code'] == 401) {
 _errorNotifier.notifyAuthError(
 NetworkAuthError.authenticationFailed(response.data['msg']),
 );
 }
 handler.next(response);
}
```

### 场景 3: Token 过期

```dart
if (isTokenExpired()) {
 _errorNotifier.notifyAuthError(
 NetworkAuthError.tokenExpired('Token 已过期'),
 );
}
```

## ⚠️ 注意事项

### ✅ 应该做的

- ✅ 在 Interceptor 中检测错误并通知
- ✅ 使用 `notifyAuthError` 等便捷方法
- ✅ 在 Provider 中监听错误并处理
- ✅ 防抖由 `NetworkErrorNotifier.notifyAuthError()` 统一处理，调用方无需自行防抖

### ❌ 不应该做的

- ❌ 不要在 Interceptor 中直接调用 Repository
- ❌ 不要在 Interceptor 中处理业务逻辑
- ❌ 不要用于通知业务事件（如登录成功）
- ❌ 不要在多个地方监听同一错误

## 🔍 常见错误

### 错误 1: 在 Interceptor 中调用 Repository

```dart
// ❌ 错误
class AuthInterceptor extends Interceptor {
 void onError(DioException err, ErrorInterceptorHandler handler) {
 if (err.response?.statusCode == 401) {
 final repo = getIt<AuthRepository>();
 await repo.handleAuthenticationFailure(); // 循环依赖风险
 }
 }
}

// ✅ 正确
class AuthInterceptor extends Interceptor {
 void onError(DioException err, ErrorInterceptorHandler handler) {
 if (err.response?.statusCode == 401) {
 _errorNotifier.notifyAuthError(
 NetworkAuthError.authenticationFailed('认证失败'),
 );
 }
 }
}
```

### 错误 2: 用于业务事件

```dart
// ❌ 错误：登录成功不应该通过 NetworkErrorNotifier
_errorNotifier.notify(LoginSuccessEvent(...));

// ✅ 正确：登录在 Auth Provider 内联校验与组装请求，通过 Repository 的 Either 处理结果
final request = PhoneLoginRequest(
 clientId: AppConfig.clientId,
 grantType: 'sms',
 phonenumber: phone,
 smsCode: code,
);
final result = await _authRepository.phoneLogin(request);
result.fold(
 (failure) => handleFailure(failure),
 (success) => handleSuccess(success),
);
```

### 错误 3: 多个地方监听

```dart
// ❌ 错误：多个 Provider 监听可能导致状态不一致
// AuthProvider
ref.listen(networkAuthErrorStreamProvider, ...);

// SomeOtherProvider
ref.listen(networkAuthErrorStreamProvider, ...);

// ✅ 正确：只有 AuthProvider 监听，其他组件监听 AuthState
// AuthProvider
ref.listen(networkAuthErrorStreamProvider, ...);

// AuthNavigationListener
ref.listen(authProvider, ...); // 监听状态，不监听错误
```

## 📚 相关文档

- [完整架构文档](./NETWORK_ERROR_NOTIFICATION_SYSTEM.md)
- [认证系统架构 V2](./AUTHENTICATION_SYSTEM_V2.md)
- [重构总结](./AUTHENTICATION_REFACTORING.md)
- [使用指南](../../lib/core/network/errors/README.md)

## 🎓 学习资源

### 推荐阅读顺序

1. **快速参考**（本文档）- 5分钟快速上手
2. [使用指南](../../lib/core/network/errors/README.md) - 15分钟详细学习
3. [架构设计](./NETWORK_ERROR_NOTIFICATION_SYSTEM.md) - 30分钟深入理解
4. [重构总结](./AUTHENTICATION_REFACTORING.md) - 了解演进历程

### 代码示例

完整的代码示例请参考：
- `lib/core/network/interceptors/auth_interceptor.dart`
- `lib/features/auth/presentation/providers/auth_provider.dart`
- `lib/features/auth/presentation/widgets/auth_navigation_listener.dart`

---

**最后更新**: (latest) **文档版本**: v1.1.1
