import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_clean_arch_template/core/di/service_locator.dart';
import 'package:flutter_clean_arch_template/core/env/app_config.dart';
import 'package:flutter_clean_arch_template/core/l10n/app_language.dart';
import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';
import 'package:flutter_clean_arch_template/core/network/auth_config.dart';
import 'package:flutter_clean_arch_template/core/network/errors/network_error.dart';
import 'package:flutter_clean_arch_template/core/network/errors/network_error_notifier.dart';
import 'package:flutter_clean_arch_template/core/network/interceptors/retry_interceptor.dart';
import 'package:flutter_clean_arch_template/core/network/token/dual_token_strategy.dart';
import 'package:flutter_clean_arch_template/core/network/token/token_manager.dart';

/// Authentication interceptor
///
/// Responsibilities:
/// - Attach auth token to requests (via TokenManager)
/// - Set request language header
/// - Detect auth errors (HTTP 401 and business-layer 401)
/// - Recover from auth failures by refreshing + replaying (dual-token only)
/// - Notify auth errors via NetworkErrorNotifier (only when unrecoverable)
///
/// 401 处理三层模型（dual-token 三层齐备，single-token 仅第三层）：
/// 1. 预刷（快路径）：TokenManager.getValidToken() 请求前主动续期，
///    覆盖 token 自然过期（日常绝大多数场景）
/// 2. 401 兜底恢复（慢路径）：检测到 401 → forceRefresh（内部单飞锁
///    合并并发刷新）→ 成功则重放原请求一次（走完整拦截链）
/// 3. 登出（终态）：重放后仍 401 / 单 Token 401 → 通知上层登出
///
/// 登出通知的收敛规则（避免双通道双登出）：
/// - 刷新致命失败（refresh token 过期/不存在）：策略层 onAuthExpired
///   发 tokenExpired，拦截器不重复通知
/// - 刷新临时失败（网络/5xx）：不通知不登出，请求按原错误返回，
///   用户侧表现为可重试的普通失败
/// - 重放后仍 401：新 token 也被服务端拒绝 → 终态，通知登出
/// - 单 Token 模式 401：无恢复手段 → 通知登出（与历史行为一致）
///
/// Public paths (skip auth) are configured via [AuthConfig] in GetIt,
/// keeping core/ independent of feature/ layers.
class AuthInterceptor extends Interceptor {
  /// 延迟获取：AuthInterceptor 在 ApiClient 构造期间添加到拦截器链，
  /// 此时 GetIt 中的依赖可能尚未全部注册完毕，因此用 late final
  /// 延迟到首次请求时获取并缓存。
  late final TokenManager _tokenManager = getIt<TokenManager>();
  late final NetworkErrorNotifier _errorNotifier =
      getIt<NetworkErrorNotifier>();

  /// AuthConfig 必须每次实时解析、不可缓存：
  /// AuthProvider 启动时会 unregister 并重新注册带 publicPaths 的实例，
  /// late final 缓存会把首次解析到的空配置永久固化，
  /// 导致登录等公共路径被误判为需认证（且不自愈）。
  AuthConfig get _authConfig => getIt<AuthConfig>();

  /// extra 中标记"已因 401 重放过"的键名（防二次重放死循环）
  static const String kAuthRetriedKey = 'auth_retried';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final languageCode = AppLanguage.chinese.locale.toString();
      options.headers['content-language'] = languageCode;
      options.headers['ClientId'] = AppConfig.clientId;

      if (_shouldSkipAuth(options.path)) {
        return handler.next(options);
      }

      final token = await _tokenManager.getValidToken();

      if (token == null || token.isEmpty) {
        AppLogger.warning(
          '[AuthInterceptor] No valid token, rejecting auth-required request: ${options.path}',
        );

        if (!_tokenManager.strategy.supportsRefresh) {
          _publishAuthenticationFailedEvent('No valid auth token');
        }

        final unauthorizedResponse = Response<dynamic>(
          requestOptions: options,
          statusCode: 401,
          data: const {
            'code': 401,
            'msg': 'No valid auth token',
            'message': 'No valid auth token',
          },
        );

        return handler.reject(
          DioException(
            requestOptions: options,
            response: unauthorizedResponse,
            type: DioExceptionType.badResponse,
            message: 'No valid auth token',
          ),
          true,
        );
      } else {
        options.headers['Authorization'] = 'Bearer $token';
        AppLogger.debug(
          '[AuthInterceptor] Token injected: [${options.method}] ${options.path}',
        );
      }

