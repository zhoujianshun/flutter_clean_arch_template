import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

/// 基于 EasyLoading 的加载弹窗工具类
///
/// 提供统一的加载状态显示接口，支持自定义加载指示器、遮罩类型等
/// 适用于需要显示加载状态的场景，如网络请求、数据处理等
class MyPopLoading {
  /// 显示加载弹窗
  ///
  /// [status] 加载状态文本，如 "加载中..."、"处理中..." 等
  /// [indicator] 自定义加载指示器，默认为系统默认
  /// [maskType] 遮罩类型，默认为 clear（透明遮罩）
  /// [dismissOnTap] 是否点击遮罩关闭，默认为 false
  static void show({
    String? status,
    Widget? indicator,
    EasyLoadingMaskType? maskType,
    bool? dismissOnTap,
  }) {
    EasyLoading.show(
      status: status,
      indicator: indicator,
      maskType: maskType ?? EasyLoadingMaskType.clear,
      dismissOnTap: dismissOnTap ?? false,
    );
  }

  /// 显示全屏加载弹窗
  ///
  /// 与 [show] 方法类似，但默认使用透明遮罩，提供更好的视觉体验
  ///
  /// [status] 加载状态文本
  /// [indicator] 自定义加载指示器
  /// [maskType] 遮罩类型，默认为 clear
  /// [dismissOnTap] 是否点击遮罩关闭，默认为 false
  static void showFull({
    String? status,
    Widget? indicator,
    EasyLoadingMaskType? maskType,
    bool? dismissOnTap,
  }) {
    EasyLoading.show(
      status: status,
      indicator: indicator,
      maskType: maskType ?? EasyLoadingMaskType.clear,
      dismissOnTap: dismissOnTap ?? false,
    );
  }

  /// 关闭加载弹窗
  ///
  /// [animation] 是否使用动画关闭，默认为 true
  static void dismiss({bool animation = true}) {
    EasyLoading.dismiss();
  }

  /// 检查是否正在显示加载弹窗
  static bool get isShow => EasyLoading.isShow;
}
