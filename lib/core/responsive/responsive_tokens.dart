import 'package:flutter/widgets.dart';
import 'package:flutter_clean_arch_template/core/responsive/breakpoints.dart';
import 'package:flutter_clean_arch_template/core/responsive/constraints_scope.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 响应式设计 token（间距、字体、内容宽度等）。
///
/// Token-first 策略：
/// - compact（手机）允许按设计稿缩放；
/// - medium/expanded（平板）优先固定 dp，避免"大屏过度放大"。
///
/// ### 全局 vs 局部
///
/// **全局方法**（[rsize]/[rfont]/[size]/[font] 及扩展 `16.rs`/`14.rf`）：
/// 基于 [ScreenUtil] 全局窗口宽度做断点判定。适用于绝大多数手机页面。
///
/// **局部方法**（[localSize]/[localFont]）：
/// 基于 [ConstraintsScope]（由 `AdaptiveBuilder` 自动注入）的局部约束宽度
/// 做断点判定。适用于嵌套面板（NavigationRail 旁的内容区）或 Split View
/// 场景，此时全局窗口宽度不等于组件实际可用宽度。
/// 若 context 中无 [ConstraintsScope]，自动回退到全局行为。
class ResponsiveTokens {
  ResponsiveTokens._();

  // 设计稿尺寸。
  static const double phoneDesignWidth = 375;
  static const double phoneDesignHeight = 812;
  static const double tabletDesignWidth = 768;
  static const double tabletDesignHeight = 1024;

  // 内容最大宽度（按页面语义）。
  static const double maxWidthFormNarrow = 420;
  static const double maxWidthForm = 480;
  static const double maxWidthList = 600;
  static const double maxWidthDetail = 680;

  // 紧凑屏缩放保护范围。
  static const double minCompactScaleRatio = 0.85;
  static const double maxCompactScaleRatio = 1.15;
  static const double maxAdaptiveScaleRatio = 1.2;

  /// 全局窗口尺寸类（单一真值源，所有全局方法共用）。
  static WindowSizeClass get _globalWindowClass =>
      ResponsiveBreakpoints.fromWidth(ScreenUtil().screenWidth);

  static double _compactScale() {
    final scale = ScreenUtil().screenWidth / phoneDesignWidth;
    return scale.clamp(minCompactScaleRatio, maxCompactScaleRatio);
  }

  /// 手机端紧凑缩放。
  ///
  /// 以 [phoneDesignWidth]（375dp）为基准计算缩放比，
  /// clamp 在 [minCompactScaleRatio]–[maxCompactScaleRatio]（0.85–1.15）之间。
  ///
  /// 仅用于确定运行在手机端的间距/尺寸值；
  /// 平板端请使用 dp 直接量或 [tw]。
  ///
  /// 快捷写法：`16.rc`（通过 [ResponsiveNumExtension]）。
  static double compact(num value) => value * _compactScale();

  /// 自适应宽度值——解决 ScreenUtil `.w` 在大屏上过度放大的问题。
  ///
  /// 以 [phoneDesignWidth]（375dp）为基准，缩放比 clamp 在
  /// [minCompactScaleRatio]–[maxAdaptiveScaleRatio]（0.85–1.2）之间。
  /// 与 [compact] 的区别在于上限更宽松（1.2 vs 1.15），
  /// 适用于手机端代码可能在大屏显示的场景。
  ///
  /// 快捷写法：`16.rw`（通过 [ResponsiveNumExtension]）。
  static double aw(num value) {
    final scale = ScreenUtil().screenWidth / phoneDesignWidth;
    final clampedScale = scale.clamp(
      minCompactScaleRatio,
      maxAdaptiveScaleRatio,
    );
    return value * clampedScale;
  }

  /// 平板设计稿缩放值。
  ///
  /// 以 [tabletDesignWidth]（768dp）为基准，缩放比 clamp 在 0.8–1.3 之间：
  /// - 下限 0.8：容忍略窄于 768dp 的窗口（如 600–768dp 的展开态折叠屏）
  /// - 上限 1.3：约覆盖 768→1000dp 的常见平板横屏区间，更宽则不再放大
  /// 与 ScreenUtil `.w` 以手机 375dp 为基准是对称关系。
  /// **仅在有平板独立设计稿时使用**；若无独立设计稿，直接用 dp 值。
  ///
  /// 快捷写法：`20.rt`（通过 [ResponsiveNumExtension]）。
  static double tw(num tabletDesignValue) {
    final scale = ScreenUtil().screenWidth / tabletDesignWidth;
    return tabletDesignValue * scale.clamp(0.8, 1.3);
  }

