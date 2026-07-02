import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/shared/responsive/responsive_utils.dart';

/// 自适应布局构建器
///
/// 基于 [LayoutBuilder] 的父组件约束宽度，在不同断点返回不同的子组件。
/// 内部使用 [ResponsiveUtils] 的断点常量（compact < 600dp, expanded >= 1024dp）。
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
///   medium: TabletLayout(),       // 600-1023dp
///   expanded: DesktopLayout(),    // >= 1024dp
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

  /// 中等布局（平板竖屏），宽度 600-1023dp
  final Widget? medium;

  /// 扩展布局（平板横屏/桌面），宽度 >= 1024dp
  final Widget? expanded;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (ResponsiveUtils.isExpanded(constraints) && expanded != null) {
          return expanded!;
        }
        if (!ResponsiveUtils.isCompact(constraints)) {
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

  /// 中等布局构建器（平板竖屏），宽度 600-1023dp
  final Widget Function(BoxConstraints constraints)? medium;

  /// 扩展布局构建器（平板横屏/桌面），宽度 >= 1024dp
  final Widget Function(BoxConstraints constraints)? expanded;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (ResponsiveUtils.isExpanded(constraints) && expanded != null) {
          return expanded!(constraints);
        }
        if (!ResponsiveUtils.isCompact(constraints)) {
          final builder = medium ?? expanded ?? compact;
          return builder(constraints);
        }
        return compact(constraints);
      },
    );
  }
}
