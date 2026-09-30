import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/shared/responsive/breakpoints.dart';

/// 自适应布局构建器
///
/// 基于 [LayoutBuilder] 的父组件约束宽度，在不同断点返回不同的子组件。
/// 内部使用 [ResponsiveBreakpoints] 的断点常量（compact < 600dp, expanded >= 840dp）。
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
        final windowClass = ResponsiveBreakpoints.fromConstraints(constraints);
        return switch (windowClass) {
          WindowSizeClass.expanded =>
            expanded ?? medium ?? compact,
          WindowSizeClass.medium =>
            medium ?? compact,
          WindowSizeClass.compact => compact,
        };
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
        final windowClass = ResponsiveBreakpoints.fromConstraints(constraints);
        final builder = switch (windowClass) {
          WindowSizeClass.expanded =>
            expanded ?? medium ?? compact,
          WindowSizeClass.medium =>
            medium ?? compact,
          WindowSizeClass.compact => compact,
        };
        return builder(constraints);
      },
    );
  }
}

/// 有状态的自适应布局构建器
///
/// 与 [AdaptiveBuilder] 相同的断点和渐进回退逻辑，
/// 但使用 [IndexedStack] 保持已构建子组件的状态。
/// 断点切换时切换显示而非销毁重建。
///
/// **适用场景**：同一子树在不同断点下复用（如旋转屏幕保持滚动位置）。
///
/// **不适用**：compact 和 medium 是两套独立表单组件——`IndexedStack`
/// 只保持各自状态，不会在两套表单之间迁移输入内容。
/// 跨布局共享表单数据请将状态上提到 Controller 或 Provider。
///
/// 注意：所有断点子组件同时存在于内存中，不适合包含重资源的页面。
/// 如果不需要状态保持，优先使用更轻量的 [AdaptiveBuilder]。
///
/// ```dart
/// StatefulAdaptiveBuilder(
///   compact: CompactForm(),
///   medium: MediumForm(), // 与 CompactForm 共享 TextEditingController
/// )
/// ```
class StatefulAdaptiveBuilder extends StatelessWidget {
  const StatefulAdaptiveBuilder({
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
        // 只构建实际存在的不同子组件，避免重复挂载同一实例
        final children = <Widget>[compact];
        if (medium != null) children.add(medium!);
        if (expanded != null) children.add(expanded!);

        // 断点 → children 下标（与 AdaptiveBuilder 渐进回退一致）
        final index = switch (ResponsiveBreakpoints.fromConstraints(constraints)) {
          WindowSizeClass.expanded => expanded != null ? children.length - 1 : (medium != null ? 1 : 0),
          WindowSizeClass.medium => medium != null ? 1 : 0,
          WindowSizeClass.compact => 0,
        };

        return IndexedStack(index: index, children: children);
      },
    );
  }
}
