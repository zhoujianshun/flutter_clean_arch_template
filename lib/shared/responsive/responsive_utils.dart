import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 响应式工具类
///
/// 对齐 Material 3 窗口尺寸类（Window Size Classes），提供两套辅助方法：
///
/// 1. **基于 [BoxConstraints]（推荐）**：配合 [LayoutBuilder] 使用，
///    响应父组件的实际约束而非全屏宽度，折叠屏/分屏友好。
///
/// 2. **基于 [BuildContext]**：使用 [MediaQuery] 获取全屏宽度，
///    适用于无法获取 [BoxConstraints] 的场景（如主题配置、导航策略）。
///
/// 断点定义：
/// - **compact**（紧凑）：< 600dp —— 手机、小窗口
/// - **medium**（中等）：600-839dp —— 平板竖屏、折叠屏展开
/// - **expanded**（扩展）：>= 840dp —— 平板横屏、桌面
class ResponsiveUtils {
  ResponsiveUtils._();

  // ── 断点常量 ──────────────────────────────────────────────────────────

  /// 紧凑断点：< 600dp 为手机
  static const double compactBreakpoint = 600;

  /// 扩展断点：>= 840dp 为平板横屏/桌面（对齐 Material 3）
  static const double expandedBreakpoint = 840;

  // ── 内容最大宽度常量 ──────────────────────────────────────────────────
  //
  // 在大屏设备上，内容不应铺满全宽，需要用 ContentConstraint 限制。
  // 以下常量按页面类型分组，提供语义化的宽度值，避免在业务代码中出现魔法数字。

  /// 窄表单宽度（登录/注册表单、搜索框等单列输入场景）
  static const double maxWidthFormNarrow = 420;

  /// 标准表单宽度（带标签的表单、编辑页等）
  static const double maxWidthForm = 480;

  /// 列表/设置页宽度（个人中心、设置列表、单列信息流等）
  static const double maxWidthList = 600;

  /// 详情/阅读宽度（文章详情、商品详情、长文内容等）
  static const double maxWidthDetail = 680;

  // ── 设计稿尺寸 ────────────────────────────────────────────────────

  /// 手机端设计稿宽度
  static const double phoneDesignWidth = 375;

  /// 手机端设计稿高度
  static const double phoneDesignHeight = 812;

  /// 平板端设计稿宽度（有平板独立设计稿时使用）
  static const double tabletDesignWidth = 768;

  /// 平板端设计稿高度
  static const double tabletDesignHeight = 1024;

  // ── 自适应缩放 ────────────────────────────────────────────────────

  /// .w 缩放比上限（大屏最多放大 20%）
  static const double maxScaleRatio = 1.2;

  /// 自适应宽度值（Adaptive Width）
  ///
  /// 手机端（缩放比 <= [maxScaleRatio]）行为与 `.w` 一致；
  /// 大屏端 clamp 缩放比至 [maxScaleRatio]，防止间距/尺寸过大。
  ///
  /// 适用场景：手机端页面代码中，想用 `.w` 但担心在大屏/分屏场景下值过大时。
  ///
  /// ```dart
  /// // 替代 16.w，大屏上最大为 16 * 1.2 = 19.2
  /// SizedBox(width: ResponsiveUtils.aw(16))
  /// Padding(padding: EdgeInsets.all(ResponsiveUtils.aw(12)))
  /// ```
  static double aw(num value) {
    final scale = ScreenUtil().screenWidth / phoneDesignWidth;
    final clampedScale = scale.clamp(0.8, maxScaleRatio);
    return value * clampedScale;
  }

