import 'package:flutter_clean_arch_template/shared/responsive/breakpoints.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 响应式设计 token（间距、字体、内容宽度等）。
///
/// Token-first 策略：
/// - compact（手机）允许按设计稿缩放；
/// - medium/expanded（平板）优先固定 dp，避免“大屏过度放大”。
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

  static bool get _isCompact =>
      ScreenUtil().screenWidth < ResponsiveBreakpoints.compact;

  static double _compactScale() {
    final scale = ScreenUtil().screenWidth / phoneDesignWidth;
    return scale.clamp(minCompactScaleRatio, maxCompactScaleRatio);
  }

  static double compact(num value) => value * _compactScale();

  static double aw(num value) {
    final scale = ScreenUtil().screenWidth / phoneDesignWidth;
    final clampedScale = scale.clamp(
      minCompactScaleRatio,
      maxAdaptiveScaleRatio,
    );
    return value * clampedScale;
  }

  static double tw(num tabletDesignValue) {
    final scale = ScreenUtil().screenWidth / tabletDesignWidth;
    return tabletDesignValue * scale.clamp(0.8, 1.3);
  }

  /// 根据屏幕尺寸类返回尺寸值。
  ///
  /// - compact：按缩放处理
  /// - medium/expanded：优先使用固定 dp（传入的 medium/expanded）
  static double size(
    num compactValue, {
    double? medium,
    double? expanded,
  }) {
    if (_isCompact) return compact(compactValue);
    if (ScreenUtil().screenWidth >= ResponsiveBreakpoints.expanded &&
        expanded != null) {
      return expanded;
    }
    return medium ?? expanded ?? compactValue.toDouble();
  }

  /// 字体 token。
  ///
  /// - compact：按 ScreenUtil 字体缩放
  /// - medium/expanded：使用固定 dp（防止字体在平板过大）
  static double font(
    num compactValue, {
    double? medium,
    double? expanded,
  }) {
    if (_isCompact) return ScreenUtil().setSp(compactValue.toDouble());
    if (ScreenUtil().screenWidth >= ResponsiveBreakpoints.expanded &&
        expanded != null) {
      return expanded;
    }
    return medium ?? expanded ?? compactValue.toDouble();
  }
}
