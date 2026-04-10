import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_clean_arch_template/core/di/service_locator.dart';
import 'package:flutter_clean_arch_template/core/env/app_config.dart';
import 'package:flutter_clean_arch_template/core/l10n/app_language.dart';
import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';
import 'package:flutter_clean_arch_template/core/network/auth_config.dart';
import 'package:flutter_clean_arch_template/core/network/errors/network_error.dart';
import 'package:flutter_clean_arch_template/core/network/errors/network_error_notifier.dart';
import 'package:flutter_clean_arch_template/core/network/token/dual_token_strategy.dart';
import 'package:flutter_clean_arch_template/core/network/token/token_manager.dart';

/// Authentication interceptor
///
/// Responsibilities:
/// - Attach auth token to requests (via TokenManager)
/// - Set request language header
/// - Detect auth errors (HTTP 401 and business-layer 401)
/// - Notify auth errors via NetworkErrorNotifier
///
/// Public paths (skip auth) are configured via [AuthConfig] in GetIt,
/// keeping core/ independent of feature/ layers.
class AuthInterceptor extends Interceptor {
  TokenManager get _tokenManager => getIt<TokenManager>();
  NetworkErrorNotifier get _errorNotifier => getIt<NetworkErrorNotifier>();
  AuthConfig get _authConfig => getIt<AuthConfig>();

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

        return handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.cancel,
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
      AppLogger.error('[AuthInterceptor] Request interception failed: $e', error: e);
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
      if (response.data != null && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final code = data['code'] as int?;
        final message = data['msg'] as String?;

        if (code == 401) {
          AppLogger.warning('Business-layer auth failure detected: $message');
          if (!_shouldSkipAuth(response.requestOptions.path)) {
            _publishAuthenticationFailedEvent(
              message ?? 'Authentication failed',
            );
          }
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
    final path = err.requestOptions.path;

    if (err.response?.statusCode == 401 &&
        !_isRefreshRequest(path) &&
        !_shouldSkipAuth(path)) {
      AppLogger.warning('HTTP 401 auth failure detected: ${err.message}');
      _publishAuthenticationFailedEvent(err.message ?? 'HTTP auth failed');
    }

    handler.next(err);
  }

  bool _shouldSkipAuth(String path) {
    final normalizedPath = Uri.tryParse(path)?.path ?? path;
    return _authConfig.publicPaths.any(
      (skipPath) =>
          normalizedPath == skipPath || normalizedPath.endsWith(skipPath),
    );
  }

  bool _isRefreshRequest(String path) {
    final normalizedPath = Uri.tryParse(path)?.path ?? path;

    final strategy = _tokenManager.strategy;
    if (strategy is DualTokenStrategy) {
      final refreshPath =
          Uri.tryParse(strategy.refreshEndpoint)?.path ??
          strategy.refreshEndpoint;
      if (normalizedPath.contains(refreshPath)) {
        return true;
      }
    }

    return normalizedPath.contains('/auth/refresh');
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
