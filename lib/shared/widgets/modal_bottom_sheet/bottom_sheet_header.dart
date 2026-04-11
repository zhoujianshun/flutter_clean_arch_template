import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/core/theme/app_theme.dart';
import 'package:flutter_clean_arch_template/shared/widgets/button/my_button.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 底部表单弹窗通用标题组件
///
/// 提供统一的底部表单标题样式，包含标题文本和关闭按钮
/// 适用于需要标题的底部表单弹窗场景
class BottomSheetHeader extends StatelessWidget {
  const BottomSheetHeader({
    required this.title,
    this.onPressed,
    super.key,
  });

  /// 标题文本
  final String title;

  /// 关闭按钮点击回调，如果为 null 则使用默认的 Navigator.pop
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 标题文本
        Container(
          alignment: Alignment.center,
          height: 56.w,
          margin: EdgeInsets.symmetric(horizontal: 48.w),
          child: Text(
            title,
            style: AppTextStyles.h5.copyWith(fontSize: 20.sp),
            textAlign: TextAlign.center,
          ),
        ),
        // 关闭按钮
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            width: 48.w,
            height: 56.w,
            alignment: Alignment.center,
            child: MyButton(
              onPressed: () => _handleClose(context),
              child: Icon(
                Icons.close,
                color: AppAdaptiveColors.neutral600(context),
                size: 24.sp,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 处理关闭按钮点击
  void _handleClose(BuildContext context) {
    if (onPressed != null) {
      onPressed!();
    } else {
      // 使用默认的关闭行为
      Navigator.pop(context);
    }
  }
}
