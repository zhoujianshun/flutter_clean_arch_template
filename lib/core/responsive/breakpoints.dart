import 'package:flutter/material.dart';

/// 窗口尺寸类（采用 M3 compact/medium/expanded 三档）。
///
/// M3 完整规范包含 compact / medium / expanded / large / extra-large 五档。
/// 本项目当前面向手机/平板场景，仅使用前三档；large / extra-large 暂归入
/// expanded，后续可通过 [BreakpointConfig] 扩展。
enum WindowSizeClass { compact, medium, expanded }

/// 响应式断点判定工具（单一入口）。
///
/// ### API 选择指南
///
/// - **页面 / 局部布局**：优先使用 [fromConstraints] 或 [valueOf]
///   （基于 `LayoutBuilder` 的有界约束，代表实际可用宽度）。
/// - **窗口级策略**（如 AppShell 导航形态）：使用 [fromWindowSize] 或 [windowValueOf]
///   （基于 `MediaQuery` 的完整窗口宽度）。
///
/// 所有需要 [BuildContext] 的方法均从 [BreakpointConfig] 读取自定义断点阈值
///（不存在时使用默认值 600/840）。不要在页面内使用 [fromWindowSize] 做布局
/// 分支——窗口宽度不等于扣除 SafeArea、NavigationRail 等后的实际内容宽度。
class ResponsiveBreakpoints {
  ResponsiveBreakpoints._();

  /// 默认紧凑断点：< 600dp
  static const double compact = 600;

  /// 默认扩展断点：>= 840dp
  static const double expanded = 840;

  /// 按默认断点分类（纯函数，不依赖 context）。
  ///
  /// 仅用于无法获取 [BuildContext] 的底层场景（如 `main.dart` 的
  /// `fontSizeResolver` 回调）。页面/组件代码请使用 [fromConstraints]
  /// 或 [fromWindowSize]，它们会读取 [BreakpointConfig] 的自定义阈值。
  static WindowSizeClass fromWidth(double width) {
    if (width >= expanded) return WindowSizeClass.expanded;
    if (width >= compact) return WindowSizeClass.medium;
    return WindowSizeClass.compact;
  }

  /// 已触发过无界宽度警告的调用位置（避免每帧刷屏）。
  @visibleForTesting
  static final Set<int> unboundedWarningHashes = {};

