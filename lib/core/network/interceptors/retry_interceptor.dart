import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';

/// 重试拦截器
///
/// 功能：
/// - 对失败的网络请求自动进行重试
/// - 使用指数退避策略 + 随机抖动（exponential backoff with jitter）
/// - 默认仅重试幂等请求（GET/HEAD/OPTIONS），非幂等请求需显式标记 `retryable`
/// - 仅对特定错误类型进行重试（超时、服务器错误等）
/// - 避免对客户端错误（4xx）进行无意义的重试
///
/// 配置：
/// - maxRetries: 最大重试次数（默认 3 次）
/// - retryDelay: 基础重试延迟（默认 1 秒）
/// - 实际延迟 = retryDelay * 2^attempt + jitter（真正的指数退避）
///
/// 幂等安全策略：
/// - GET/HEAD/OPTIONS 默认可重试
/// - POST/PUT/DELETE/PATCH 默认不重试，需通过 `requestOptions.extra['retryable'] = true` 显式启用
///
/// 使用场景：
/// - 网络不稳定环境
/// - 需要提高请求成功率的场景
/// - 可选功能，根据业务需求在 ApiClient 中启用
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
    this.retryableStatusCodes = const [408, 429, 500, 502, 503, 504],
    this.idempotentMethods = const ['GET', 'HEAD', 'OPTIONS'],
    Random? random,
  }) : _random = random ?? Random();

  /// 最大重试次数
  final int maxRetries;

  /// 基础重试延迟时间
  final Duration retryDelay;

  /// 可重试的 HTTP 状态码
  final List<int> retryableStatusCodes;

  /// 默认允许重试的幂等 HTTP 方法（大写）
  final List<String> idempotentMethods;

  final Random _random;

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_shouldRetry(err)) {
      final requestOptions = err.requestOptions;
      final currentRetryCount = requestOptions.extra['retry_count'] as int? ?? 0;

      if (currentRetryCount < maxRetries) {
        requestOptions.extra['retry_count'] = currentRetryCount + 1;

        AppLogger.warning(
          '重试请求 (${currentRetryCount + 1}/$maxRetries): '
          '[${requestOptions.method}] ${requestOptions.uri}',
        );

        final delay = _calculateDelay(currentRetryCount);
        await Future<void>.delayed(delay);

        try {
          final dio = requestOptions.extra['dio_instance'] as Dio;
          final response = await dio.fetch<dynamic>(requestOptions);

          AppLogger.info('重试成功: ${requestOptions.uri}');
          return handler.resolve(response);
        } on DioException catch (e) {
          AppLogger.error('重试失败 (${currentRetryCount + 1}/$maxRetries): ${e.message}');

          if (currentRetryCount + 1 < maxRetries) {
            return onError(e, handler);
          }
        } catch (e) {
          AppLogger.error('重试过程中发生意外错误: $e');
        }
      } else {
        AppLogger.error('已达到最大重试次数 ($maxRetries): ${requestOptions.uri}');
      }
    }

    handler.next(err);
  }

  /// 计算指数退避延迟（含随机抖动）
  ///
  /// delay = base * 2^attempt + jitter(0~300ms)
  Duration _calculateDelay(int attempt) {
    final exponentialMs = retryDelay.inMilliseconds * pow(2, attempt).toInt();
    final jitterMs = _random.nextInt(300);
    return Duration(milliseconds: exponentialMs + jitterMs);
  }

  /// 判断请求方法是否允许重试
  ///
  /// 幂等方法（GET/HEAD/OPTIONS）默认允许；
  /// 非幂等方法（POST/PUT/DELETE/PATCH）需要调用方通过
  /// `extra['retryable'] = true` 显式声明才允许重试。
  bool _isMethodRetryable(RequestOptions options) {
    final method = options.method.toUpperCase();
    if (idempotentMethods.contains(method)) {
      return true;
    }
    if (options.extra['retryable'] == true) {
      return true;
    }
    AppLogger.debug('[RetryInterceptor] 非幂等方法 $method 且未标记 retryable，跳过重试: ${options.uri}');
    return false;
  }

  /// 判断请求是否应该重试
  ///
  /// 重试策略：
  /// 1. 先检查方法幂等性（非幂等且未显式标记则不重试）
  /// 2. 缺少 dio_instance 引用时不重试（无法发出正确请求）
  /// 3. 取消的请求不重试
  /// 4. 证书错误不重试
  /// 5. 超时错误：重试
  /// 6. 服务器错误（5xx）和特定状态码（408/429）：重试
  /// 7. 网络连接错误：重试
  bool _shouldRetry(DioException err) {
    if (!_isMethodRetryable(err.requestOptions)) {
      return false;
    }

    if (err.requestOptions.extra['dio_instance'] is! Dio) {
      AppLogger.warning('[RetryInterceptor] 缺少 dio_instance 引用，跳过重试: ${err.requestOptions.uri}');
      return false;
    }

    if (err.type == DioExceptionType.cancel) {
      return false;
    }

    if (err.type == DioExceptionType.badCertificate) {
      return false;
    }

    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      return true;
    }

    if (err.type == DioExceptionType.badResponse) {
      final statusCode = err.response?.statusCode;
      if (statusCode == null) return false;
      return statusCode >= 500 || retryableStatusCodes.contains(statusCode);
    }

    if (err.type == DioExceptionType.unknown || err.type == DioExceptionType.connectionError) {
      final message = err.message?.toLowerCase() ?? '';
      return message.contains('network') ||
          message.contains('connection') ||
          message.contains('socket') ||
          message.contains('failed host lookup');
    }

    return false;
  }
}
