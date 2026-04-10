import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_clean_arch_template/core/theme/app_theme.dart';

/// 红点徽章组件
class RedDotBadge extends StatelessWidget {
  const RedDotBadge({
    required this.child,
    this.showBadge = false,
    this.badgeCount,
    this.offset,
    this.badgeColor,
    this.badgeSize,
    super.key,
  });

  /// 子组件
  final Widget child;

  /// 是否显示徽章
  final bool showBadge;

  /// 徽章数量（如果为null或0，则显示红点；如果大于0，则显示数字）
  final int? badgeCount;

  /// 徽章偏移量
  final Offset? offset;

  /// 徽章颜色
  final Color? badgeColor;

  /// 徽章大小（仅对红点有效）
  final double? badgeSize;

  @override
  Widget build(BuildContext context) {
    if (!showBadge) {
      return child;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: (offset?.dy ?? 0) - 4.h,
          right: (offset?.dx ?? 0) - 4.w,
          child: _buildBadge(context),
        ),
      ],
    );
  }

  Widget _buildBadge(BuildContext context) {
    final effectiveBadgeColor = badgeColor ?? AppAdaptiveColors.error500(context);
    final count = badgeCount ?? 0;

    if (count > 0) {
      // 显示数字徽章
      return _buildNumberBadge(context, count, effectiveBadgeColor);
    } else {
      // 显示红点
      return _buildDotBadge(context, effectiveBadgeColor);
    }
  }

  /// 构建数字徽章
  Widget _buildNumberBadge(BuildContext context, int count, Color badgeColor) {
    final displayText = count > 99 ? '99+' : count.toString();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: count > 9 ? 6.w : 4.w,
        vertical: 2.h,
      ),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: AppAdaptiveColors.surface(context),
          width: 1.w,
        ),
      ),
      constraints: BoxConstraints(
        minWidth: 16.w,
        minHeight: 16.h,
      ),
      child: Text(
        displayText,
        style: AppTextStyles.overline.copyWith(
          color: Colors.white,
          fontSize: 10.sp,
          fontWeight: FontWeight.w500,
          height: 1.2,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// 构建红点徽章
  Widget _buildDotBadge(BuildContext context, Color badgeColor) {
    final size = badgeSize ?? 8.w;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: badgeColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppAdaptiveColors.surface(context),
          width: 1.w,
        ),
      ),
    );
  }
}

/// 用于Tab的红点徽章组件
class TabBadge extends StatelessWidget {
  const TabBadge({
    required this.child,
    this.showBadge = false,
    this.badgeCount,
    super.key,
  });

  final Widget child;
  final bool showBadge;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    return RedDotBadge(
      showBadge: showBadge,
      badgeCount: badgeCount,
      offset: Offset(1.w, 1.h),
      badgeSize: 6.w,
      child: child,
    );
  }
}

/// 用于底部导航栏的红点徽章组件
class BottomNavBadge extends StatelessWidget {
  const BottomNavBadge({
    required this.child,
    this.showBadge = false,
    this.badgeCount,
    super.key,
  });

  final Widget child;
  final bool showBadge;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    return RedDotBadge(
      showBadge: showBadge,
      badgeCount: badgeCount,
      offset: Offset(12.w, 6.h),
      badgeSize: 8.w,
      child: child,
    );
  }
}
