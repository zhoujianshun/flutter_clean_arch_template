import 'package:flutter/widgets.dart';
import 'package:flutter_clean_arch_template/core/responsive/adaptive_builder.dart';
import 'package:flutter_clean_arch_template/core/responsive/breakpoints.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 响应式设计 token（间距、字体、内容宽度等）。
///
/// Token-first 策略：
/// - compact（手机）允许按设计稿缩放；
/// - medium/expanded（平板）优先固定 dp，避免"大屏过度放大"。
///
/// ### ScreenUtil 依赖契约
///
/// - [space] 的 compact 缩放基于窗口级 MediaQuery 宽度，**不依赖** ScreenUtil。
/// - [font] 的 compact 缩放委托 `ScreenUtil().setSp`（保留根部
///   `ScreenUtilInit` 注入的 `fontSizeResolver` 语义），**要求根部已接线
///   `ScreenUtilInit`**；未接线时回退固定 dp 并输出一次性 debug 警告。
///
/// ### 用法：`ResponsiveTokens.of(context)`
///
/// 基于局部约束（[ConstraintsScope]）和 [BreakpointConfig] 自定义断点
/// 做断点判定。适用于所有场景，包括嵌套面板。
///
/// ```dart
/// final tokens = ResponsiveTokens.of(context);
/// final padding = tokens.space(16, medium: 24, expanded: 32);
/// final fontSize = tokens.font(14, medium: 16);
/// ```
@immutable
class ResponsiveTokens {
  /// 用于 [of] 返回的上下文感知实例。
  const ResponsiveTokens._({
    required this.windowClass,
    required this.isGloballyCompact,
    required this.globalWindowWidth,
  });

  /// 当前（局部或全局）窗口尺寸类。
  final WindowSizeClass windowClass;

  /// 全局窗口是否为 compact（用于区分"真手机"和"大屏窄面板"）。
  final bool isGloballyCompact;

  /// 全局窗口宽度（dp，来自 `MediaQuery.sizeOf`）。
  ///
  /// 供 compact 缩放计算使用。与 `ScreenUtil().screenWidth` 同源等价
  /// （`ScreenUtilInit` 内部即以窗口级 MediaQuery configure），
  /// 此处直接读取以消除对 ScreenUtil 单例的依赖。
  final double globalWindowWidth;

  // -------------------------------------------------------------------------
  // 设计稿与常量
  // -------------------------------------------------------------------------

  /// 手机设计稿宽度。
  static const double phoneDesignWidth = 375;

  /// 手机设计稿高度。
  static const double phoneDesignHeight = 812;

  /// 平板设计稿宽度。
  static const double tabletDesignWidth = 768;

  /// 平板设计稿高度。
  static const double tabletDesignHeight = 1024;

  /// 内容最大宽度（窄表单）。
  static const double maxWidthFormNarrow = 420;

  /// 内容最大宽度（标准表单）。
  static const double maxWidthForm = 480;

  /// 内容最大宽度（列表语义）。
  static const double maxWidthList = 600;

  /// 内容最大宽度（详情语义）。
  static const double maxWidthDetail = 680;

  /// 紧凑屏缩放保护范围。
  static const double minCompactScaleRatio = 0.85;

  /// 紧凑屏缩放保护范围。
  static const double maxCompactScaleRatio = 1.15;

  // -------------------------------------------------------------------------
  // 推荐 API：context-aware 实例
  // -------------------------------------------------------------------------

  /// 获取上下文感知的响应式 token 实例。
  ///
  /// 优先使用 `ConstraintsScope`（由 `AdaptiveBuilder` 自动注入）的局部
  /// 约束宽度做断点判定；不存在时使用 [BreakpointConfig] + 窗口宽度。
  ///
  /// ```dart
  /// final tokens = ResponsiveTokens.of(context);
  /// final padding = tokens.space(16, medium: 24);
  /// final fontSize = tokens.font(14, medium: 16);
  /// ```
  static ResponsiveTokens of(BuildContext context) {
    final scope = ConstraintsScope.maybeOf(context);
    final config = BreakpointConfig.of(context);
    final globalWindowWidth = MediaQuery.sizeOf(context).width;
    final globalClass = config.classify(globalWindowWidth);
    final windowClass = scope?.windowClass ?? globalClass;
    final isGloballyCompact = globalClass == WindowSizeClass.compact;

    return ResponsiveTokens._(
      windowClass: windowClass,
      isGloballyCompact: isGloballyCompact,
      globalWindowWidth: globalWindowWidth,
    );
  }

