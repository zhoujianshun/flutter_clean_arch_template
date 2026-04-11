import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/core/theme/app_theme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding,
    this.margin,
    this.decoration,
    this.width,
    this.height,
    super.key,
    this.onTap,
    this.clipBehavior = Clip.none,
    this.constraints,
  });
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final BoxDecoration? decoration;
  final double? width;
  final double? height;
  final GestureTapCallback? onTap;
  final Clip clipBehavior;
  final BoxConstraints? constraints;

  @override
  Widget build(BuildContext context) {
    Widget widget = Container(
      width: width,
      height: height,
      constraints: constraints,
      clipBehavior: clipBehavior,
      padding: padding ?? EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.w),
      margin: margin,
      decoration:
          decoration ??
          BoxDecoration(
            color: AppAdaptiveColors.neutral100(context),
            borderRadius: BorderRadius.circular(16.r),
          ),
      child: child,
    );
    //
    if (onTap != null) {
      widget = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: widget,
      );
    }
    return widget;
  }
}
