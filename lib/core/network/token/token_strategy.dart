/// 认证过期回调
///
/// 当策略确定需要重新登录时调用（如 refresh token 过期或不存在）。
/// 暂时性错误（网络超时、服务器 500）不应触发此回调。
typedef TokenAuthExpiredCallback = void Function(String message);

/// Token 策略接口
///
/// 定义了 Token 管理的统一接口，支持多种 Token 模式：
/// - 单一 Token 模式（SingleTokenStrategy）
/// - 双 Token 模式（DualTokenStrategy - Access + Refresh）
/// - 可扩展支持其他模式（OAuth、API Key 等）
///
/// 使用策略模式，便于在运行时动态切换不同的 Token 管理策略
abstract class TokenStrategy {
  /// 获取当前有效的 access token
  ///
  /// 返回 null 表示没有 token 或 token 无效
  Future<String?> getAccessToken();

  /// 保存 token
  ///
  /// [accessToken] 必须提供的访问令牌
  /// [refreshToken] 可选的刷新令牌（仅双 Token 模式使用）
  ///
  /// 示例：
  /// ```dart
  /// await strategy.saveAccessToken(
  ///   accessToken: 'eyJhbGc...',
  ///   refreshToken: 'refresh_token_value', // 双 Token 模式
  /// );
  /// ```
  Future<void> saveAccessToken({
    required String accessToken,
    String? refreshToken,
  });

  /// 清除所有 token
  ///
  /// 用于登出或 token 失效时清理
  Future<void> clearToken();

  /// 检查 token 是否已过期
  ///
  /// 单 Token 模式：通常返回 false（依赖服务器 401 判断）
  /// 双 Token 模式：解析 JWT token 获取过期时间进行判断
  Future<bool> isTokenExpired();

  /// 刷新 token
  ///
  /// 使用 refresh token 获取新的 access token
  ///
  /// 返回：
  /// - 成功：返回新的 access token
  /// - 失败/不支持：返回 null
  Future<String?> refreshToken();

  /// 判断是否需要刷新 token
  ///
  /// 单 Token 模式：总是返回 false
  /// 双 Token 模式：检查是否接近过期（如提前 5 分钟刷新）
  ///
  /// 用于在请求前主动刷新，避免请求失败
  bool shouldRefresh();

  /// 策略名称（用于日志和调试）
  String get name;

  /// 是否支持 token 刷新
  ///
  /// 单 Token 模式：false
  /// 双 Token 模式：true
  bool get supportsRefresh;
}
