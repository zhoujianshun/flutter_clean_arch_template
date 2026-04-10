import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_clean_arch_template/core/theme/app_theme.dart';
import 'package:flutter_clean_arch_template/shared/widgets/button/my_filled_button.dart';

enum AppErrorType {
  /// 网络错误
  network,

  /// 普通错误
  normal,

  /// 订单错误
  order,
}

/// 应用错误显示组件
class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({
    required this.error,
    this.onRetry,
    // this.title,
    this.description,
    this.retryText = '重新加载',
    this.isCenter = false,
    super.key,
    this.type = AppErrorType.normal,
  });

  final AppErrorType type;

  /// 错误信息
  final String error;

  /// 重试回调
  final VoidCallback? onRetry;

  /// 错误标题
  // final String? title;

  /// 错误描述
  final String? description;

  /// 重试按钮文本
  final String retryText;

  final bool isCenter;

  @override
  Widget build(BuildContext context) {
    final child = _buildErrorWidget(context);
    if (isCenter) {
      return Container(
        alignment: Alignment.center,
        padding: EdgeInsets.all(24.r),
        child: child,
      );
    }
    return Container(
      alignment: Alignment.topCenter,
      padding: EdgeInsets.only(top: 96.h),
      child: child,
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Column(
      children: [
        // 错误图标
        Image.asset(
          _getErrorImage(),
          width: 165.w,
          height: 144.w,
        ),
        SizedBox(height: 16.w),
        // 错误标题
        // Text(
        //   title ?? '出错了',
        //   style: AppTextStyles.bodyMedium.copyWith(
        //     color: AppAdaptiveColors.onSurface(context),
        //     fontWeight: FontWeight.w600,
        //   ),
        //   textAlign: TextAlign.center,
        // ),

        // SizedBox(height: 8.w),

        // 错误描述
        Text(
          description ?? '当前网络异常，请刷新试试',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppAdaptiveColors.neutral700(context),
          ),
          textAlign: TextAlign.center,
        ),

        // 错误详情（仅在调试模式下显示）
        if (error.isNotEmpty && kDebugMode) ...[
          SizedBox(height: 4.w),
          ExpansionTile(
            initiallyExpanded: true,
            title: Text(
              '错误详情',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppAdaptiveColors.neutral500(context),
              ),
            ),
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.r),
                margin: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  color: AppAdaptiveColors.error50(context),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: AppAdaptiveColors.error500(context).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  error,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppAdaptiveColors.error700(context),
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ],

        SizedBox(height: 16.w),

        // 重试按钮
        if (onRetry != null)
          ConstrainedBox(
            constraints: BoxConstraints(minWidth: 72.sp),
            child: MyFilledButton.roundText(
              fontSize: 12.sp,
              height: 28.sp,
              text: retryText,
              onPressed: onRetry,
            ),
          ),
      ],
    );
  }

  String _getErrorImage() {
    switch (type) {
      case AppErrorType.network:
        return 'assets/images/network_error.png';
      case AppErrorType.normal:
        return 'assets/images/network_error.png';
      case AppErrorType.order:
        return 'assets/images/order_list_empty.png';
    }
  }
}

/// 简化版错误组件
class AppSimpleErrorWidget extends StatelessWidget {
  const AppSimpleErrorWidget({
    required this.message,
    this.onRetry,
    super.key,
  });

  /// 错误消息
  final String message;

  /// 重试回调
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      margin: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppAdaptiveColors.error50(context),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: AppAdaptiveColors.error500(context),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber,
                size: 20.r,
                color: AppAdaptiveColors.error500(context),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppAdaptiveColors.error700(context),
                  ),
                ),
              ),
            ],
          ),
          if (onRetry != null) ...[
            SizedBox(height: 12.w),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: AppAdaptiveColors.error700(context),
                ),
                child: const Text('重试'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 网络错误组件
class AppNetworkErrorWidget extends StatelessWidget {
  const AppNetworkErrorWidget({
    this.onRetry,
    super.key,
  });

  /// 重试回调
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return AppErrorWidget(
      error: '网络连接失败',
      // title: '网络异常',
      description: '请检查网络连接后重试',
      onRetry: onRetry,
    );
  }
}
