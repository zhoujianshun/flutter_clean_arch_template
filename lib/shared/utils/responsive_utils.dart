import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 响应式工具类
///
/// 提供统一的响应式设计工具方法，包括：
/// - 屏幕尺寸判断
/// - 响应式布局辅助
/// - 设备类型检测
/// - 适老化响应式配置
class ResponsiveUtils {
  ResponsiveUtils._();

  // === 屏幕尺寸断点 ===
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;

  // === 设备类型判断 ===
  /// 是否为手机
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// 是否为平板
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// 是否为桌面
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  /// 是否为小屏设备（手机）
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width <= 375.w;
  }

  /// 是否为大屏设备（平板或桌面）
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 768.w;
  }

  // === 响应式数值 ===
  /// 根据屏幕尺寸返回不同的值
  static T responsiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context) && desktop != null) {
      return desktop;
    } else if (isTablet(context) && tablet != null) {
      return tablet;
    } else {
      return mobile;
    }
  }

  /// 获取响应式列数
  static int getColumns(BuildContext context) {
    return responsiveValue(
      context,
      mobile: 1,
      tablet: 2,
      desktop: 3,
    );
  }

  /// 获取响应式网格列数
  static int getGridColumns(BuildContext context) {
    return responsiveValue(
      context,
      mobile: 2,
      tablet: 3,
      desktop: 4,
    );
  }

  // === 适老化响应式配置 ===
  /// 获取适老化字体缩放比例
  static double getElderlyFontScale(BuildContext context) {
    // 大屏设备可以使用更大的字体
    return isLargeScreen(context) ? 1.3 : 1.2;
  }

  /// 获取适老化按钮最小高度
  static double getElderlyButtonHeight(BuildContext context) {
    return responsiveValue(
      context,
      mobile: 56.h,
      tablet: 64.h,
      desktop: 72.h,
    );
  }

  /// 获取适老化触摸目标最小尺寸
  static double getElderlyTouchTarget(BuildContext context) {
    return responsiveValue(
      context,
      mobile: 48.w,
      tablet: 56.w,
      desktop: 64.w,
    );
  }

  // === 布局辅助 ===
  /// 获取内容最大宽度（防止在大屏上内容过宽）
  static double getMaxContentWidth(BuildContext context) {
    return responsiveValue(
      context,
      mobile: double.infinity,
      tablet: 768.w,
      desktop: 1200.w,
    );
  }

  /// 获取侧边距
  static double getHorizontalPadding(BuildContext context) {
    return responsiveValue(
      context,
      mobile: 16.w,
      tablet: 32.w,
      desktop: 48.w,
    );
  }

  /// 获取卡片间距
  static double getCardSpacing(BuildContext context) {
    return responsiveValue(
      context,
      mobile: 8.w,
      tablet: 12.w,
      desktop: 16.w,
    );
  }

  // === 文字大小辅助 ===
  /// 获取响应式标题大小
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

  /// 获取响应式正文大小
  static double getBodySize(BuildContext context, {bool isLarge = false}) {
    if (isLarge) {
      return responsiveValue(
        context,
        mobile: 16.sp,
        tablet: 18.sp,
        desktop: 20.sp,
      );
    } else {
      return responsiveValue(
        context,
        mobile: 14.sp,
        tablet: 16.sp,
        desktop: 18.sp,
      );
    }
  }

  // === 图标大小辅助 ===
  /// 获取响应式图标大小
  static double getIconSize(BuildContext context, {bool isLarge = false}) {
    if (isLarge) {
      return responsiveValue(
        context,
        mobile: 32.w,
        tablet: 40.w,
        desktop: 48.w,
      );
    } else {
      return responsiveValue(
        context,
        mobile: 24.w,
        tablet: 28.w,
        desktop: 32.w,
      );
    }
  }

  // === 屏幕信息 ===
  /// 获取状态栏高度
  static double getStatusBarHeight(BuildContext context) {
    return MediaQuery.of(context).padding.top;
  }

  /// 获取底部安全区域高度
  static double getBottomSafeArea(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }

  /// 获取屏幕宽度
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// 获取屏幕高度
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// 获取可用高度（去除状态栏和底部安全区域）
  static double getAvailableHeight(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.size.height - mediaQuery.padding.top - mediaQuery.padding.bottom;
  }

  // === 方向检测 ===
  /// 是否为横屏
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// 是否为竖屏
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  // === 调试信息 ===
  /// 打印屏幕信息（调试用）
  static void printScreenInfo(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    print('=== 屏幕信息 ===');
    print('屏幕尺寸: ${mediaQuery.size.width} x ${mediaQuery.size.height}');
    print('设备像素比: ${mediaQuery.devicePixelRatio}');
    print('设备类型: ${isMobile(context) ? '手机' : isTablet(context) ? '平板' : '桌面'}');
    print('方向: ${isLandscape(context) ? '横屏' : '竖屏'}');
    print('状态栏高度: ${getStatusBarHeight(context)}');
    print('底部安全区域: ${getBottomSafeArea(context)}');
    print('ScreenUtil 设计尺寸: ${1.sw} x ${1.sh}');
    print('================');
  }
}

/// 响应式构建器
///
/// 根据屏幕尺寸返回不同的组件
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    required this.mobile,
    super.key,
    this.tablet,
    this.desktop,
  });
  final Widget mobile;
  final Widget? tablet;
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

/// 响应式布局构建器
///
/// 提供更细粒度的响应式控制
class ResponsiveLayoutBuilder extends StatelessWidget {
  const ResponsiveLayoutBuilder({
    required this.builder,
    super.key,
  });
  final Widget Function(BuildContext context, BoxConstraints constraints) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: builder,
    );
  }
}

/// 适老化响应式组件
///
/// 专门为老年用户优化的响应式组件
class ElderlyResponsiveWidget extends StatelessWidget {
  const ElderlyResponsiveWidget({
    required this.child,
    super.key,
    this.fontScale,
    this.enableLargeTouch = true,
  });
  final Widget child;
  final double? fontScale;
  final bool enableLargeTouch;

  @override
  Widget build(BuildContext context) {
    final scale = fontScale ?? ResponsiveUtils.getElderlyFontScale(context);

    var result = child;

    // 应用字体缩放
    result = MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(scale),
      ),
      child: result,
    );

    // 启用大触摸目标
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
