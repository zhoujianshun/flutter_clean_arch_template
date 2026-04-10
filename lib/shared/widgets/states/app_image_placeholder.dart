import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_clean_arch_template/core/theme/app_theme.dart';

class AppImagePlaceholder extends StatelessWidget {
  const AppImagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildImagePlaceholder(context);
  }

  Widget _buildImagePlaceholder(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppAdaptiveColors.neutral200(context),
            AppAdaptiveColors.neutral300(context),
          ],
        ),
      ),
      child: Icon(
        Icons.image_outlined,
        size: 24.sp,
        color: AppAdaptiveColors.neutral500(context),
      ),
    );
  }
}
