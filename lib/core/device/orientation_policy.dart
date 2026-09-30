import 'dart:async';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_clean_arch_template/shared/responsive/breakpoints.dart';

/// 屏幕方向策略（手机/平板分治）。
///
/// 默认策略：
/// - 手机（物理短边 < 600dp）：竖屏
/// - 平板及以上：全方向
///
/// 折叠屏支持：[applyAndObserve] 在应用方向策略的同时注册 metrics 监听，
/// 折叠↔展开导致判定结果翻转时自动重新应用方向策略。
///
/// 使用 [FlutterView.display] 获取物理屏幕尺寸（而非可能被 letterbox
/// 限制的 [FlutterView.physicalSize]），这是 Flutter 官方对方向锁定
/// 场景的推荐做法。
///
/// 注意：折叠屏/多形态设备上锁方向是 Flutter 官方认定的反模式，
/// 面向国际市场或深度适配折叠屏的项目建议 `lockPhonePortrait: false`。
class OrientationPolicy with WidgetsBindingObserver {
  OrientationPolicy({
    this.lockPhonePortrait = true,
  });

  /// 为 true 时，手机维持竖屏策略。
  final bool lockPhonePortrait;

  bool _observing = false;
  bool _isTabletOrLarger = false;

  /// 应用方向策略并开始监听后续尺寸变化（折叠/展开）。
  ///
  /// 调用 [dispose] 移除监听。重复调用安全（幂等）。
  Future<void> applyAndObserve(FlutterView view) async {
    await _evaluate(view);
    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
  }

  @override
  void didChangeMetrics() {
    unawaited(_evaluate(PlatformDispatcher.instance.views.first));
  }

  Future<void> _evaluate(FlutterView view) async {
    // 使用 Display API 获取物理屏幕尺寸。
    // FlutterView.physicalSize 在方向锁定 + letterbox 时可能不反映
    // 物理屏幕真实大小（折叠屏展开后仍返回折叠态尺寸）。
    final display = view.display;
    final shortestSide = display.size.shortestSide / display.devicePixelRatio;
    final isTabletOrLarger = shortestSide >= ResponsiveBreakpoints.compact;

    // 折叠→展开（compact→非 compact）或反向翻转时才重新应用；
    // 方向变更本身也会触发 didChangeMetrics，结果不变时跳过可防循环。
    if (_observing && isTabletOrLarger == _isTabletOrLarger) {
      return;
    }
    _isTabletOrLarger = isTabletOrLarger;

    if (isTabletOrLarger || !lockPhonePortrait) {
      await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      return;
    }

    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  /// 移除 metrics 监听。
  void dispose() {
    if (_observing) {
      WidgetsBinding.instance.removeObserver(this);
      _observing = false;
    }
  }
}