  /// 平板端自适应宽度值（Tablet Width）
  ///
  /// 根据平板设计稿宽度（[tabletDesignWidth] = 768dp）计算缩放值。
  /// 缩放比 clamp 在 0.8-1.3 范围内，避免极端值。
  ///
  /// 适用场景：手机和平板有两套独立设计稿时，在 `AdaptiveBuilder` 的
  /// medium/expanded 回调中，按平板设计稿的标注值做缩放。
  ///
  /// 如果平板没有独立设计稿，直接使用 dp 值即可，不需要此方法。
  ///
  /// ```dart
  /// AdaptiveLayoutBuilder(
  ///   compact: (_) => Padding(padding: EdgeInsets.all(16.w)),           // 手机稿 16
  ///   medium: (_) => Padding(padding: EdgeInsets.all(ResponsiveUtils.tw(20))),  // 平板稿 20
  /// )
  /// ```
  static double tw(num tabletDesignValue) {
    final scale = ScreenUtil().screenWidth / tabletDesignWidth;
    return tabletDesignValue * scale.clamp(0.8, 1.3);
  }

  // ── 基于约束的断点判断 ──────────────────────────────────────────────

  /// 是否为紧凑布局（手机）：可用宽度 < 600dp
  static bool isCompact(BoxConstraints constraints) =>
      constraints.maxWidth < compactBreakpoint;

  /// 是否为中等布局（平板竖屏）：可用宽度 600-839dp
  static bool isMedium(BoxConstraints constraints) =>
      constraints.maxWidth >= compactBreakpoint &&
      constraints.maxWidth < expandedBreakpoint;

  /// 是否为扩展布局（平板横屏/桌面）：可用宽度 >= 840dp
  static bool isExpanded(BoxConstraints constraints) =>
      constraints.maxWidth >= expandedBreakpoint;

  /// 根据约束宽度返回对应的值
  ///
  /// 回退规则：expanded 未提供时用 medium，medium 未提供时用 compact。
  ///
  /// ```dart
  /// LayoutBuilder(
  ///   builder: (context, constraints) {
  ///     final columns = ResponsiveUtils.valueOf(
  ///       constraints,
  ///       compact: 1,
  ///       medium: 2,
  ///       expanded: 3,
  ///     );
  ///     return GridView(..., crossAxisCount: columns);
  ///   },
  /// )
  /// ```
  static T valueOf<T>(
    BoxConstraints constraints, {
    required T compact,
    T? medium,
    T? expanded,
  }) {
    if (isExpanded(constraints) && expanded != null) return expanded;
    if (isMedium(constraints) && medium != null) return medium;
    return compact;
  }

  /// 列表布局建议列数：compact=1, medium=2, expanded=3
  static int gridColumns(BoxConstraints constraints) =>
      valueOf(constraints, compact: 1, medium: 2, expanded: 3);

  /// 商品/图片等网格建议列数：compact=2, medium=3, expanded=4
  static int itemGridColumns(BoxConstraints constraints) =>
      valueOf(constraints, compact: 2, medium: 3, expanded: 4);

  // ── 基于 Context 的断点判断 ────────────────────────────────────────
  //
  // 使用 MediaQuery 获取全屏宽度。适用于无法获取 BoxConstraints 的场景，
  // 如主题配置、导航策略、fontSizeResolver 等。
  // 页面布局切换优先使用上面基于约束的方法。

  /// 是否为紧凑屏幕（手机）：屏幕宽度 < 600dp
  static bool isCompactScreen(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compactBreakpoint;

  /// 是否为中等屏幕（平板竖屏）：屏幕宽度 600-839dp
  static bool isMediumScreen(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= compactBreakpoint && width < expandedBreakpoint;
  }

  /// 是否为扩展屏幕（平板横屏/桌面）：屏幕宽度 >= 840dp
  static bool isExpandedScreen(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= expandedBreakpoint;

  /// 根据屏幕宽度返回对应的值
  ///
  /// 回退规则：expanded 未提供时用 medium，medium 未提供时用 compact。
  ///
  /// ```dart
  /// final padding = ResponsiveUtils.screenValueOf(
  ///   context,
  ///   compact: 16.w,
  ///   medium: 32,
  ///   expanded: 48,
  /// );
  /// ```
  static T screenValueOf<T>(
    BuildContext context, {
    required T compact,
    T? medium,
    T? expanded,
  }) {
    if (isExpandedScreen(context) && expanded != null) return expanded;
    if (!isCompactScreen(context) && medium != null) return medium;
    return compact;
  }
}
