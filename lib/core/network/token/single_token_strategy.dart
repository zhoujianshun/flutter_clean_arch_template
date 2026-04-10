import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';
import 'package:flutter_clean_arch_template/core/network/token/token_storage.dart';
import 'package:flutter_clean_arch_template/core/network/token/token_strategy.dart';

/// 单一 Token 策略
///
/// 只管理一个 access token，不支持自动刷新
///
/// 特点：
/// - 简单直接，适用于大多数场景
/// - Token 过期依赖服务器返回 401 判断
/// - 不支持 refresh token
/// - 不支持主动刷新
///
/// 适用场景：
/// - 简单的认证系统
/// - Token 有效期较长的应用
/// - 不需要无感刷新的场景
///
/// 使用示例：
/// ```dart
/// final strategy = SingleTokenStrategy(
///   tokenStorage: getIt<TokenStorage>(),
/// );
/// ```
class SingleTokenStrategy implements TokenStrategy {
  SingleTokenStrategy({
    required TokenStorage tokenStorage,
  }) : _tokenStorage = tokenStorage;

  final TokenStorage _tokenStorage;

  @override
  String get name => 'SingleToken';

  @override
  bool get supportsRefresh => false;

  @override
  Future<String?> getAccessToken() async {
    final token = await _tokenStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      return token;
    }
    return null;
  }

  @override
  Future<void> saveAccessToken({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _tokenStorage.saveAccessToken(accessToken);

    if (refreshToken != null) {
      AppLogger.warning('[$name] 单 Token 模式不支持 refresh token，已忽略');
    }
  }

  @override
  Future<void> clearToken() async {
    await _tokenStorage.clearAccessToken();
  }

  @override
  Future<bool> isTokenExpired() async {
    return false;
  }

  @override
  bool shouldRefresh() {
    return false;
  }

  @override
  Future<String?> refreshToken() async {
    AppLogger.warning('[$name] 单 Token 模式不支持 token 刷新');
    return null;
  }
}
