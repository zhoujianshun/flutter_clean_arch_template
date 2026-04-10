import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_clean_arch_template/core/theme/app_theme.dart';

/// 应用加载指示器组件
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({
    this.size = 24,
    this.strokeWidth = 2.0,
    this.color,
    this.backgroundColor,
    this.width,
    this.height,
    super.key,
  });

  final double? width;
  final double? height;

  /// 指示器大小
  final double size;

  /// 线条宽度
  final double strokeWidth;

  /// 指示器颜色
  final Color? color;

  /// 背景颜色
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      child: SizedBox(
        width: size.r,
        height: size.r,
        child: CircularProgressIndicator(
          strokeWidth: strokeWidth,
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? AppAdaptiveColors.primary700(context),
          ),
          backgroundColor: backgroundColor,
        ),
      ),
    );
  }
}

/// 页面级别的加载指示器
class AppPageLoadingIndicator extends StatelessWidget {
  const AppPageLoadingIndicator({
    this.message,
    super.key,
  });

  /// 加载消息
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AppLoadingIndicator(size: 32),
          if (message != null) ...[
            SizedBox(height: 16.h),
            Text(
              message!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppAdaptiveColors.neutral600(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// 按钮内的加载指示器
class AppButtonLoadingIndicator extends StatelessWidget {
  const AppButtonLoadingIndicator({
    this.size = 16,
    this.color,
    super.key,
  });

  /// 指示器大小
  final double size;

  /// 指示器颜色
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size.r,
        height: size.r,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? Colors.white,
          ),
        ),
      ),
    );
  }
}
