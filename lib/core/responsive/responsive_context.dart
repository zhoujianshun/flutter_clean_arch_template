import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/core/responsive/breakpoints.dart';

/// BuildContext 的响应式扩展。
///
/// 读取的是**窗口级**宽度（`MediaQuery.sizeOf`），
/// 适用于壳层和全局策略。页面/组件布局应使用
/// `ConstraintsScope` 或 `AdaptiveBuilder` 的局部约束。
///
/// 布局决策应基于**可用宽度**（通过断点判定），而非设备方向。
/// Flutter 和 Apple 均明确建议：不要用 orientation 做布局分支。
/// iPhone Duo 内屏不遵循 app 声明的方向，orientation 不是可靠信号。
extension ResponsiveContextX on BuildContext {
  WindowSizeClass get windowSizeClass =>
      ResponsiveBreakpoints.fromWindowSize(this);

  bool get isCompactWindow => windowSizeClass == WindowSizeClass.compact;

  bool get isMediumWindow => windowSizeClass == WindowSizeClass.medium;

  bool get isExpandedWindow => windowSizeClass == WindowSizeClass.expanded;

  /// 安全区是否不对称（左右 padding 不同）。
  ///
  /// 在 iPhone Duo 内屏横屏模式下，系统垂直控件条带占据一侧（通常是右侧
  /// ~84dp），导致 `MediaQuery.padding` 左右不对称。
  /// 使用此属性判断是否需要逐侧处理 padding，避免 `EdgeInsets.symmetric`。
  ///
  /// 示例：
  /// ```dart
  /// if (context.hasAsymmetricHorizontalPadding) {
  ///   final p = MediaQuery.paddingOf(context);
  ///   // 逐侧处理：p.left 和 p.right 分别应用
  /// }
  /// ```
  bool get hasAsymmetricHorizontalPadding {
    final p = MediaQuery.paddingOf(this);
    return p.left != p.right;
  }
}
