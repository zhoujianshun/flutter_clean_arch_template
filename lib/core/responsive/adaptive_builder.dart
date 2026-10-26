import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/core/responsive/breakpoints.dart';

/// 自适应布局构建器
///
/// 基于 [LayoutBuilder] 的父组件约束宽度，在不同断点返回不同的子组件。
/// 断点阈值来自 [BreakpointConfig]（默认 compact < 600dp, expanded >= 840dp）。
///
/// 渐进回退规则（大→小安全降级）：
/// - expanded 宽度但 [expanded] 为 null → [medium] → [compact]
/// - medium 宽度但 [medium] 为 null → [compact]
///
/// ```dart
/// // 基础用法：手机和平板两种布局
/// AdaptiveBuilder(
///   compact: MobileLayout(),      // < 600dp
///   medium: TabletLayout(),       // >= 600dp（expanded 也会回退到此）
/// )
///
/// // 三种布局
/// AdaptiveBuilder(
///   compact: PhoneLayout(),       // < 600dp
///   medium: TabletLayout(),       // 600-839dp
///   expanded: DesktopLayout(),    // >= 840dp
/// )
/// ```
class AdaptiveBuilder extends StatelessWidget {
  const AdaptiveBuilder({
    required this.compact,
    super.key,
    this.medium,
    this.expanded,
  });

  /// 紧凑布局（手机），宽度 < 600dp
  final Widget compact;

  /// 中等布局（平板竖屏），宽度 600-839dp
  final Widget? medium;

  /// 扩展布局（平板横屏/桌面），宽度 >= 840dp
  final Widget? expanded;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final windowClass = ResponsiveBreakpoints.fromConstraints(
          context,
          constraints,
        );
        final child = ResponsiveBreakpoints.resolve<Widget>(
          windowClass: windowClass,
          compact: compact,
          medium: medium,
          expanded: expanded,
        );
        return ConstraintsScope(
          constraints: constraints,
          windowClass: windowClass,
          child: child,
        );
      },
    );
  }
}

/// 自适应布局构建器（Builder 回调版本）
///
/// 与 [AdaptiveBuilder] 相同的断点和渐进回退逻辑，
/// 但通过回调传递 [BoxConstraints]，
/// 允许子组件根据约束值做进一步的布局计算（如分栏比例、宽度值等）。
///
/// 使用场景：
/// - 子组件需要 `constraints` 来决定分栏宽度、flex 比例等
/// - 需要区分 medium / expanded 做细粒度调整
///
/// 如果子组件不需要 `constraints`，优先使用更简洁的 [AdaptiveBuilder]。
///
/// ```dart
/// // 需要 constraints 计算分栏宽度
/// AdaptiveLayoutBuilder(
///   compact: (_) => MobileList(),
///   medium: (c) => SplitLayout(masterWidth: c.maxWidth * 0.4),
/// )
///
/// // 三级布局，子组件使用 constraints 做判断
/// AdaptiveLayoutBuilder(
///   compact: (_) => CompactView(),
///   medium: (c) => MediumView(constraints: c),
///   expanded: (c) => ExpandedView(constraints: c),
/// )
/// ```
class AdaptiveLayoutBuilder extends StatelessWidget {
  const AdaptiveLayoutBuilder({
    required this.compact,
    super.key,
    this.medium,
    this.expanded,
  });

  /// 紧凑布局构建器（手机），宽度 < 600dp
  final Widget Function(BoxConstraints constraints) compact;

  /// 中等布局构建器（平板竖屏），宽度 600-839dp
  final Widget Function(BoxConstraints constraints)? medium;

  /// 扩展布局构建器（平板横屏/桌面），宽度 >= 840dp
  final Widget Function(BoxConstraints constraints)? expanded;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final windowClass = ResponsiveBreakpoints.fromConstraints(
          context,
          constraints,
        );
        final builder = ResponsiveBreakpoints.resolve(
          windowClass: windowClass,
          compact: compact,
          medium: medium,
          expanded: expanded,
        );
        return ConstraintsScope(
          constraints: constraints,
          windowClass: windowClass,
          child: builder(constraints),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// 约束作用域
// ---------------------------------------------------------------------------

/// 向子树注入当前 [LayoutBuilder] 约束和窗口尺寸类。
///
/// 由 [AdaptiveBuilder] / [AdaptiveLayoutBuilder]
/// 在 [LayoutBuilder] 回调内自动注入，无需手动创建。
///
/// 子树中的组件可通过 [ConstraintsScope.of] 读取**局部**约束宽度，
/// 用于比全局 `ScreenUtil` 更精确的断点判定（如 NavigationRail 旁的内容面板、
/// iPhone Duo Split View 中的半屏窗口等）。
///
/// ```dart
/// // 在 AdaptiveBuilder 的子树中
/// final scope = ConstraintsScope.of(context);
/// final isLocallyCompact = scope.windowClass == WindowSizeClass.compact;
/// ```
class ConstraintsScope extends InheritedWidget {
  const ConstraintsScope({
    required this.constraints,
    required this.windowClass,
    required super.child,
    super.key,
  });

  /// 当前子树的父级约束。
  final BoxConstraints constraints;

  /// 基于 [constraints] 计算的窗口尺寸类。
  final WindowSizeClass windowClass;

  /// 当前子树的可用宽度（`constraints.maxWidth`）。
  ///
  /// 无界宽度时返回 [double.infinity]，调用方应处理此情况。
  double get localWidth =>
      constraints.hasBoundedWidth ? constraints.maxWidth : double.infinity;

  /// 从最近的祖先读取，不存在时抛出 [FlutterError]。
  ///
  /// 如需安全访问，请使用 [maybeOf]。
  static ConstraintsScope of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ConstraintsScope>();
    if (scope == null) {
      throw FlutterError.fromParts([
        ErrorSummary(
          'ConstraintsScope.of() called without a ConstraintsScope ancestor.',
        ),
        ErrorDescription(
          'No ConstraintsScope was found in the widget tree above this context. '
          'ConstraintsScope is automatically injected by AdaptiveBuilder, '
          'AdaptiveLayoutBuilder, or FoldAwareBuilder.',
        ),
        ErrorHint(
          'Ensure the widget calling ConstraintsScope.of() is inside an '
          'AdaptiveBuilder or AdaptiveLayoutBuilder subtree, '
          'or use ConstraintsScope.maybeOf() for a nullable result.',
        ),
        context.describeElement('The context used was'),
      ]);
    }
    return scope;
  }

  /// 从最近的 [ConstraintsScope] 祖先读取，不存在时返回 null。
  static ConstraintsScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ConstraintsScope>();
  }

  @override
  bool updateShouldNotify(ConstraintsScope oldWidget) {
    // 刻意比较完整 constraints 而非仅宽度：constraints 是公开字段，
    // 消费方可能读取任意维度（如 maxHeight）。仅比较宽度会漏掉高度变化，
    // 引入正确性风险；多出的重建成本在 Flutter 的 rebuild 模型下可忽略。
    // 请勿将此比较"优化"为仅比较宽度。
    return constraints != oldWidget.constraints;
  }
}
