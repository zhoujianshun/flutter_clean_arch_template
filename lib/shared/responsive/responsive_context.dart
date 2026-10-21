import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/core/responsive/breakpoints.dart';

/// BuildContext 的响应式扩展。
///
/// 用于在页面中更语义化地读取窗口尺寸类。
extension ResponsiveContextX on BuildContext {
  WindowSizeClass get windowSizeClass =>
      ResponsiveBreakpoints.fromContext(this);

  bool get isCompactWindow => windowSizeClass == WindowSizeClass.compact;

  bool get isMediumWindow => windowSizeClass == WindowSizeClass.medium;

  bool get isExpandedWindow => windowSizeClass == WindowSizeClass.expanded;

  /// 当前是否处于横屏且宽度 >= medium 断点。
  ///
  /// 在此模式下，iPhone Duo 内屏和平板设备通常使用 [NavigationRail]
  /// 代替底部导航。iPhone Duo 的系统垂直控件条带会占据右侧 ~84dp。
  bool get isWideScreenLandscape {
    final mq = MediaQuery.of(this);
    return mq.size.width >= ResponsiveBreakpoints.compact &&
        mq.orientation == Orientation.landscape;
  }

  /// 安全区是否不对称（左右 padding 不同）。
  ///
  /// 在 iPhone Duo 内屏横屏模式下，系统垂直控件条带占据一侧（通常是右侧
  /// ~84dp），导致 [MediaQuery.padding] 左右不对称。
  /// 使用此属性判断是否需要逐侧处理 padding，避免 `EdgeInsets.symmetric`。
  bool get hasAsymmetricHorizontalPadding {
    final p = MediaQuery.paddingOf(this);
    return p.left != p.right;
  }
}
