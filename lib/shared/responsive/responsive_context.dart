import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/shared/responsive/breakpoints.dart';

/// BuildContext 的响应式扩展。
///
/// 用于在页面中更语义化地读取窗口尺寸类。
extension ResponsiveContextX on BuildContext {
  WindowSizeClass get windowSizeClass =>
      ResponsiveBreakpoints.fromContext(this);

  bool get isCompactWindow => windowSizeClass == WindowSizeClass.compact;

  bool get isMediumWindow => windowSizeClass == WindowSizeClass.medium;

  bool get isExpandedWindow => windowSizeClass == WindowSizeClass.expanded;
}
