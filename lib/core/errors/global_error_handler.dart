import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';

/// 全局错误处理工具类
class ErrorHandlerUtils {
  ErrorHandlerUtils._();

  /// 安全执行同步操作
  static T? safeExecute<T>(
    T Function() operation, {
    String? context,
    T? fallbackValue,
  }) {
    try {
      return operation();
    } catch (error, stackTrace) {
      AppLogger.error('SafeExecute: $error', error: error, stackTrace: stackTrace);
      return fallbackValue;
    }
  }

  /// 安全执行异步操作
  static Future<T?> safeExecuteAsync<T>(
    Future<T> Function() operation, {
    String? context,
    T? fallbackValue,
  }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      AppLogger.error('SafeExecuteAsync: $error', error: error, stackTrace: stackTrace);
      return fallbackValue;
    }
  }

  /// 创建错误边界Widget
  static Widget errorBoundary({
    required Widget child,
    Widget? fallback,
    String? context,
  }) {
    return ErrorBoundary(
      fallback: fallback,
      context: context,
      child: child,
    );
  }
}

/// 错误边界Widget
class ErrorBoundary extends StatefulWidget {
  const ErrorBoundary({
    required this.child,
    super.key,
    this.fallback,
    this.context,
  });

  final Widget child;
  final Widget? fallback;
  final String? context;

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;
  Object? _error;

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.fallback ?? _buildDefaultErrorWidget();
    }

    return Builder(
      builder: (context) {
        try {
          return widget.child;
        } catch (error, stackTrace) {
          _handleError(error, stackTrace);
          return widget.fallback ?? _buildDefaultErrorWidget();
        }
      },
    );
  }

  void _handleError(Object error, StackTrace stackTrace) {
    setState(() {
      _hasError = true;
      _error = error;
    });

    AppLogger.error('ErrorBoundary: $error', error: error, stackTrace: stackTrace);
  }

  Widget _buildDefaultErrorWidget() {
    if (kDebugMode) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.red.shade100,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 8),
            Text(
              'Widget Error',
              style: TextStyle(
                color: Colors.red.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _error?.toString() ?? 'Unknown error',
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // 生产模式下返回空容器
    return const SizedBox.shrink();
  }
}

/// 平台通道错误捕获工具类
///
/// 提供平台通道错误处理的实用方法
class PlatformChannelErrorHandler {
  PlatformChannelErrorHandler._();

  /// 安全执行MethodChannel调用
  static Future<T?> safeInvokeMethod<T>(
    MethodChannel channel,
    String method, [
    dynamic arguments,
  ]) async {
    try {
      return await channel.invokeMethod<T>(method, arguments);
    } catch (error, stackTrace) {
      // 上报到全局错误处理器
      AppLogger.error('SafeInvokeMethod: $error', error: error, stackTrace: stackTrace);
      return null;
    }
  }

  /// 安全设置消息处理器
  static void safeSetMessageHandler(
    String channelName,
    Future<ByteData?> Function(ByteData? message)? handler,
  ) {
    final channel = BasicMessageChannel<ByteData?>(
      channelName,
      const BinaryCodec(),
    );

    if (handler == null) {
      channel.setMessageHandler(null);
      return;
    }

    channel.setMessageHandler((message) async {
      try {
        return await handler(message);
      } catch (error, stackTrace) {
        AppLogger.error('SafeSetMessageHandler: $error', error: error, stackTrace: stackTrace);
        // 返回空的ByteData而不是null
        return ByteData(0);
      }
    });
  }
}
