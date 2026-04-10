import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_clean_arch_template/core/theme/app_theme.dart';

/// 默认弹窗标题
///
/// 提供统一的弹窗标题样式，包含标题文本和可选的边距
/// 适用于需要标题的弹窗场景
class DefaultAlertTitle extends StatelessWidget {
  const DefaultAlertTitle({required this.title, super.key, this.padding});
  final String title;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: padding ?? EdgeInsets.only(top: 32.w),
      child: Text(
        title,
        style: AppTextStyles.h4.copyWith(
          fontFamily: AppTextStyles.fontFamilyMedium,
          fontWeight: FontWeight.w500,
          color: AppAdaptiveColors.neutral800(context),
        ),
      ),
    );
  }
}
