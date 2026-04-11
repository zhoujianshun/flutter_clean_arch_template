import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/core/theme/app_theme.dart';
import 'package:flutter_clean_arch_template/shared/widgets/gradient_icon.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Sky Harbor 自定义评分组件
/// 支持半颗星评分，完全适配项目主题系统
class AppRatingBar extends StatelessWidget {
  const AppRatingBar({
    required this.rating,
    this.onRatingUpdate,
    this.starCount = 5,
    this.size,
    this.itemPadding,
    this.allowHalfRating = true,
    this.ignoreGestures = false,
    this.direction = Axis.horizontal,
    this.tapOnlyMode = false,
    this.glow = true,
    this.maxRating,
    this.minRating,
    this.unratedColor,
    this.ratedColor,
    this.wrapAlignment = WrapAlignment.start,
    this.useGradient = false,
    this.gradientColors,
    super.key,
  });

  /// 当前评分值
  final double rating;

  /// 评分更新回调
  final ValueChanged<double>? onRatingUpdate;

  /// 星星数量，默认5颗
  final int starCount;

  /// 星星大小，默认根据屏幕适配
  final double? size;

  /// 星星间距，默认根据屏幕适配
  final EdgeInsets? itemPadding;

  /// 是否允许半颗星，默认true
  final bool allowHalfRating;

  /// 是否忽略手势（只读模式），默认false
  final bool ignoreGestures;

  /// 排列方向，默认水平
  final Axis direction;

  /// 是否只在点击时更新评分（而不是拖拽），默认false
  final bool tapOnlyMode;

  /// 是否显示发光效果，默认true
  final bool glow;

  /// 最大评分值
  final double? maxRating;

  /// 最小评分值
  final double? minRating;

  /// 未评分星星的颜色
  final Color? unratedColor;

  /// 已评分星星的颜色
  final Color? ratedColor;

  /// 换行对齐方式
  final WrapAlignment wrapAlignment;

  /// 是否使用渐变色
  final bool useGradient;

  /// 渐变颜色列表（当 useGradient 为 true 时使用）
  final List<Color>? gradientColors;

  @override
  Widget build(BuildContext context) {
    final effectiveSize = size ?? 16.w;
    final effectiveItemPadding = itemPadding ?? EdgeInsets.symmetric(horizontal: 1.w);
    final effectiveRatedColor = ratedColor ?? AppAdaptiveColors.warning500(context);
    final effectiveUnratedColor = unratedColor ?? AppAdaptiveColors.neutral400(context);

    return RatingBar.builder(
      initialRating: rating,
      minRating: minRating ?? 0,
      maxRating: maxRating ?? starCount.toDouble(),
      direction: direction,
      allowHalfRating: allowHalfRating,
      ignoreGestures: ignoreGestures,
      tapOnlyMode: tapOnlyMode,
      glow: glow,
      itemCount: starCount,
      itemPadding: effectiveItemPadding,
      wrapAlignment: wrapAlignment,
      itemBuilder: (context, index) => useGradient && gradientColors != null
          ? LinearGradientIcon(
              icon: Icons.star_rounded,
              size: effectiveSize,
              colors: gradientColors!,
            )
          : Icon(
              Icons.star_rounded,
              size: effectiveSize,
              color: effectiveRatedColor,
            ),
      unratedColor: effectiveUnratedColor,
      onRatingUpdate: onRatingUpdate ?? (_) {},
    );
  }
}

/// 只读评分显示组件
/// 用于显示评分，不支持交互
class SkyRatingDisplay extends StatelessWidget {
  const SkyRatingDisplay({
    required this.rating,
    this.starCount = 5,
    this.size,
    this.itemPadding,
    this.showRatingText = false,
    this.ratingTextStyle,
    this.direction = Axis.horizontal,
    this.unratedColor,
    this.ratedColor,
    this.useGradient = true,
    this.gradientColors = const [Color(0xFFFA6C21), Color(0xFFDC3545)],
    super.key,
  });

  /// 当前评分值
  final double rating;

  /// 星星数量，默认5颗
  final int starCount;

  /// 星星大小，默认根据屏幕适配
  final double? size;

  /// 星星间距，默认根据屏幕适配
  final EdgeInsets? itemPadding;

  /// 是否显示评分文字
  final bool showRatingText;

  /// 评分文字样式
  final TextStyle? ratingTextStyle;

  /// 排列方向，默认水平
  final Axis direction;

