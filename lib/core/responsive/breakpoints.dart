import 'package:flutter/material.dart';

/// 窗口尺寸类（采用 M3 compact/medium/expanded 三个阈值的子集）。
///
/// 用于手机/平板场景：
/// - compact: 小屏（< 600dp）
/// - medium: 中屏（600-839dp）
/// - expanded: 大屏（>= 840dp）
///
/// desktop / 超宽屏暂统一归入 expanded，后续可通过 [ResponsivePolicy] 扩展。
enum WindowSizeClass { compact, medium, expanded }

/// 响应式断点与判定工具（单一真值源）。
///
/// ### API 选择指南
///
/// - **页面 / 局部布局**：优先使用 [fromConstraints] 或 [valueOf]
///   （基于 `LayoutBuilder` 的有界约束，代表实际可用宽度）。
/// - **窗口级策略**（如 AppShell 导航形态）：使用 [fromWindowSize] 或 [windowValueOf]
///   （基于 `MediaQuery` 的完整窗口宽度）。
///
/// 不要在页面内使用 [fromWindowSize] 做布局分支——窗口宽度不等于
/// 扣除 SafeArea、NavigationRail 等后的实际内容宽度。
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

  /// 从 [BoxConstraints] 判定尺寸类。
  ///
  /// 无界宽度在 debug 模式下输出警告，提示调用方应使用外层有界约束。
  /// 运行时回退为 [WindowSizeClass.compact]。
  static WindowSizeClass fromConstraints(BoxConstraints constraints) {
    if (!constraints.hasBoundedWidth) {
      assert(() {
        debugPrint(
          'ResponsiveBreakpoints.fromConstraints: 收到无界宽度约束，回退为 compact。'
          '\n请检查是否将断点判定放入了横向可滚动或无界子树中。'
          '\n建议使用外层有界 LayoutBuilder 的约束，或改用 tryFromConstraints。',
        );
        return true;
      }(), 'Unbounded width should not be used for breakpoint detection');
      return WindowSizeClass.compact;
    }
    return fromWidth(constraints.maxWidth);
  }

  /// 从 [BoxConstraints] 判定尺寸类，无界宽度时返回 null。
  ///
  /// 适用于调用方需要区分"真正的 compact"和"无法判定"的场景。
  static WindowSizeClass? tryFromConstraints(BoxConstraints constraints) {
    if (!constraints.hasBoundedWidth) return null;
    return fromWidth(constraints.maxWidth);
  }

  /// 从窗口宽度判定尺寸类。
  ///
  /// **仅用于窗口级策略**（如 AppShell 导航形态选择）。
  /// 页面/组件布局请使用 [fromConstraints]，基于实际可用宽度判定。
  static WindowSizeClass fromWindowSize(BuildContext context) {
    return fromWidth(MediaQuery.sizeOf(context).width);
  }

  static bool isCompact(BoxConstraints constraints) =>
      fromConstraints(constraints) == WindowSizeClass.compact;

  static bool isMedium(BoxConstraints constraints) =>
      fromConstraints(constraints) == WindowSizeClass.medium;

  static bool isExpanded(BoxConstraints constraints) =>
      fromConstraints(constraints) == WindowSizeClass.expanded;

  /// 窗口级判定——是否为紧凑窗口。
  ///
  /// 仅用于壳层/全局策略。页面布局请使用 [isCompact]。
  static bool isCompactWindow(BuildContext context) =>
      fromWindowSize(context) == WindowSizeClass.compact;

  /// 窗口级判定——是否为中等窗口。
  ///
  /// 仅用于壳层/全局策略。页面布局请使用 [isMedium]。
  static bool isMediumWindow(BuildContext context) =>
      fromWindowSize(context) == WindowSizeClass.medium;

  /// 窗口级判定——是否为扩展窗口。
  ///
  /// 仅用于壳层/全局策略。页面布局请使用 [isExpanded]。
  static bool isExpandedWindow(BuildContext context) =>
      fromWindowSize(context) == WindowSizeClass.expanded;

  /// 按窗口尺寸类解析值，渐进回退（expanded→medium→compact）。
  ///
  /// 回退链的唯一真值源：medium 缺失时回退到 compact（而非 expanded），
  /// 避免 600dp 窗口使用为 840dp+ 设计的布局导致溢出。
  /// [valueOf]/[windowValueOf]、AdaptiveBuilder 系列与 ResponsiveTokens
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

  /// 按约束断点返回对应值，渐进回退（expanded→medium→compact）。
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
  ///
  /// **仅用于窗口级策略**。页面布局请使用 [valueOf]。
  static T windowValueOf<T>(
    BuildContext context, {
    required T compactValue,
    T? mediumValue,
    T? expandedValue,
  }) {
    return resolve(
      windowClass: fromWindowSize(context),
      compact: compactValue,
      medium: mediumValue,
      expanded: expandedValue,
    );
  }
}

/// 可注入的响应式策略配置。
///
/// 允许不同品牌/产品线自定义断点、最小 pane 宽度和导航阈值，
/// 替代全局 `static const` 硬编码。
///
/// 通过 [ResponsivePolicy.of] 从 widget 树中读取最近的策略，
/// 不存在时返回使用默认值构造的实例。
///
/// ```dart
/// // 在 App 顶层注入自定义策略
/// ResponsivePolicy(
///   compactBreakpoint: 640,
///   expandedBreakpoint: 900,
///   minPaneWidth: 320,
///   child: MaterialApp(...),
/// )
/// ```
class ResponsivePolicy extends InheritedWidget {
  const ResponsivePolicy({
    required super.child,
    super.key,
    this.compactBreakpoint = ResponsiveBreakpoints.compact,
    this.expandedBreakpoint = ResponsiveBreakpoints.expanded,
    this.minPaneWidth = 300,
    this.navigationThreshold = ResponsiveBreakpoints.compact,
  });

  /// 默认 compact → medium 阈值。
  static const double defaultCompactBreakpoint = ResponsiveBreakpoints.compact;

  /// 默认 medium → expanded 阈值。
  static const double defaultExpandedBreakpoint = ResponsiveBreakpoints.expanded;

  /// compact → medium 阈值（dp）。
  final double compactBreakpoint;

  /// medium → expanded 阈值（dp）。
  final double expandedBreakpoint;

  /// 分栏布局中单个 pane 的最小宽度（dp）。
  final double minPaneWidth;

  /// 切换到 NavigationRail 的窗口最小宽度（dp）。
  final double navigationThreshold;

  /// 从 widget 树中读取最近的 [ResponsivePolicy]。
  ///
  /// 不存在时返回使用默认值构造的实例（等价于全局常量）。
  static ResponsivePolicy of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ResponsivePolicy>() ??
        const ResponsivePolicy(child: SizedBox.shrink());
  }

  /// 从 widget 树中读取，不存在时返回 null。
  static ResponsivePolicy? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ResponsivePolicy>();
  }

  @override
  bool updateShouldNotify(ResponsivePolicy oldWidget) {
    return compactBreakpoint != oldWidget.compactBreakpoint ||
        expandedBreakpoint != oldWidget.expandedBreakpoint ||
        minPaneWidth != oldWidget.minPaneWidth ||
        navigationThreshold != oldWidget.navigationThreshold;
  }
}
