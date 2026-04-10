import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_clean_arch_template/core/theme/app_theme.dart';

class FormTitle extends StatelessWidget {
  const FormTitle({required this.title, super.key, this.isRequired = false});
  final String title;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.bodySmall.copyWith(
      fontWeight: FontWeight.w500,
      fontFamily: AppTextStyles.fontFamilyMedium,
    );
    return Container(
      height: 52.w,
      alignment: Alignment.centerLeft,
      child: Text.rich(
        style: style,
        TextSpan(
          children: [
            if (isRequired) TextSpan(text: '*', style: style.copyWith(color: AppAdaptiveColors.error500(context))),
            TextSpan(text: title, style: style),
          ],
        ),
      ),
    );
  }
}
