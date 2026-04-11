import 'dart:async';

import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';
import 'package:flutter_clean_arch_template/core/network/errors/network_error.dart';
import 'package:injectable/injectable.dart';

/// 网络层错误通知器
///
/// **职责**：网络层检测到错误后，通知应用层处理
///
/// **当前支持的错误类型**：
/// - 认证错误（TokenExpiredError、AuthenticationFailedError）
///
/// **未来可扩展**：
/// - 网络连接错误（超时、连接失败等）
/// - 服务器错误（500、502、503等）
/// - 限流错误（429等）
/// - 其他网络层错误
///
/// **不应该用于**：
/// - ❌ 业务逻辑事件（应该通过 UseCase 返回值）
/// - ❌ UI 事件（应该使用其他机制）
/// - ❌ 应用层错误（应该在应用层处理）
///
/// **架构位置**：Shared/Network 层
/// **通信方向**：Network Layer (Interceptor) → Presentation Layer (Provider)
///
/// **设计原则**：
/// 1. 单一职责：只负责网络层错误的通知
/// 2. 单向通信：从底层（Network）到上层（Presentation）
/// 3. 解耦：避免 Interceptor 直接依赖 Repository 或 Provider
/// 4. 可扩展：支持添加更多错误类型
@singleton
class NetworkErrorNotifier {
  NetworkErrorNotifier() {
    AppLogger.i('NetworkErrorNotifier: 初始化网络错误通知器');
  }

  final StreamController<NetworkError> _controller = StreamController<NetworkError>.broadcast();

  /// 认证错误防抖：上次发布时间
  DateTime? _lastAuthErrorAt;

  /// 认证错误防抖时长（500ms 内不重复发布）
  static const Duration _authErrorDebounce = Duration(milliseconds: 500);

  /// 错误流
  ///
  /// 供 Presentation 层订阅网络错误
  ///
  /// **订阅者示例**：
  /// - AuthProvider：监听认证错误，调用 Repository 清理数据，更新状态
  /// - 未来可添加：NetworkStatusProvider、ErrorHandlingProvider 等
  Stream<NetworkError> get stream => _controller.stream;

  /// 认证错误流（过滤后的流）
  ///
  /// 只包含认证相关的错误
  /// 供 AuthProvider 订阅，避免处理无关错误
  Stream<NetworkAuthError> get authErrorStream =>
      _controller.stream.where((error) => error is NetworkAuthError).cast<NetworkAuthError>();

  /// 通知网络错误
  ///
  /// **调用者**：Network Layer（各种 Interceptor）
  ///
  /// **支持的错误类型**：
  /// - [NetworkAuthError]：认证错误（TokenExpiredError、AuthenticationFailedError）
  /// - 未来可扩展：NetworkConnectionError、NetworkServerError 等
  ///
  /// **注意**：
  /// - 不要用于通知业务逻辑事件
  /// - 业务事件应该通过 UseCase 的返回值处理
  ///
  /// [error] 要通知的网络错误
  void notify(NetworkError error) {
    if (_controller.isClosed) {
      AppLogger.w('NetworkErrorNotifier: 通知器已关闭，无法发送通知');
      return;
    }

    _controller.add(error);
  }

  /// 通知认证错误（带防抖）
  ///
  /// 500ms 内重复的认证错误会被过滤，避免短时间内多次触发相同处理。
  /// 防抖职责统一在此处，调用方（AuthInterceptor、TokenManager）无需额外防抖。
  ///
  /// [error] 认证错误
  void notifyAuthError(NetworkAuthError error) {
    final now = DateTime.now();
    if (_lastAuthErrorAt != null && now.difference(_lastAuthErrorAt!) < _authErrorDebounce) {
      AppLogger.d('NetworkErrorNotifier: 认证错误防抖，跳过重复通知');
      return;
    }
    _lastAuthErrorAt = now;
    notify(error);
  }

  /// 清理资源
  ///
  /// 关闭事件流控制器
  /// 通常在应用退出时调用
  void dispose() {
    if (!_controller.isClosed) {
      AppLogger.i('NetworkErrorNotifier: 清理资源，关闭事件流');
      _controller.close();
    }
  }
}