      handler.next(options);
    } catch (e) {
      AppLogger.error(
        '[AuthInterceptor] Request interception failed: $e',
        error: e,
      );
      handler.reject(
        DioException(
          requestOptions: options,
          error: e,
          message: 'Auth interceptor error: $e',
        ),
        true,
      );
    }
  }

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    try {
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final code = data['code'] as int?;
        final message = data['msg'] as String?;

        if (code == 401) {
          AppLogger.warning('Business-layer auth failure detected: $message');
          final options = response.requestOptions;

          if (options.extra[kAuthRetriedKey] == true) {
            // 重放后的响应仍为业务 401：新 token 也被拒 → 终态
            _notifyTerminalAuthFailure(
              options,
              message ?? 'Authentication failed',
            );
          } else if (await _tryRefreshAndReplay(options, handler)) {
            return;
          } else if (!_tokenManager.strategy.supportsRefresh) {
            // 单 Token：无恢复手段（保持历史通知行为）
            _notifyTerminalAuthFailure(
              options,
              message ?? 'Authentication failed',
            );
          }
          // 双 Token 且刷新失败：致命失败策略层已通知 tokenExpired，
          // 临时失败设计上不登出——此处均保持沉默
        }
      }
      handler.next(response);
    } catch (e) {
      handler.next(response);
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      AppLogger.warning('HTTP 401 auth failure detected: ${err.message}');
      final options = err.requestOptions;
      final retried = options.extra[kAuthRetriedKey] == true;

      if (!retried && await _tryRefreshAndReplayOnError(err, handler)) {
        return;
      }

      // 到这里说明恢复未发生或恢复失败：
      // - retried：重放（inner 链）已发过终态通知，此处为防抖兜底
      // - 单 Token：无恢复手段，通知登出
      // - 刷新失败：致命由策略层通知，临时设计上不登出——均不在此通知
      if ((retried || !_tokenManager.strategy.supportsRefresh) &&
          !_isRefreshRequest(options.path) &&
          !_shouldSkipAuth(options.path)) {
        _publishAuthenticationFailedEvent(err.message ?? 'HTTP auth failed');
      }
    }

    handler.next(err);
  }

  /// 终态认证失败通知（带公共路径/刷新端点守卫）
  void _notifyTerminalAuthFailure(RequestOptions options, String message) {
    if (_isRefreshRequest(options.path) || _shouldSkipAuth(options.path)) {
      return;
    }
    _publishAuthenticationFailedEvent(message);
  }

  /// 尝试刷新 token 并重放原请求（onResponse 路径：业务层 401）
  ///
  /// 返回 true 表示已用新响应接管（handler.resolve），调用方应直接 return
  Future<bool> _tryRefreshAndReplay(
    RequestOptions options,
    ResponseInterceptorHandler handler,
  ) async {
    final replayed = await _replayWithFreshToken(options);
    if (replayed != null) {
      handler.resolve(replayed);
      return true;
    }
    return false;
  }

  /// 尝试刷新 token 并重放原请求（onError 路径：HTTP 401）
  Future<bool> _tryRefreshAndReplayOnError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final replayed = await _replayWithFreshToken(err.requestOptions);
    if (replayed != null) {
      handler.resolve(replayed);
      return true;
    }
    return false;
  }

  /// 刷新 + 重放核心逻辑，两个 401 入口共用
  ///
  /// 返回 null 表示恢复失败（或不需要恢复），调用方维持原错误/登出路径；
  /// 返回 Response 表示重放成功，用新响应替换原结果。
  ///
  /// 五重防死循环防护：
  /// 1. 公共路径（登录等）不进恢复流程
  /// 2. 单 Token 模式（不支持刷新）不进恢复流程
  /// 3. 已重放过（extra[kAuthRetriedKey]）不二次重放——新 token 仍 401
  ///    说明凭证真被拒，再刷无意义
  /// 4. 刷新端点自身的 401 不进恢复流程
  /// 5. 已取消的请求不重放（用户已放弃）
  Future<Response<dynamic>?> _replayWithFreshToken(
    RequestOptions options,
  ) async {
    if (_shouldSkipAuth(options.path) ||
        !_tokenManager.strategy.supportsRefresh ||
        options.extra[kAuthRetriedKey] == true ||
        _isRefreshRequest(options.path)) {
      return null;
    }

    if (options.cancelToken?.isCancelled == true) {
      AppLogger.debug('[AuthInterceptor] Request cancelled, skip replay');
      return null;
    }

    final dio = options.extra[RetryInterceptor.kDioInstanceKey] as Dio?;
    if (dio == null) {
      AppLogger.warning(
        '[AuthInterceptor] No Dio instance available, skip replay',
      );
      return null;
    }

    AppLogger.info(
      '[AuthInterceptor] Trying to recover request via refresh + replay',
    );
    final newToken = await _tokenManager.forceRefresh();

    if (newToken == null || newToken.isEmpty) {
      return null;
    }

    options.extra[kAuthRetriedKey] = true;

    try {
      // 走完整拦截链重放：onRequest 重新注入最新 token 与请求头，
      // onResponse/onError 链对新响应同样生效（retried 标记防止二次恢复）
      final response = await dio.fetch<dynamic>(options);
      AppLogger.info('[AuthInterceptor] Replay succeeded: ${options.uri}');
      return response;
    } on DioException catch (e) {
      // 重放失败不吞错误语义：返回 null 让原错误沿链传播。
      // inner 链已对重放的 401 发过终态通知
      AppLogger.warning('[AuthInterceptor] Replay failed: ${e.message}');
      return null;
    }
  }

  bool _shouldSkipAuth(String path) {
    final normalizedPath = Uri.tryParse(path)?.path ?? path;
    return _authConfig.publicPaths.contains(normalizedPath);
  }

  bool _isRefreshRequest(String path) {
    final normalizedPath = Uri.tryParse(path)?.path ?? path;

    final strategy = _tokenManager.strategy;
    if (strategy is DualTokenStrategy) {
      final refreshPath =
          Uri.tryParse(strategy.refreshEndpoint)?.path ??
          strategy.refreshEndpoint;
      if (normalizedPath == refreshPath ||
          normalizedPath.endsWith(refreshPath)) {
        return true;
      }
    }

    return normalizedPath == '/auth/refresh' ||
        normalizedPath.endsWith('/auth/refresh');
  }

  void _publishAuthenticationFailedEvent(String message) {
    try {
      AppLogger.i('AuthInterceptor: Notifying auth failure - $message');
      _errorNotifier.notifyAuthError(
        NetworkAuthError.authenticationFailed(message),
      );
    } catch (e, stackTrace) {
      AppLogger.e(
        'AuthInterceptor: Error notifying auth failure',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
