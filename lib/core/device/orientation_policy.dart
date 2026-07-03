import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_clean_arch_template/shared/responsive/breakpoints.dart';

/// 屏幕方向策略（手机/平板分治）。
///
/// 默认策略：
/// - 手机：竖屏
/// - 平板：全方向
class OrientationPolicy {
  const OrientationPolicy({
    this.lockPhonePortrait = true,
  });

  /// 为 true 时，手机维持竖屏策略。
  final bool lockPhonePortrait;

  Future<void> apply(FlutterView view) async {
    final shortestSide = view.physicalSize.shortestSide / view.devicePixelRatio;
    final isTabletOrLarger = shortestSide >= ResponsiveBreakpoints.compact;

    if (isTabletOrLarger || !lockPhonePortrait) {
      await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      return;
    }

    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
}