  /// 按断点返回间距/尺寸值。
  ///
  /// - compact + 全局 compact（真手机）：按设计稿缩放（clamp 0.85–1.15），
  ///   缩放基于窗口级 MediaQuery 宽度，不依赖 ScreenUtil
  /// - compact + 全局非 compact（大屏窄面板）：固定 dp，不缩放
  /// - medium/expanded：优先使用传入的固定 dp 值
  double space(double compact, {double? medium, double? expanded}) {
    if (windowClass == WindowSizeClass.compact) {
      return isGloballyCompact ? _compact(compact) : compact;
    }
    return ResponsiveBreakpoints.resolve(
      windowClass: windowClass,
      compact: compact,
      medium: medium,
      expanded: expanded,
    );
  }

  /// 按断点返回字体值。
  ///
  /// - compact + 全局 compact（真手机）：通过 `ScreenUtil().setSp` 缩放
  ///   （保留根部 `ScreenUtilInit` 注入的 `fontSizeResolver` 语义）；
  ///   根部未接线 `ScreenUtilInit` 时回退固定 dp 并输出一次性 debug 警告
  /// - compact + 全局非 compact（大屏窄面板）：固定 dp，不缩放
  /// - medium/expanded：优先使用传入的固定 dp 值
  double font(double compact, {double? medium, double? expanded}) {
    if (windowClass == WindowSizeClass.compact) {
      return isGloballyCompact ? _setSpSafe(compact) : compact;
    }
    return ResponsiveBreakpoints.resolve(
      windowClass: windowClass,
      compact: compact,
      medium: medium,
      expanded: expanded,
    );
  }

  /// 按断点返回固定 dp 值（所有断点均不缩放）。
  ///
  /// 适用于主题定义、全局样式等不需要按屏幕尺寸缩放的场景。
  double fixedSize(double compact, {double? medium, double? expanded}) {
    return ResponsiveBreakpoints.resolve(
      windowClass: windowClass,
      compact: compact,
      medium: medium,
      expanded: expanded,
    );
  }

  // -------------------------------------------------------------------------
  // 内部工具
  // -------------------------------------------------------------------------

  /// compact 缩放比（基于全局窗口宽度，clamp 0.85–1.15）。
  double _compactScale() {
    final scale = globalWindowWidth / phoneDesignWidth;
    return scale.clamp(minCompactScaleRatio, maxCompactScaleRatio);
  }

  double _compact(num value) => value * _compactScale();

  /// 已告警过的调用位置（避免每帧刷屏）。
  @visibleForTesting
  static final Set<int> screenUtilMissingWarningHashes = {};

  /// 委托 `ScreenUtil().setSp`，根部未接线 `ScreenUtilInit` 时安全回退。
  ///
  /// ScreenUtil 的内部字段为 `late` 且无公开初始化探针，未初始化时访问
  /// 会抛 late 初始化错误。该错误类型未公开导出（VM 上为 `LateError`，
  /// dart2js 上为 `dart:internal` 的 `LateInitializationError`），无法按
  /// 类型引用到 on-catch 子句，故捕获 `Error` 后按 runtimeType 名称过滤；
  /// 命中时回退固定 dp，并按调用点哈希去重输出一次性 debug 警告。
  static double _setSpSafe(double value) {
    try {
      return ScreenUtil().setSp(value);
      // ignore: avoid_catching_errors, late 初始化错误类型未公开导出，无法按类型捕获，详见上方注释
    } on Error catch (e) {
      final typeName = e.runtimeType.toString();
      final isLateInitError =
          typeName == 'LateError' || typeName == 'LateInitializationError';
      if (!isLateInitError) rethrow;
      assert(() {
        final hash = StackTrace.current.hashCode;
        if (screenUtilMissingWarningHashes.add(hash)) {
          debugPrint(
            'ResponsiveTokens.font: ScreenUtil 未初始化（根部缺少 ScreenUtilInit），'
            ' 已回退为固定 dp，字体将不按设计稿缩放；'
            ' 如需启用 compact 字体缩放，请在 App 根部接线 ScreenUtilInit。',
          );
        }
        return true;
      }(), 'ScreenUtil missing guard');
      return value;
    }
  }
}
