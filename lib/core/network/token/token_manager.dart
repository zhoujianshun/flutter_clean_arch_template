import 'dart:async';

import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';
import 'package:flutter_clean_arch_template/core/network/token/token_strategy.dart';


/// Token 管理器
///
/// 统一管理 Token 的获取、刷新、存储等操作
///
/// 核心功能：
/// - 支持多种 Token 策略（单 Token、双 Token 等）
/// - 自动刷新机制（根据策略）
/// - 并发安全（刷新锁机制）
/// - 支持运行时动态切换策略
///
/// 刷新锁机制：
/// - 使用 Completer 确保同一时间只有一个刷新请求
/// - 并发请求会等待正在进行的刷新完成
/// - 避免多次重复刷新和竞态条件
///
/// 使用示例：
/// ```dart
/// // 单 Token 模式
/// final tokenManager = TokenManager(
///   strategy: SingleTokenStrategy(
///     tokenStorage: getIt<TokenStorage>(),
///   ),
/// );
///
/// // 双 Token 模式
/// final tokenManager = TokenManager(
///   strategy: DualTokenStrategy(
///     tokenStorage: getIt<TokenStorage>(),
///     dio: Dio(),
///     refreshEndpoint: '/auth/refresh',
///   ),
/// );
///
/// // 获取有效 token（自动刷新）
/// final token = await tokenManager.getValidToken();
/// ```
class TokenManager {
  TokenManager({
    required TokenStrategy strategy,
  }) : _strategy = strategy {
    AppLogger.info('[TokenManager] 初始化，使用策略: ${strategy.name}');
  }

  /// 当前使用的 Token 策略
  TokenStrategy _strategy;

  /// 刷新锁，防止并发刷新
  ///
  /// - null: 没有刷新在进行
  /// - 未完成的 Completer: 有刷新正在进行，其他请求需要等待
  /// - 已完成的 Completer: 刷新已完成（2 秒窗口期内复用结果）
  Completer<String?>? _refreshCompleter;

  /// 窗口期计时器，用于 2 秒后清理 _refreshCompleter
  Timer? _windowTimer;

  /// 上次刷新失败的时间
  DateTime? _lastRefreshFailureTime;

  /// 刷新失败冷却时间（避免频繁重试）
  static const Duration _refreshCooldown = Duration(seconds: 30);

  /// 获取当前策略
  TokenStrategy get strategy => _strategy;

  /// 切换 Token 策略
  ///
  /// 支持运行时动态切换策略
  ///
  /// 注意：切换策略会清空缓存状态和刷新锁
  void setStrategy(TokenStrategy strategy) {
    if (_strategy.name == strategy.name) {
      AppLogger.debug('[TokenManager] 策略未变化: ${strategy.name}');
      return;
    }

    AppLogger.info('[TokenManager] 切换策略: ${_strategy.name} → ${strategy.name}');

    _strategy = strategy;

    _windowTimer?.cancel();
    _refreshCompleter = null;
    _lastRefreshFailureTime = null;
  }

  /// 获取有效的 access token
  ///
  /// 核心方法，提供以下功能：
  /// 1. 返回有效的 token
  /// 2. 如果需要刷新，自动刷新
  /// 3. 如果有刷新正在进行，等待刷新完成
  /// 4. 处理刷新失败的情况
  ///
  /// 返回：
  /// - 成功：返回有效的 access token
  /// - 失败：返回 null（需要重新登录）
  Future<String?> getValidToken() async {
    try {
      // 1. 如果有刷新正在进行，等待刷新完成
      if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
        AppLogger.debug('[TokenManager] 等待正在进行的刷新...');
        return await _refreshCompleter!.future;
      }

      // 2. 先获取当前 token（双 Token 模式会在此阶段初始化过期时间缓存）
      final currentToken = await _strategy.getAccessToken();
      if (currentToken == null || currentToken.isEmpty) {
        return null;
      }

      // 3. 检查是否需要刷新
      if (_strategy.shouldRefresh()) {
        if (_isInCooldown()) {
          AppLogger.warning('[TokenManager] 在刷新冷却期内，跳过刷新');
          return currentToken;
        }

        // 致命失败（refresh token 过期/不存在）由策略通过 onAuthExpired 回调通知上层，
        // 直接返回刷新结果（null），避免用即将过期的 token 发请求导致 401 再次触发重复通知
        return await _refreshToken();
      }

      // 4. 直接返回当前 token
      AppLogger.debug('[TokenManager] 返回有效 token');
      return currentToken;
    } catch (e) {
      AppLogger.error('[TokenManager] 获取有效 token 失败', error: e);
      return null;
    }
  }

  /// 刷新 token（带并发控制）
  ///
  /// 使用 Completer 实现刷新锁：
  /// - 第一个请求：创建 Completer 并执行刷新
  /// - 后续并发请求：等待 Completer 完成
  /// - 2 秒窗口期内：复用已完成的结果，避免重复刷新
  Future<String?> _refreshToken() async {
    // 如果已经有 Completer（进行中或刚完成的窗口期内），直接复用
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<String?>();

    try {
      AppLogger.info('[TokenManager] 开始刷新 token');

      final newToken = await _strategy.refreshToken();

      if (newToken != null && newToken.isNotEmpty) {
        AppLogger.info('[TokenManager] Token 刷新成功');
        _lastRefreshFailureTime = null;

        if (!_refreshCompleter!.isCompleted) {
          _refreshCompleter!.complete(newToken);
        }

        return newToken;
      } else {
        AppLogger.error('[TokenManager] Token 刷新失败：返回 null');
        _lastRefreshFailureTime = DateTime.now();

        if (!_refreshCompleter!.isCompleted) {
          _refreshCompleter!.complete(null);
        }

        return null;
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        '[TokenManager] Token 刷新时发生错误',
        error: e,
        stackTrace: stackTrace,
      );

      _lastRefreshFailureTime = DateTime.now();

      if (!_refreshCompleter!.isCompleted) {
        _refreshCompleter!.completeError(e, stackTrace);
      }

      return null;
    } finally {
      _windowTimer?.cancel();
      _windowTimer = Timer(const Duration(seconds: 2), () {
        _refreshCompleter = null;
      });
    }
  }

  /// 检查是否在刷新冷却期内
  bool _isInCooldown() {
    if (_lastRefreshFailureTime == null) {
      return false;
    }

    final cooldownEnd = _lastRefreshFailureTime!.add(_refreshCooldown);
    return DateTime.now().isBefore(cooldownEnd);
  }

  /// 保存 token
  ///
  /// [accessToken] 必须提供的访问令牌
  /// [refreshToken] 可选的刷新令牌
  Future<void> saveToken({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _strategy.saveAccessToken(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  /// 清除所有 token
  ///
  /// 用于登出或 token 失效时
  Future<void> clearToken() async {
    await _strategy.clearToken();
    _windowTimer?.cancel();
    _refreshCompleter = null;
    _lastRefreshFailureTime = null;
  }

  /// 检查 token 是否过期
  Future<bool> isTokenExpired() async {
    return _strategy.isTokenExpired();
  }

  /// 强制刷新 token
  ///
  /// 不管是否需要刷新，强制执行刷新
  /// 用于手动触发刷新的场景
  ///
  /// 如果当前策略不支持刷新，返回当前 access token
  Future<String?> forceRefresh() async {
    if (!_strategy.supportsRefresh) {
      AppLogger.warning('[TokenManager] 当前策略不支持刷新');
      return _strategy.getAccessToken();
    }
    AppLogger.info('[TokenManager] 强制刷新 token');
    return _refreshToken();
  }
}
