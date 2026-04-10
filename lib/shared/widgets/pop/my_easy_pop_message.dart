import 'dart:async';

import 'package:flutter_easyloading/flutter_easyloading.dart';

/// 基于 EasyLoading 的 Toast 提示工具类
///
/// 提供统一的 Toast 消息显示接口，包括成功、错误、信息和普通提示
/// 支持自定义显示时长、遮罩类型和点击关闭行为
class MyEasyPopMessage {
  /// 默认显示时长
  static const Duration _defaultDuration = Duration(milliseconds: 1500);

  /// 显示成功提示
  ///
  /// [status] 提示文本内容
  /// [duration] 显示时长，默认为 1.5 秒
  /// [maskType] 遮罩类型，默认为 none
  /// [dismissOnTap] 是否点击关闭，默认为 true
  static Future<void> showSuccess(
    String status, {
    Duration? duration,
    EasyLoadingMaskType? maskType,
    bool? dismissOnTap,
  }) {
    if (status.isEmpty) {
      throw ArgumentError('提示文本不能为空');
    }

    return EasyLoading.showSuccess(
      status,
      duration: duration ?? _defaultDuration,
      maskType: maskType ?? EasyLoadingMaskType.none,
      dismissOnTap: dismissOnTap ?? true,
    );
  }

  static void showSuccessUnawaited(
    String status, {
    Duration? duration,
    EasyLoadingMaskType? maskType,
    bool? dismissOnTap,
  }) {
    unawaited(showSuccess(status, duration: duration, maskType: maskType, dismissOnTap: dismissOnTap));
  }

  /// 显示错误提示
  ///
  /// [status] 错误提示文本内容
  /// [duration] 显示时长，默认为 1.5 秒
  /// [maskType] 遮罩类型，默认为 none
  /// [dismissOnTap] 是否点击关闭，默认为 true
  static Future<void> showError(
    String status, {
    Duration? duration,
    EasyLoadingMaskType? maskType,
    bool? dismissOnTap,
  }) {
    if (status.isEmpty) {
      throw ArgumentError('错误提示文本不能为空');
    }

    return EasyLoading.showError(
      status,
      duration: duration ?? _defaultDuration,
      maskType: maskType ?? EasyLoadingMaskType.none,
      dismissOnTap: dismissOnTap ?? true,
    );
  }

  static void showErrorUnawaited(
    String status, {
    Duration? duration,
    EasyLoadingMaskType? maskType,
    bool? dismissOnTap,
  }) {
    unawaited(showError(status, duration: duration, maskType: maskType, dismissOnTap: dismissOnTap));
  }

  /// 显示信息提示
  ///
  /// [status] 信息提示文本内容
  /// [duration] 显示时长，默认为 1.5 秒
  /// [maskType] 遮罩类型，默认为 none
  /// [dismissOnTap] 是否点击关闭，默认为 true
  static Future<void> showInfo(
    String status, {
    Duration? duration,
    EasyLoadingMaskType? maskType,
    bool? dismissOnTap,
  }) {
    if (status.isEmpty) {
      throw ArgumentError('信息提示文本不能为空');
    }

    return EasyLoading.showInfo(
      status,
      duration: duration ?? _defaultDuration,
      maskType: maskType ?? EasyLoadingMaskType.none,
      dismissOnTap: dismissOnTap ?? true,
    );
  }

  static void showInfoUnawaited(
    String status, {
    Duration? duration,
    EasyLoadingMaskType? maskType,
    bool? dismissOnTap,
  }) {
    unawaited(showInfo(status, duration: duration, maskType: maskType, dismissOnTap: dismissOnTap));
  }

  /// 显示普通 Toast 提示
  ///
  /// [status] Toast 文本内容
  /// [duration] 显示时长，默认为 1.5 秒
  /// [maskType] 遮罩类型，默认为 none
  /// [dismissOnTap] 是否点击关闭，默认为 true
  static Future<void> showToast(
    String status, {
    Duration? duration,
    EasyLoadingMaskType? maskType,
    bool? dismissOnTap,
  }) {
    if (status.isEmpty) {
      throw ArgumentError('Toast 文本不能为空');
    }

    return EasyLoading.showToast(
      status,
      duration: duration ?? _defaultDuration,
      maskType: maskType ?? EasyLoadingMaskType.none,
      dismissOnTap: dismissOnTap ?? true,
    );
  }

  static void showToastUnawaited(
    String status, {
    Duration? duration,
    EasyLoadingMaskType? maskType,
    bool? dismissOnTap,
  }) {
    unawaited(showToast(status, duration: duration, maskType: maskType, dismissOnTap: dismissOnTap));
  }

  /// 手动关闭所有 Toast
  static Future<void> dismiss() {
    return EasyLoading.dismiss();
  }

  static void dismissUnawaited() {
    unawaited(dismiss());
  }
}
