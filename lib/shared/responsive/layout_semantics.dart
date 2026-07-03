import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/shared/responsive/breakpoints.dart';

/// 页面层响应式语义决策。
///
/// 业务页面优先使用该层，而不是直接写宽度判断，
/// 便于统一策略和后续集中调整。
class LayoutSemantics {
  LayoutSemantics._();

  /// NavigationRail 标签显示策略：
  /// - expanded：全部显示
  /// - compact/medium：仅显示选中项
  static NavigationRailLabelType railLabelType(BoxConstraints constraints) {
    return ResponsiveBreakpoints.isExpanded(constraints)
        ? NavigationRailLabelType.all
        : NavigationRailLabelType.selected;
  }

  /// 主从分栏中左侧主面板的推荐宽度比例。
  static double masterPaneRatio(BoxConstraints constraints) {
    return ResponsiveBreakpoints.isExpanded(constraints) ? 0.35 : 0.4;
  }
}