  /// 按断点返回尺寸值（**不缩放**）。
  ///
  /// 所有断点均直接返回传入的 dp 值，compact 端**不做**缩放。
  /// 适用于主题定义、全局样式等不需要按屏幕尺寸缩放的场景。
  ///
  /// 如果 compact 端需要按设计稿缩放，请使用 [rsize]。
  ///
  /// 快捷写法：`16.s`（通过 [ResponsiveNumExtension]）。
  static double size(num compactValue, {double? medium, double? expanded}) {
    return _resolveByWindowClass(
      _globalWindowClass,
      compactValue,
      compactTransform: (v) => v.toDouble(),
      medium: medium,
      expanded: expanded,
    );
  }

  /// 按断点返回字体值（**不缩放**）。
  ///
  /// 所有断点均直接返回传入的 dp 值，compact 端**不做** sp 缩放。
  /// 适用于主题定义、全局字体样式等不需要按屏幕尺寸缩放的场景。
  ///
  /// 如果 compact 端需要 ScreenUtil sp 缩放，请使用 [rfont]。
  ///
  /// 快捷写法：`14.f`（通过 [ResponsiveNumExtension]）。
  static double font(num compactValue, {double? medium, double? expanded}) {
    return _resolveByWindowClass(
      _globalWindowClass,
      compactValue,
      compactTransform: (v) => v.toDouble(),
      medium: medium,
      expanded: expanded,
    );
  }

  /// 按断点返回尺寸值（compact 端**带缩放**）。
  ///
  /// - compact：通过 [compact] 方法按设计稿宽度缩放（clamp 0.85–1.15）
  /// - medium/expanded：优先使用固定 dp（传入的 [medium]/[expanded]）
  ///
  /// 适用于页面布局中的间距、尺寸等需要跟随屏幕适配的值。
  /// 如果不需要缩放（如主题定义），请使用 [size]。
  ///
  /// 快捷写法：`16.rs`（通过 [ResponsiveNumExtension]）。
  static double rsize(num compactValue, {double? medium, double? expanded}) {
    return _resolveByWindowClass(
      _globalWindowClass,
      compactValue,
      compactTransform: compact,
      medium: medium,
      expanded: expanded,
    );
  }

  /// 按断点返回字体值（compact 端**带 sp 缩放**）。
  ///
  /// - compact：通过 [ScreenUtil.setSp] 按字体缩放策略处理
  /// - medium/expanded：使用固定 dp（防止字体在平板过大）
  ///
  /// 适用于页面内的文字，需要跟随 ScreenUtil 字体适配。
  /// 如果不需要缩放（如主题定义），请使用 [font]。
  ///
  /// 快捷写法：`14.rf`（通过 [ResponsiveNumExtension]）。
  static double rfont(num compactValue, {double? medium, double? expanded}) {
    return _resolveByWindowClass(
      _globalWindowClass,
      compactValue,
      compactTransform: (v) => ScreenUtil().setSp(v.toDouble()),
      medium: medium,
      expanded: expanded,
    );
  }

  // ---------------------------------------------------------------------------
  // 局部约束感知方法（context-aware）
  // ---------------------------------------------------------------------------

  /// 基于局部约束的尺寸值（compact 端**条件缩放**）。
  ///
  /// 从 [ConstraintsScope.maybeOf] 读取 `AdaptiveBuilder` 注入的局部约束宽度
  /// 做断点判定。若 context 中无 [ConstraintsScope]，回退到全局 [rsize]。
  ///
  /// 适用于嵌套面板（NavigationRail 旁的内容区）或 Split View 场景，
  /// 此时全局窗口宽度不等于组件实际可用宽度。
  ///
  /// ### 缩放策略
  ///
  /// - **全局 compact + 局部 compact**（真手机）：按设计稿缩放（[compact]）
  /// - **全局非 compact + 局部 compact**（大屏窄面板）：固定 dp，不缩放
  ///
  /// 这样确保大屏上的窄面板不会因为全局窗口宽度被过度放大。
  ///
  /// ```dart
  /// // 在 AdaptiveBuilder 的子树中
  /// final padding = ResponsiveTokens.localSize(context, 16, medium: 24);
  /// ```
  static double localSize(
    BuildContext context,
    num compactValue, {
    double? medium,
    double? expanded,
  }) {
    final scope = ConstraintsScope.maybeOf(context);
    if (scope == null) {
      return rsize(compactValue, medium: medium, expanded: expanded);
    }

    final isGloballyCompact = _globalWindowClass == WindowSizeClass.compact;
    return _resolveByWindowClass(
      scope.windowClass,
      compactValue,
      compactTransform: isGloballyCompact ? compact : (v) => v.toDouble(),
      medium: medium,
      expanded: expanded,
    );
  }

