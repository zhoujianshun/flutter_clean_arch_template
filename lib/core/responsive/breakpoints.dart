import 'package:flutter/material.dart';

/// 窗口尺寸类（对齐 Material 3）。
///
/// 用于手机/平板场景：
/// - compact: 小屏
/// - medium: 中屏
/// - expanded: 大屏
enum WindowSizeClass { compact, medium, expanded }

/// 响应式断点与判定工具（单一真值源）。
///
/// 建议：
/// - 页面/局部布局：优先使用 `BoxConstraints` 系列方法
/// - 全局壳层判定：使用 `BuildContext` 系列方法
class ResponsiveBreakpoints {
  ResponsiveBreakpoints._();

  /// 紧凑断点：< 600dp
  static const double compact = 600;

  /// 扩展断点：>= 840dp
  static const double expanded = 840;

  static WindowSizeClass fromWidth(double width) {
    if (width >= expanded) return WindowSizeClass.expanded;
    if (width >= compact) return WindowSizeClass.medium;
    return WindowSizeClass.compact;
  }

  static WindowSizeClass fromConstraints(BoxConstraints constraints) {
    if (!constraints.hasBoundedWidth) return WindowSizeClass.compact;
    return fromWidth(constraints.maxWidth);
  }

  static WindowSizeClass fromContext(BuildContext context) {
    return fromWidth(MediaQuery.sizeOf(context).width);
  }

  static bool isCompact(BoxConstraints constraints) =>
      fromConstraints(constraints) == WindowSizeClass.compact;

  static bool isMedium(BoxConstraints constraints) =>
      fromConstraints(constraints) == WindowSizeClass.medium;

  static bool isExpanded(BoxConstraints constraints) =>
      fromConstraints(constraints) == WindowSizeClass.expanded;

  static bool isCompactScreen(BuildContext context) =>
      fromContext(context) == WindowSizeClass.compact;

  static bool isMediumScreen(BuildContext context) =>
      fromContext(context) == WindowSizeClass.medium;

  static bool isExpandedScreen(BuildContext context) =>
      fromContext(context) == WindowSizeClass.expanded;

  /// 按窗口尺寸类解析值，渐进回退（expanded→medium→compact）。
  ///
  /// 回退链的唯一真值源：medium 缺失时回退到 compact（而非 expanded），
  /// 避免 600dp 窗口使用为 840dp+ 设计的布局导致溢出。
  /// [valueOf]/[screenValueOf]、AdaptiveBuilder 系列与 ResponsiveTokens
  /// 系列均委托此方法，保证回退策略全局一致。
  static T resolve<T>({
    required WindowSizeClass windowClass,
    required T compact,
    T? medium,
    T? expanded,
  }) {
    return switch (windowClass) {
      WindowSizeClass.expanded => expanded ?? medium ?? compact,
      WindowSizeClass.medium => medium ?? compact,
      WindowSizeClass.compact => compact,
    };
  }

  /// 按断点返回对应值，渐进回退（expanded→medium→compact）。
  ///
  /// medium 缺失时回退到 compact（而非 expanded），
  /// 避免 600dp 窗口使用为 840dp+ 设计的布局导致溢出。
  static T valueOf<T>(
    BoxConstraints constraints, {
    required T compactValue,
    T? mediumValue,
    T? expandedValue,
  }) {
    return resolve(
      windowClass: fromConstraints(constraints),
      compact: compactValue,
      medium: mediumValue,
      expanded: expandedValue,
    );
  }

  /// 按窗口宽度返回对应值，渐进回退（expanded→medium→compact）。
  static T screenValueOf<T>(
    BuildContext context, {
    required T compactValue,
    T? mediumValue,
    T? expandedValue,
  }) {
    return resolve(
      windowClass: fromContext(context),
      compact: compactValue,
      medium: mediumValue,
      expanded: expandedValue,
    );
  }
}
