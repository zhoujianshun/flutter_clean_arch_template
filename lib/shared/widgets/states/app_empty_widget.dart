import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_clean_arch_template/core/theme/app_theme.dart';

enum AppEmptyWidgetType {
  /// 待接单
  messageCenter('暂无消息记录', 'assets/images/message_list_empty.png'),

  /// 待服务
  orderList('您还没有相关订单', 'assets/images/order_list_empty.png'),

  normal('暂无数据', 'assets/images/order_list_empty.png');

  const AppEmptyWidgetType(this.message, this.image);

  final String message;
  final String image;
}

class AppEmptyWidget extends StatelessWidget {
  const AppEmptyWidget({super.key, this.message, this.inScrollView = false, this.type = AppEmptyWidgetType.normal});
  final String? message;

  /// 是否在ScrollView中，这样的话可以在下拉刷新中使用
  final bool inScrollView;

  final AppEmptyWidgetType type;

  @override
  Widget build(BuildContext context) {
    var child = _buildEmptyWidget(context);
    if (inScrollView) {
      child = SizedBox(
        height: double.infinity,
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.only(top: 96.h),
            child: child,
          ),
        ),
      );
    }
    return child;
  }

  Widget _buildEmptyWidget(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            type.image,
            width: 165.w,
            height: 144.w,
          ),
          SizedBox(height: 16.w),
          Text(
            getMessage(),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppAdaptiveColors.neutral700(context),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  String getMessage() {
    return message ?? type.message;
  }
}
