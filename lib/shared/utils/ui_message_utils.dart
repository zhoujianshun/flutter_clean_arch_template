import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';

/// UI 消息工具类
///
/// 提供统一的消息提示功能，替代原 RouteUtilSnackBarExtension
///
/// 使用示例：
/// ```dart
/// await UiMessageUtils.showSuccess('操作成功');
/// await UiMessageUtils.showError('操作失败');
/// await UiMessageUtils.showWarning('请注意');
/// await UiMessageUtils.showInfo('提示信息');
/// ```
class UiMessageUtils {
  UiMessageUtils._();

  /// 全局导航键（需要在main.dart中设置）
  static GlobalKey<NavigatorState>? navigatorKey;

  /// 获取当前上下文
  static BuildContext? get _context => navigatorKey?.currentContext;

  /// 显示 SnackBar
  ///
  /// [message] 消息内容
  /// [duration] 显示时长
  /// [action] 操作按钮
  /// [backgroundColor] 背景颜色
  static void showSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    Color? backgroundColor,
  }) {
    try {
      if (_context == null) {
        AppLogger.error('UiMessageUtils: Context is null, cannot show SnackBar');
        return;
      }

      AppLogger.info('显示 SnackBar: $message');

      ScaffoldMessenger.of(_context!).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: duration,
          action: action,
          backgroundColor: backgroundColor,
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error('显示 SnackBar 失败', error: e, stackTrace: stackTrace);
    }
  }

  /// 显示成功消息（绿色背景）
  ///
  /// [message] 消息内容
  static void showSuccess(String message) {
    showSnackBar(
      message,
      backgroundColor: Colors.green,
    );
  }

  /// 显示错误消息（红色背景，显示时间更长）
  ///
  /// [message] 消息内容
  static void showError(String message) {
    showSnackBar(
      message,
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 5),
    );
  }

  /// 显示警告消息（橙色背景）
  ///
  /// [message] 消息内容
  static void showWarning(String message) {
    showSnackBar(
      message,
      backgroundColor: Colors.orange,
    );
  }

  /// 显示信息消息（蓝色背景）
  ///
  /// [message] 消息内容
  static void showInfo(String message) {
    showSnackBar(
      message,
      backgroundColor: Colors.blue,
    );
  }
}
