import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 响应式工具类
///
/// 对齐 Material 3 窗口尺寸类（Window Size Classes），提供两套辅助方法：
///
/// 1. **基于 [BoxConstraints]（推荐）**：配合 [LayoutBuilder] 使用，
///    响应父组件的实际约束而非全屏宽度，折叠屏/分屏友好。
///
/// 2. **基于 [BuildContext]（兼容）**：使用 [MediaQuery]，
///    适用于无法获取 [BoxConstraints] 的场景（如主题配置）。
///
/// 断点定义：
/// - **compact**（紧凑）：< 600dp —— 手机、小窗口
/// - **medium**（中等）：600-1023dp —— 平板竖屏、折叠屏展开
/// - **expanded**（扩展）：>= 1024dp —— 平板横屏、桌面
class ResponsiveUtils {
  ResponsiveUtils._();

  // ── 断点常量 ──────────────────────────────────────────────────────────

  /// 紧凑断点：< 600dp 为手机
  static const double compactBreakpoint = 600;

  /// 扩展断点：>= 1024dp 为平板横屏/桌面
  static const double expandedBreakpoint = 1024;

  /// 兼容旧代码的别名
  static const double mobileBreakpoint = compactBreakpoint;
  static const double tabletBreakpoint = expandedBreakpoint;
  static const double desktopBreakpoint = 1440;

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

  // ── 基于约束的断点判断（推荐） ──────────────────────────────────────

  /// 是否为紧凑布局（手机）：可用宽度 < 600dp
  static bool isCompact(BoxConstraints constraints) =>
      constraints.maxWidth < compactBreakpoint;

  /// 是否为中等布局（平板竖屏）：可用宽度 600-1023dp
  static bool isMedium(BoxConstraints constraints) =>
      constraints.maxWidth >= compactBreakpoint &&
      constraints.maxWidth < expandedBreakpoint;

  /// 是否为扩展布局（平板横屏/桌面）：可用宽度 >= 1024dp
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

  // ── 基于 Context 的断点判断（兼容旧代码） ──────────────────────────

  /// 是否为手机（屏幕宽度 < 600dp）
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compactBreakpoint;

