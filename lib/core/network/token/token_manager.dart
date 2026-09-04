import 'dart:async';

import 'package:clock/clock.dart';
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
/// - 刷新期间登出/切策略会立即唤醒等待者并丢弃过期结果（代际校验）
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

  /// 刷新结果复用窗口期（窗口期内迟到的请求直接复用已完成的刷新结果）
  static const Duration _resultReuseWindow = Duration(seconds: 2);

  /// 刷新代数，每次 clearToken/setStrategy 时递增。
  ///
  /// 用于丢弃"登出后才返回"的过期刷新结果：
  /// 刷新发起时记录代数，完成后若代数已变（期间发生过登出/切策略），
  /// 结果作废——不写回存储、不广播给等待者。
  int _refreshGeneration = 0;

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

    // 先让旧刷新的等待者立即失败返回，再切换状态
    _abortActiveRefresh('策略切换');
    _strategy = strategy;
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
      //    局部变量持有：await 期间即使 clearToken/setStrategy 置空了
      //    _refreshCompleter，此处也不会 NPE
      final pendingRefresh = _refreshCompleter;
      if (pendingRefresh != null && !pendingRefresh.isCompleted) {
        AppLogger.debug('[TokenManager] 等待正在进行的刷新...');
        return await pendingRefresh.future;
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
    final existing = _refreshCompleter;
    if (existing != null) {
      return existing.future;
    }

    final completer = Completer<String?>();
    _refreshCompleter = completer;

    // 记录刷新代数：完成后若代数已变（期间发生过 clearToken/setStrategy），结果作废
    final generation = _refreshGeneration;

    try {
      AppLogger.info('[TokenManager] 开始刷新 token (gen=$generation)');

      final newToken = await _strategy.refreshToken();

      // 代际校验：刷新期间发生过登出/切策略，丢弃迟到结果
      if (generation != _refreshGeneration) {
        AppLogger.warning('[TokenManager] 刷新结果已过期（代际变更），丢弃');
        return null;
      }

      if (newToken != null && newToken.isNotEmpty) {
        AppLogger.info('[TokenManager] Token 刷新成功');
        _lastRefreshFailureTime = null;

        if (!completer.isCompleted) {
          completer.complete(newToken);
        }

        return newToken;
      } else {
        AppLogger.error('[TokenManager] Token 刷新失败：返回 null');
        _lastRefreshFailureTime = clock.now();

        if (!completer.isCompleted) {
          completer.complete(null);
        }

        return null;
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        '[TokenManager] Token 刷新时发生错误',
        error: e,
        stackTrace: stackTrace,
      );

      if (generation == _refreshGeneration) {
        _lastRefreshFailureTime = clock.now();
      }

      // 错误语义统一为 null：本方法返回 null，等待者也拿 null。
      // 不用 completeError——无人监听的 errored future 会变成
      // unhandled async error 污染监控，且与 getValidToken 的
      // "null = 失败" 契约不一致
      if (!completer.isCompleted) {
        completer.complete(null);
      }

      return null;
    } finally {
      // 兜底：任何路径都确保 completer 已完成，
      // 所有等待者一定能被唤醒（不永久挂起）
      if (!completer.isCompleted) {
        completer.complete(null);
      }

      // 窗口期：仅当本轮刷新仍是"现任"（未被 clearToken/setStrategy
      // 接管）时才挂清理计时器，且清理前校验，防止误清他人的锁
      if (identical(_refreshCompleter, completer)) {
        _windowTimer?.cancel();
        _windowTimer = Timer(_resultReuseWindow, () {
          if (identical(_refreshCompleter, completer)) {
            _refreshCompleter = null;
          }
        });
      }
    }
  }

  /// 中止进行中的刷新：立即唤醒所有等待者（返回 null），推进代数。
  ///
  /// 调用时机：clearToken（登出）或 setStrategy（切换策略）——
  /// 此时旧 token 体系已作废，等待者不应再等旧刷新的结果。
  void _abortActiveRefresh(String reason) {
    _windowTimer?.cancel();
    _windowTimer = null;

    final active = _refreshCompleter;
    if (active != null) {
      _refreshGeneration++;
      if (!active.isCompleted) {
        AppLogger.info('[TokenManager] 中止进行中的刷新（$reason），唤醒等待者');
        active.complete(null);
      }
    }
    _refreshCompleter = null;
  }

  /// 检查是否在刷新冷却期内
  bool _isInCooldown() {
    if (_lastRefreshFailureTime == null) {
      return false;
    }

    final cooldownEnd = _lastRefreshFailureTime!.add(_refreshCooldown);
    return clock.now().isBefore(cooldownEnd);
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
  /// 用于登出或 token 失效时。
  /// 若有刷新正在进行，立即中止并唤醒等待者（避免其等待已作废的结果）。
  Future<void> clearToken() async {
    _abortActiveRefresh('登出');
    await _strategy.clearToken();
    _lastRefreshFailureTime = null;
  }

  /// 检查 token 是否过期
  Future<bool> isTokenExpired() async {
    return _strategy.isTokenExpired();
  }

  /// 强制刷新 token
  ///
  /// 不管是否需要刷新，强制执行刷新
  /// 用于手动触发刷新的场景（如 401 兜底刷新）
  ///
  /// 如果当前策略不支持刷新，返回当前 access token。
  /// 冷却期内不发起真实刷新，直接返回 null——调用方（AuthInterceptor）
  /// 拿到 null 后走登出路径，避免每个 401 请求都真实打一次刷新端点
  /// （单飞锁只能合并"同时"的并发刷新，防不了"连续"到来的 401 风暴）
  Future<String?> forceRefresh() async {
    if (!_strategy.supportsRefresh) {
      AppLogger.warning('[TokenManager] 当前策略不支持刷新');
      return _strategy.getAccessToken();
    }
    if (_isInCooldown()) {
      AppLogger.warning('[TokenManager] 冷却期内跳过强制刷新');
      return null;
    }
    AppLogger.info('[TokenManager] 强制刷新 token');
    return _refreshToken();
  }
}
