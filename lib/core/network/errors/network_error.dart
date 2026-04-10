/// 网络层错误基类
///
/// **用途**：网络层（Interceptor）检测到错误后，通知应用层处理
///
/// **架构位置**：Shared/Network 层
/// **通信方向**：Network Layer (Interceptor) → Presentation Layer (Provider)
///
/// **设计原则**：
/// 1. 只用于网络层检测到的错误
/// 2. 不用于业务逻辑事件（如登录成功、登出完成）
/// 3. 支持扩展，可添加更多错误类型
///
/// **当前支持的错误类型**：
/// - 认证错误（Token过期、401错误）
/// - 未来可扩展：网络超时、服务器错误、限流错误等
sealed class NetworkError {
  const NetworkError();
}

/// 认证相关错误
///
/// 包含所有与认证相关的网络错误
sealed class NetworkAuthError extends NetworkError {
  const NetworkAuthError();

  /// Token 过期错误
  ///
  /// **触发场景**：
  /// - Token 过期被网络层检测到
  /// - 需要重新登录
  ///
  /// **处理方**：AuthProvider
  /// - 调用 Repository 清理本地数据
  /// - 更新状态为未认证
  /// - AuthNavigationListener 监听状态变化，导航到登录页
  const factory NetworkAuthError.tokenExpired(String message) = TokenExpiredError;

  /// 认证失败错误（401）
  ///
  /// **触发场景**：
  /// - HTTP 401 状态码
  /// - 业务层返回 code=401
  ///
  /// **处理方**：AuthProvider
  /// - 调用 Repository 清理本地数据
  /// - 更新状态为未认证
  /// - AuthNavigationListener 监听状态变化，导航到登录页
  const factory NetworkAuthError.authenticationFailed(String message) = AuthenticationFailedError;
}

/// Token 过期错误
class TokenExpiredError extends NetworkAuthError {
  const TokenExpiredError(this.message);

  /// 错误消息
  final String message;
}

/// 认证失败错误
class AuthenticationFailedError extends NetworkAuthError {
  const AuthenticationFailedError(this.message);

  /// 错误消息
  final String message;
}

// ============================================================================
// 未来可扩展的错误类型示例
// ============================================================================

/// 网络连接错误（示例，暂未实现）
///
/// 可用于处理：
/// - 网络超时
/// - 连接失败
/// - DNS 解析失败
// sealed class NetworkConnectionError extends NetworkError {
//   const NetworkConnectionError();
//   const factory NetworkConnectionError.timeout(String message) = NetworkTimeoutError;
//   const factory NetworkConnectionError.connectionFailed(String message) = ConnectionFailedError;
// }

/// 服务器错误（示例，暂未实现）
///
/// 可用于处理：
/// - 500 服务器内部错误
/// - 502 网关错误
/// - 503 服务不可用
// sealed class NetworkServerError extends NetworkError {
//   const NetworkServerError();
//   const factory NetworkServerError.internalError(String message) = InternalServerError;
//   const factory NetworkServerError.serviceUnavailable(String message) = ServiceUnavailableError;
// }

/// 限流错误（示例，暂未实现）
///
/// 可用于处理：
/// - 429 请求过多
/// - API 限流
// sealed class NetworkRateLimitError extends NetworkError {
//   const NetworkRateLimitError();
//   const factory NetworkRateLimitError.tooManyRequests(String message, Duration retryAfter) = TooManyRequestsError;
// }
