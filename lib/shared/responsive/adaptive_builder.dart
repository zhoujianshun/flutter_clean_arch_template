import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/shared/responsive/breakpoints.dart';

/// 自适应布局构建器
///
/// 基于 [LayoutBuilder] 的父组件约束宽度，在不同断点返回不同的子组件。
/// 内部使用 [ResponsiveBreakpoints] 的断点常量（compact < 600dp, expanded >= 840dp）。
///
/// 回退规则：
/// - expanded 宽度但 [expanded] 为 null → 使用 [medium]
/// - medium 宽度但 [medium] 为 null → 使用 [expanded]（如有）或 [compact]
///
/// ```dart
/// // 基础用法：手机和平板两种布局
/// AdaptiveBuilder(
///   compact: MobileLayout(),      // < 600dp
///   medium: TabletLayout(),       // >= 600dp
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
        if (ResponsiveBreakpoints.isExpanded(constraints) && expanded != null) {
          return expanded!;
        }
        if (!ResponsiveBreakpoints.isCompact(constraints)) {
          return medium ?? expanded ?? compact;
        }
        return compact;
      },
    );
  }
}

/// 自适应布局构建器（Builder 回调版本）
///
/// 与 [AdaptiveBuilder] 相同的断点逻辑，但通过回调传递 [BoxConstraints]，
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
        if (ResponsiveBreakpoints.isExpanded(constraints) && expanded != null) {
          return expanded!(constraints);
        }
        if (!ResponsiveBreakpoints.isCompact(constraints)) {
          final builder = medium ?? expanded ?? compact;
          return builder(constraints);
        }
        return compact(constraints);
      },
    );
  }
}

/// 有状态的自适应布局构建器
///
/// 与 [AdaptiveBuilder] 相同的断点逻辑，但使用 [IndexedStack] 保持
/// 所有已构建的子组件状态。断点切换时切换显示而非销毁重建。
///
/// 适用场景：
/// - 包含表单输入的页面（旋转屏幕不丢失输入内容）
/// - 包含滚动列表的页面（旋转屏幕保持滚动位置）
///
/// 注意：所有断点的子组件会同时存在于内存中，不适合非常重的页面。
/// 如果不需要状态保持，优先使用更轻量的 [AdaptiveBuilder]。
///
/// ```dart
/// // 旋转屏幕后表单输入不丢失
/// StatefulAdaptiveBuilder(
///   compact: CompactForm(),
///   medium: MediumForm(),
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
        final children = <Widget>[
          compact,
          medium ?? expanded ?? compact,
          expanded ?? medium ?? compact,
        ];
        final index =
            ResponsiveBreakpoints.isExpanded(constraints) && expanded != null
            ? 2
            : !ResponsiveBreakpoints.isCompact(constraints) &&
                  (medium ?? expanded) != null
            ? 1
            : 0;
        return IndexedStack(index: index, children: children);
      },
    );
  }
}
