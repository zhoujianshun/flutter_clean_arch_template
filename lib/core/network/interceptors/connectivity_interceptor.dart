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
/// 使用场景：
/// - 所有需要网络连接的 API 请求
/// - 在拦截器链的最前面执行，优先检查网络
///
/// 性能优化：
/// - 使用缓存机制，避免频繁检测网络状态
/// - 缓存有效期 2 秒，减少不必要的系统调用
class ConnectivityInterceptor extends Interceptor {
  ConnectivityInterceptor({
    this.cacheDuration = const Duration(seconds: 2),
  });

  final NetworkInfo _networkInfo = NetworkInfo();

  /// 缓存有效期
  final Duration cacheDuration;

  /// 网络状态缓存
  bool? _cachedConnectionStatus;

  /// 缓存时间
  DateTime? _cacheTime;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      // 检查缓存是否有效
      final now = DateTime.now();
      final isCacheValid = _cacheTime != null && now.difference(_cacheTime!) < cacheDuration;

      // 使用缓存或重新检测
      bool isConnected;
      if (isCacheValid && _cachedConnectionStatus != null) {
        isConnected = _cachedConnectionStatus!;
      } else {
        isConnected = await _networkInfo.isConnected();
        _cachedConnectionStatus = isConnected;
        _cacheTime = now;
      }

      if (!isConnected) {
        AppLogger.warning('[Connectivity] 网络不可用，拒绝请求: [${options.method}] ${options.uri}');
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
}
