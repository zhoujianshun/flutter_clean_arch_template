import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/core/responsive/breakpoints.dart';

/// 页面层响应式语义决策。
///
/// 业务页面优先使用该层，而不是直接写宽度判断，
/// 便于统一策略和后续集中调整。
///
/// 所有方法通过 [ResponsiveBreakpoints] 读取 [BreakpointConfig] 断点，
/// 注入自定义配置后语义决策自动跟随。
class LayoutSemantics {
  LayoutSemantics._();

  /// NavigationRail 标签显示策略：
  /// - expanded：全部显示
  /// - compact/medium：仅显示选中项
  static NavigationRailLabelType railLabelType(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    return ResponsiveBreakpoints.isExpanded(context, constraints)
        ? NavigationRailLabelType.all
        : NavigationRailLabelType.selected;
  }

  /// 主从分栏中左侧主面板的推荐宽度比例。
  static double masterPaneRatio(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    return ResponsiveBreakpoints.isExpanded(context, constraints) ? 0.35 : 0.4;
  }
}