  /// 基于局部约束的字体值（compact 端**条件缩放**）。
  ///
  /// 与 [localSize] 类似，但全局 compact 时使用 [ScreenUtil.setSp]。
  /// 全局非 compact 时（大屏窄面板），字体不缩放，直接返回固定 dp。
  /// 若 context 中无 [ConstraintsScope]，回退到全局 [rfont]。
  static double localFont(
    BuildContext context,
    num compactValue, {
    double? medium,
    double? expanded,
  }) {
    final scope = ConstraintsScope.maybeOf(context);
    if (scope == null) {
      return rfont(compactValue, medium: medium, expanded: expanded);
    }

    final isGloballyCompact = _globalWindowClass == WindowSizeClass.compact;
    return _resolveByWindowClass(
      scope.windowClass,
      compactValue,
      compactTransform: isGloballyCompact
          ? (v) => ScreenUtil().setSp(v.toDouble())
          : (v) => v.toDouble(),
      medium: medium,
      expanded: expanded,
    );
  }

  /// 按 [WindowSizeClass] 解析值，渐进回退。
  ///
  /// 回退语义（P0-1 回归测试锁定）：medium/expanded 缺失时回退到
  /// **原始** [compactValue]（未缩放），而非 [compactTransform] 的缩放结果。
  static double _resolveByWindowClass(
    WindowSizeClass windowClass,
    num compactValue, {
    required double Function(num) compactTransform,
    double? medium,
    double? expanded,
  }) {
    if (windowClass == WindowSizeClass.compact) {
      return compactTransform(compactValue);
    }
    return ResponsiveBreakpoints.resolve(
      windowClass: windowClass,
      compact: compactValue.toDouble(),
      medium: medium,
      expanded: expanded,
    );
  }
}

/// [ResponsiveTokens] 的 `num` 快捷扩展。
///
/// 命名以 `r` 前缀（responsive）开头，与 ScreenUtil 的 `.w`/`.sp` 区分。
/// 不带 `r` 前缀的 `.s`/`.f` 对应不缩放版本，用于主题/全局配置。
///
/// | Extension | 等价调用 | compact 端 | 说明 |
/// |-----------|---------|-----------|------|
/// | `16.rs` | `ResponsiveTokens.rsize(16)` | 缩放 | 页面间距（带缩放） |
/// | `14.rf` | `ResponsiveTokens.rfont(14)` | sp 缩放 | 页面字体（带缩放） |
/// | `16.s` | `ResponsiveTokens.size(16)` | 不缩放 | 主题/全局尺寸 |
/// | `14.f` | `ResponsiveTokens.font(14)` | 不缩放 | 主题/全局字体 |
/// | `16.rw` | `ResponsiveTokens.aw(16)` | clamp 1.2 | 自适应宽度 |
/// | `20.rt` | `ResponsiveTokens.tw(20)` | clamp 1.3 | 平板设计稿缩放 |
/// | `16.rc` | `ResponsiveTokens.compact(16)` | clamp 1.15 | 手机端紧凑缩放 |
///
/// 需要为不同断点指定不同值时，使用静态方法：
/// ```dart
/// ResponsiveTokens.rsize(16, medium: 24, expanded: 32)
/// ```
///
/// 嵌套面板等局部约束场景，使用 context-aware 方法：
/// ```dart
/// ResponsiveTokens.localSize(context, 16, medium: 24)
/// ```
extension ResponsiveNumExtension on num {
  /// 页面响应式尺寸（compact 带缩放）——[ResponsiveTokens.rsize] 的快捷写法。
  double get rs => ResponsiveTokens.rsize(this);

  /// 页面响应式字体（compact 带 sp 缩放）——[ResponsiveTokens.rfont] 的快捷写法。
  double get rf => ResponsiveTokens.rfont(this);

  /// 主题/全局尺寸（不缩放）——[ResponsiveTokens.size] 的快捷写法。
  double get s => ResponsiveTokens.size(this);

  /// 主题/全局字体（不缩放）——[ResponsiveTokens.font] 的快捷写法。
  double get f => ResponsiveTokens.font(this);

  /// 自适应宽度——[ResponsiveTokens.aw] 的快捷写法。
  double get rw => ResponsiveTokens.aw(this);

  /// 平板设计稿缩放——[ResponsiveTokens.tw] 的快捷写法。
  double get rt => ResponsiveTokens.tw(this);

  /// 手机端紧凑缩放——[ResponsiveTokens.compact] 的快捷写法。
  double get rc => ResponsiveTokens.compact(this);
}
