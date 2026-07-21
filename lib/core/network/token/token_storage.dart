/// Token 存储接口
///
/// 定义 Token 持久化存储的统一接口，将 Token 存储职责从 AuthRepository 中分离。
///
/// **架构位置**：Core/Network 层
///
/// **实现**：`TokenStorageImpl` 使用 SecureStorage 安全存储
///
/// **使用者**：
/// - `TokenStrategy`（Single/Dual）：通过此接口读写 Token
/// - Auth 模块 Repository：登录时保存 Token，登出时清除 Token
abstract class TokenStorage {
  /// 获取 access token
  Future<String?> getAccessToken();

  /// 保存 access token
  Future<void> saveAccessToken(String token);

  /// 清除 access token
  Future<void> clearAccessToken();

  /// 获取 refresh token（双 Token 模式使用）
  Future<String?> getRefreshToken();

  /// 保存 refresh token（双 Token 模式使用）
  Future<void> saveRefreshToken(String refreshToken);

  /// 清除 refresh token
  Future<void> clearRefreshToken();

  /// 清除所有 token（access + refresh）
  Future<void> clearAll();
}