  /// 未评分星星的颜色
  final Color? unratedColor;

  /// 已评分星星的颜色
  final Color? ratedColor;

  /// 是否使用渐变色
  final bool useGradient;

  /// 渐变颜色列表（当 useGradient 为 true 时使用）
  final List<Color>? gradientColors;

  @override
  Widget build(BuildContext context) {
    final effectiveSize = size ?? 16.w;
    final effectiveItemPadding = itemPadding ?? EdgeInsets.symmetric(horizontal: 1.w);
    final effectiveRatedColor = ratedColor ?? AppAdaptiveColors.warning500(context);
    final effectiveUnratedColor = unratedColor ?? AppAdaptiveColors.neutral400(context);

    final Widget ratingWidget = RatingBarIndicator(
      rating: rating,
      direction: direction,
      itemCount: starCount,
      itemSize: effectiveSize,
      itemPadding: effectiveItemPadding,
      itemBuilder: (context, index) => useGradient && gradientColors != null
          ? LinearGradientIcon(
              icon: Icons.star_rounded,
              size: effectiveSize,
              colors: gradientColors!,
            )
          : Icon(
              Icons.star_rounded,
              size: effectiveSize,
              color: effectiveRatedColor,
            ),
      unratedColor: effectiveUnratedColor,
    );

    if (!showRatingText) {
      return ratingWidget;
    }

    final ratingText = Text(
      rating.toStringAsFixed(1),
      style:
          ratingTextStyle ??
          AppTextStyles.bodySmall.copyWith(
            color: AppAdaptiveColors.neutral700(context),
            fontWeight: FontWeight.w500,
            fontFamily: AppTextStyles.fontFamilyMedium,
          ),
    );

    return direction == Axis.horizontal
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ratingWidget,
              SizedBox(width: 4.w),
              ratingText,
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ratingWidget,
              SizedBox(height: 4.h),
              ratingText,
            ],
          );
  }
}

/// 大尺寸评分组件（适老化设计）
/// 专为老年用户设计，具有更大的触摸区域和视觉元素
class SkyElderlyRatingBar extends StatelessWidget {
  const SkyElderlyRatingBar({
    required this.rating,
    this.onRatingUpdate,
    this.starCount = 5,
    this.allowHalfRating = false, // 老年用户建议不使用半星
    this.showRatingText = true,
    super.key,
  });

  /// 当前评分值
  final double rating;

  /// 评分更新回调
  final ValueChanged<double>? onRatingUpdate;

  /// 星星数量，默认5颗
  final int starCount;

  /// 是否允许半颗星，默认false（适老化考虑）
  final bool allowHalfRating;

  /// 是否显示评分文字
  final bool showRatingText;

  @override
  Widget build(BuildContext context) {
    final isReadOnly = onRatingUpdate == null;

    final Widget ratingWidget = isReadOnly
        ? RatingBarIndicator(
            rating: rating,
            itemCount: starCount,
            itemPadding: EdgeInsets.symmetric(horizontal: 4.w),
            itemBuilder: (context, index) => Icon(
              Icons.star_rounded,
              size: 32.w, // 大尺寸适老化
              color: AppAdaptiveColors.warning500(context),
            ),
            unratedColor: AppAdaptiveColors.neutral400(context),
          )
        : RatingBar.builder(
            initialRating: rating,
            minRating: 1,
            allowHalfRating: allowHalfRating,
            itemCount: starCount,
            itemPadding: EdgeInsets.symmetric(horizontal: 4.w),
            itemBuilder: (context, index) => Icon(
              Icons.star_rounded,
              size: 32.w, // 大尺寸适老化
              color: AppAdaptiveColors.warning500(context),
            ),
            unratedColor: AppAdaptiveColors.neutral400(context),
            onRatingUpdate: onRatingUpdate!,
            tapOnlyMode: true, // 适老化：只支持点击，不支持拖拽
          );

    if (!showRatingText) {
      return ratingWidget;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ratingWidget,
        SizedBox(height: 8.h),
        Text(
          '${rating.toStringAsFixed(allowHalfRating ? 1 : 0)} 分',
          style: AppTextStyles.elderlyBodyLarge.copyWith(
            color: AppAdaptiveColors.neutral800(context),
            fontWeight: FontWeight.w500,
            fontFamily: AppTextStyles.fontFamilyMedium,
          ),
        ),
      ],
    );
  }
}