  /// 从 [BoxConstraints] 判定尺寸类（读取 [BreakpointConfig] 自定义阈值）。
  ///
  /// 无界宽度在 debug 模式下通过 [FlutterError.reportError] 输出一次性
  /// 静默警告，运行时回退为 [WindowSizeClass.compact]。
  static WindowSizeClass fromConstraints(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    if (!constraints.hasBoundedWidth) {
      assert(() {
        final hash = StackTrace.current.hashCode;
        if (unboundedWarningHashes.add(hash)) {
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: FlutterError(
                'ResponsiveBreakpoints.fromConstraints: 收到无界宽度约束，回退为 compact。\n'
                '请检查是否将断点判定放入了横向可滚动或无界子树中。\n'
                '建议使用外层有界 LayoutBuilder 的约束，或改用 tryFromConstraints。',
              ),
              library: 'responsive',
              silent: true,
            ),
          );
        }
        return true;
      }(), 'Unbounded width detected');
      return WindowSizeClass.compact;
    }
    return BreakpointConfig.of(context).classify(constraints.maxWidth);
  }

  /// 从 [BoxConstraints] 判定尺寸类，无界宽度时返回 null。
  ///
  /// 适用于调用方需要区分"真正的 compact"和"无法判定"的场景。
  static WindowSizeClass? tryFromConstraints(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    if (!constraints.hasBoundedWidth) return null;
    return BreakpointConfig.of(context).classify(constraints.maxWidth);
  }

  /// 从窗口宽度判定尺寸类。
  ///
  /// **仅用于窗口级策略**（如 AppShell 导航形态选择）。
  /// 页面/组件布局请使用 [fromConstraints]，基于实际可用宽度判定。
  static WindowSizeClass fromWindowSize(BuildContext context) {
    return BreakpointConfig.of(
      context,
    ).classify(MediaQuery.sizeOf(context).width);
  }

  /// 约束宽度 < compact 阈值。
  static bool isCompact(BuildContext context, BoxConstraints constraints) =>
      fromConstraints(context, constraints) == WindowSizeClass.compact;

  /// 约束宽度在 compact–expanded 阈值之间。
  static bool isMedium(BuildContext context, BoxConstraints constraints) =>
      fromConstraints(context, constraints) == WindowSizeClass.medium;

  /// 约束宽度 >= expanded 阈值。
  static bool isExpanded(BuildContext context, BoxConstraints constraints) =>
      fromConstraints(context, constraints) == WindowSizeClass.expanded;

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
  /// 读取 [BreakpointConfig] 的自定义阈值。
  /// medium 缺失时回退到 compact（而非 expanded），
  /// 避免 600dp 窗口使用为 840dp+ 设计的布局导致溢出。
  static T valueOf<T>(
    BuildContext context,
    BoxConstraints constraints, {
    required T compactValue,
    T? mediumValue,
    T? expandedValue,
  }) {
    return resolve(
      windowClass: fromConstraints(context, constraints),
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

/// 可注入的响应式断点配置。
///
/// 纯数据容器，持有断点阈值和布局参数。
/// [ResponsiveBreakpoints] 的所有需要 [BuildContext] 的方法
/// 均从此处读取自定义阈值。
///
/// 通过 [BreakpointConfig.of] 从 widget 树中读取最近的配置，
/// 不存在时返回使用默认值构造的实例。
///
/// ```dart
/// // 在 App 顶层注入自定义配置（可选）
/// BreakpointConfig(
///   compactBreakpoint: 640,
///   expandedBreakpoint: 900,
///   minPaneWidth: 320,
///   child: MaterialApp(...),
/// )
/// ```
class BreakpointConfig extends InheritedWidget {
  const BreakpointConfig({
    required super.child,
    super.key,
    this.compactBreakpoint = ResponsiveBreakpoints.compact,
    this.expandedBreakpoint = ResponsiveBreakpoints.expanded,
    this.minPaneWidth = 300,
  }) : assert(
         compactBreakpoint < expandedBreakpoint,
         'compactBreakpoint must be less than expandedBreakpoint',
       );

  /// compact → medium 阈值（dp）。
  final double compactBreakpoint;

  /// medium → expanded 阈值（dp）。
  final double expandedBreakpoint;

  /// 分栏布局中单个 pane 的最小宽度（dp）。
  final double minPaneWidth;

  /// 按此配置的阈值将宽度分类为 [WindowSizeClass]。
  ///
  /// 纯函数，仅基于自身字段做分类。
  /// [ResponsiveBreakpoints] 的各方法内部委托此方法。
  WindowSizeClass classify(double width) {
    if (width >= expandedBreakpoint) return WindowSizeClass.expanded;
    if (width >= compactBreakpoint) return WindowSizeClass.medium;
    return WindowSizeClass.compact;
  }

  /// 从 widget 树中读取最近的 [BreakpointConfig]。
  ///
  /// 不存在时返回使用默认值构造的实例（等价于默认阈值 600/840）。
  static BreakpointConfig of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<BreakpointConfig>() ??
        const BreakpointConfig(child: SizedBox.shrink());
  }

  /// 从 widget 树中读取，不存在时返回 null。
  static BreakpointConfig? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<BreakpointConfig>();
  }

  @override
  bool updateShouldNotify(BreakpointConfig oldWidget) {
    return compactBreakpoint != oldWidget.compactBreakpoint ||
        expandedBreakpoint != oldWidget.expandedBreakpoint ||
        minPaneWidth != oldWidget.minPaneWidth;
  }
}

// ---------------------------------------------------------------------------
// BuildContext 响应式扩展
// ---------------------------------------------------------------------------

/// BuildContext 的响应式扩展。
///
/// 读取的是**窗口级**宽度（`MediaQuery.sizeOf`），
/// 适用于壳层和全局策略。页面/组件布局应使用
/// `ConstraintsScope` 或 `AdaptiveBuilder` 的局部约束。
///
/// 使用 [BreakpointConfig] 的自定义断点（不存在时使用默认值）。
///
/// 布局决策应基于**可用宽度**（通过断点判定），而非设备方向。
/// Flutter 和 Apple 均明确建议：不要用 orientation 做布局分支。
/// iPhone Duo 内屏不遵循 app 声明的方向，orientation 不是可靠信号。
extension ResponsiveContextX on BuildContext {
  /// 当前窗口尺寸类（使用 [BreakpointConfig] 断点）。
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
