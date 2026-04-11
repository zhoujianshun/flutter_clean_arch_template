import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/core/theme/app_theme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppTag extends StatelessWidget {
  const AppTag({
    required this.text,
    required this.color,
    this.height,
    this.borderRadius,
    this.padding,
    this.constraints,
    super.key,
  });

  final String text;
  final Color color;
  final double? height;
  final BorderRadiusGeometry? borderRadius;
  final EdgeInsetsGeometry? padding;
  final BoxConstraints? constraints;

  @override
  Widget build(BuildContext context) {
    final wHeight = height;
    return Container(
      height: wHeight,
      alignment: Alignment.center,
      constraints: constraints,
      padding:
          padding ??
          EdgeInsets.symmetric(
            horizontal: 10.w,
            // vertical: 1.w,
          ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: borderRadius ?? BorderRadius.circular(99999),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodyXSmall.copyWith(
          color: color,
          height: 1.5,
        ),
      ),
    );
  }
}