  /// 是否为平板（屏幕宽度 600-1023dp）
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= compactBreakpoint && width < expandedBreakpoint;
  }

  /// 是否为桌面（屏幕宽度 >= 1024dp）
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= expandedBreakpoint;

  /// 是否为小屏设备（<= 375dp）
  static bool isSmallScreen(BuildContext context) =>
      MediaQuery.sizeOf(context).width <= 375;

  /// 是否为大屏设备（>= 768dp）
  static bool isLargeScreen(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 768;

  /// 根据屏幕宽度返回对应的值
  ///
  /// ```dart
  /// final padding = ResponsiveUtils.responsiveValue(
  ///   context,
  ///   mobile: 16.w,
  ///   tablet: 32,
  ///   desktop: 48,
  /// );
  /// ```
  static T responsiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context) && desktop != null) return desktop;
    if (isTablet(context) && tablet != null) return tablet;
    return mobile;
  }

  /// 列数（基于 Context）
  static int getColumns(BuildContext context) =>
      responsiveValue(context, mobile: 1, tablet: 2, desktop: 3);

  /// 网格列数（基于 Context）
  static int getGridColumns(BuildContext context) =>
      responsiveValue(context, mobile: 2, tablet: 3, desktop: 4);

  // ── 适老化配置 ────────────────────────────────────────────────────────

  /// 适老化字体缩放比例
  static double getElderlyFontScale(BuildContext context) =>
      isLargeScreen(context) ? 1.3 : 1.2;

  /// 适老化按钮最小高度
  static double getElderlyButtonHeight(BuildContext context) =>
      responsiveValue(context, mobile: 56.h, tablet: 64, desktop: 72);

  /// 适老化触摸目标最小尺寸
  static double getElderlyTouchTarget(BuildContext context) =>
      responsiveValue(context, mobile: 48.w, tablet: 56, desktop: 64);

  // ── 布局辅助 ──────────────────────────────────────────────────────────

  /// 内容最大宽度（防止在大屏上内容过宽）
  static double getMaxContentWidth(BuildContext context) =>
      responsiveValue(context, mobile: double.infinity, tablet: 768, desktop: 1200);

  /// 水平边距
  static double getHorizontalPadding(BuildContext context) =>
      responsiveValue(context, mobile: 16.w, tablet: 32, desktop: 48);

  /// 卡片间距
  static double getCardSpacing(BuildContext context) =>
      responsiveValue(context, mobile: 8.w, tablet: 12, desktop: 16);

  // ── 文字大小辅助 ──────────────────────────────────────────────────────

  /// 响应式标题大小（level 1-6）
  static double getHeadingSize(BuildContext context, int level) {
    final baseSizes = {
      1: responsiveValue(context, mobile: 28.sp, tablet: 32.sp, desktop: 36.sp),
      2: responsiveValue(context, mobile: 24.sp, tablet: 28.sp, desktop: 32.sp),
      3: responsiveValue(context, mobile: 20.sp, tablet: 24.sp, desktop: 28.sp),
      4: responsiveValue(context, mobile: 18.sp, tablet: 20.sp, desktop: 24.sp),
      5: responsiveValue(context, mobile: 16.sp, tablet: 18.sp, desktop: 20.sp),
      6: responsiveValue(context, mobile: 14.sp, tablet: 16.sp, desktop: 18.sp),
    };
    return baseSizes[level] ?? 16.sp;
  }

  /// 响应式正文大小
  static double getBodySize(BuildContext context, {bool isLarge = false}) {
    if (isLarge) {
      return responsiveValue(context, mobile: 16.sp, tablet: 18.sp, desktop: 20.sp);
    }
    return responsiveValue(context, mobile: 14.sp, tablet: 16.sp, desktop: 18.sp);
  }

  // ── 图标大小辅助 ──────────────────────────────────────────────────────

  /// 响应式图标大小
  static double getIconSize(BuildContext context, {bool isLarge = false}) {
    if (isLarge) {
      return responsiveValue(context, mobile: 32.w, tablet: 40, desktop: 48);
    }
    return responsiveValue(context, mobile: 24.w, tablet: 28, desktop: 32);
  }

  // ── 屏幕信息 ──────────────────────────────────────────────────────────

  /// 状态栏高度
  static double getStatusBarHeight(BuildContext context) =>
      MediaQuery.of(context).padding.top;

  /// 底部安全区域高度
  static double getBottomSafeArea(BuildContext context) =>
      MediaQuery.of(context).padding.bottom;

  /// 屏幕宽度
  static double getScreenWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  /// 屏幕高度
  static double getScreenHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).height;

  /// 可用高度（去除状态栏和底部安全区域）
  static double getAvailableHeight(BuildContext context) {
    final mq = MediaQuery.of(context);
    return mq.size.height - mq.padding.top - mq.padding.bottom;
  }

  // ── 方向检测 ──────────────────────────────────────────────────────────

  /// 是否为横屏
  static bool isLandscape(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.landscape;

  /// 是否为竖屏
  static bool isPortrait(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.portrait;

  // ── 调试工具 ──────────────────────────────────────────────────────────

  /// 打印屏幕信息（仅调试用）
  static void printScreenInfo(BuildContext context) {
    final mq = MediaQuery.of(context);
    debugPrint('=== 屏幕信息 ===');
    debugPrint('尺寸: ${mq.size.width} x ${mq.size.height}');
    debugPrint('像素比: ${mq.devicePixelRatio}');
    debugPrint('类型: ${isMobile(context) ? '手机' : isTablet(context) ? '平板' : '桌面'}');
    debugPrint('方向: ${isLandscape(context) ? '横屏' : '竖屏'}');
    debugPrint('状态栏: ${getStatusBarHeight(context)}');
    debugPrint('底部安全区: ${getBottomSafeArea(context)}');
    debugPrint('ScreenUtil 设计尺寸: ${1.sw} x ${1.sh}');
    debugPrint('================');
  }
}

/// 响应式构建器（基于 MediaQuery）
///
/// 根据屏幕宽度返回不同的子组件。
/// 如需基于父组件约束宽度切换，请使用 `AdaptiveBuilder`。
///
/// ```dart
/// ResponsiveBuilder(
///   mobile: MobileView(),
///   tablet: TabletView(),
///   desktop: DesktopView(),
/// )
/// ```
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    required this.mobile,
    super.key,
    this.tablet,
    this.desktop,
  });

  /// 手机布局（< 600dp）
  final Widget mobile;

  /// 平板布局（600-1023dp）
  final Widget? tablet;

  /// 桌面布局（>= 1024dp）
  final Widget? desktop;

  @override
  Widget build(BuildContext context) {
    return ResponsiveUtils.responsiveValue(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
}

/// LayoutBuilder 封装
///
/// 提供便捷的约束感知构建能力。
class ResponsiveLayoutBuilder extends StatelessWidget {
  const ResponsiveLayoutBuilder({
    required this.builder,
    super.key,
  });

  final Widget Function(BuildContext context, BoxConstraints constraints) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: builder);
  }
}

/// 适老化响应式组件
///
/// 为老年用户提供更大的字体和触摸目标。
///
/// ```dart
/// ElderlyResponsiveWidget(
///   fontScale: 1.3,
///   child: SettingsPage(),
/// )
/// ```
class ElderlyResponsiveWidget extends StatelessWidget {
  const ElderlyResponsiveWidget({
    required this.child,
    super.key,
    this.fontScale,
    this.enableLargeTouch = true,
  });

  final Widget child;

  /// 字体缩放比例，为 null 时自动根据屏幕大小选择
  final double? fontScale;

  /// 是否启用大触摸目标
  final bool enableLargeTouch;

  @override
  Widget build(BuildContext context) {
    final scale = fontScale ?? ResponsiveUtils.getElderlyFontScale(context);

    var result = child;

    result = MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(scale),
      ),
      child: result,
    );

    if (enableLargeTouch) {
      result = MaterialTapTargetSize.padded == Theme.of(context).materialTapTargetSize
          ? result
          : Theme(
              data: Theme.of(context).copyWith(
                materialTapTargetSize: MaterialTapTargetSize.padded,
              ),
              child: result,
            );
    }

    return result;
  }
}
