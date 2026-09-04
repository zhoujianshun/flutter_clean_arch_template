import 'dart:async';

import 'package:clock/clock.dart';
import 'package:dio/dio.dart';
import 'package:flutter_clean_arch_template/core/errors/exceptions.dart';
import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';
import 'package:flutter_clean_arch_template/core/network/network_info.dart';

/// 连接检测拦截器
///
/// 功能：
/// - 在发送请求前检查网络连接状态
/// - 如果网络不可用，立即返回错误，避免无谓的请求尝试
/// - 提供更好的用户体验和错误提示
///
/// 缓存策略（时间兜底 + 事件失效，双保险）：
/// - 时间缓存：检测结果缓存 [cacheDuration]（默认 2 秒），防止
///   checkConnectivity 平台调用风暴
/// - 事件失效：订阅网络状态流，状态一变化立即作废缓存——
///   消除纯时间窗的假阳性（断网后仍放行）与假阴性（恢复后仍拒绝）
///
/// 使用场景：
/// - 所有需要网络连接的 API 请求
/// - 在拦截器链的最前面执行，优先检查网络
class ConnectivityInterceptor extends Interceptor {
  ConnectivityInterceptor({
    this.cacheDuration = const Duration(seconds: 2),
    NetworkInfo? networkInfo,
  }) : _networkInfo = networkInfo ?? NetworkInfo() {
    // 网络状态变化立即作废缓存：恢复连接不被旧的 false 拦截，
    // 断网即刻生效（无需等时间窗过期）
    _subscription = _networkInfo.networkStatusStream.listen((_) {
      _cachedConnectionStatus = null;
      _cacheTime = null;
    });
  }

  final NetworkInfo _networkInfo;

  /// 缓存有效期
  final Duration cacheDuration;

  /// 网络状态缓存（null 表示无有效缓存）
  bool? _cachedConnectionStatus;

  /// 缓存时间
  DateTime? _cacheTime;

  StreamSubscription<NetworkStatus>? _subscription;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final now = clock.now();
      final isCacheValid =
          _cacheTime != null && now.difference(_cacheTime!) < cacheDuration;

      bool isConnected;
      if (isCacheValid && _cachedConnectionStatus != null) {
        isConnected = _cachedConnectionStatus!;
      } else {
        isConnected = await _networkInfo.isConnected();
        _cachedConnectionStatus = isConnected;
        _cacheTime = now;
      }

      if (!isConnected) {
        AppLogger.warning(
          '[Connectivity] 网络不可用，拒绝请求: [${options.method}] ${options.uri}',
        );
        throw const NetworkException(
          message: '网络连接不可用，请检查网络设置',
        );
      }

      handler.next(options);
    } catch (e) {
      if (e is NetworkException) {
        // 网络异常，拒绝请求
        handler.reject(
          DioException(
            requestOptions: options,
            error: e,
            type: DioExceptionType.connectionError,
            message: e.message,
          ),
        );
      } else {
        // 连接检测本身失败，记录错误但继续请求
        AppLogger.error('网络连接检测失败: $e');
        handler.next(options);
      }
    }
  }

  /// 清理资源（通常仅测试需要；生产环境随 ApiClient 单例存活）
  void dispose() {
    unawaited(_subscription?.cancel());
    _subscription = null;
  }
}
