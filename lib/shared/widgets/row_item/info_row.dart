import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/core/theme/app_theme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 信息行
class InfoRow extends StatelessWidget {
  const InfoRow({
    required this.label,
    this.value,
    this.tailWidget,
    this.valueColor,
    this.labelColor,
    this.fontSize,
    super.key,
  });

  final String label;
  final String? value;
  final Widget? tailWidget;
  final Color? valueColor;
  final Color? labelColor;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.transparent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: labelColor ?? AppAdaptiveColors.neutral600(context),
              fontSize: fontSize,
            ),
          ),
          SizedBox(width: 8.sp),
          Flexible(
            child: Text(
              value ?? '',
              style: AppTextStyles.bodySmall.copyWith(
                color: valueColor ?? AppAdaptiveColors.neutral800(context),
                fontSize: fontSize,
              ),
            ),
          ),
          tailWidget ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}
