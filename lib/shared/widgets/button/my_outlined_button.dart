import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/core/theme/app_theme.dart';
import 'package:flutter_clean_arch_template/shared/widgets/my_circular_progress_indicator.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum MyOutlinedButtonType {
  primary,
  plain,
}

/// 有边框的按钮组件，类iOS风格
/// 提供多种工厂构造函数以支持不同的使用场景
class MyOutlinedButton extends StatelessWidget {
  const MyOutlinedButton({
    required this.child,
    this.type = MyOutlinedButtonType.primary,
    super.key,
    this.onPressed,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    this.alignment = Alignment.center,
    this.borderColor,
    this.disabledBorderColor,
    this.borderWidth,
    this.backgroundColor,
    this.disabledBackgroundColor,
    this.isLoading = false,
    this.minimumSize,
    this.expand = false,
  });

  /// 圆角边框按钮
  factory MyOutlinedButton.round({
    required Widget child,
    MyOutlinedButtonType type = MyOutlinedButtonType.primary,
    Key? key,
    bool isLoading = false,
    VoidCallback? onPressed,
    double? width,
    double? height,
    EdgeInsets? padding,
    Color? borderColor,
    Color? disabledBorderColor,
    double? borderWidth,
    Color? backgroundColor,
    Color? disabledBackgroundColor,
    AlignmentGeometry alignment = Alignment.center,
    Size? minimumSize,
    bool expand = false,
  }) {
    // final btnHeight = height ?? 36.sp;
    return MyOutlinedButton(
      key: key,
      onPressed: onPressed,
      type: type,
      isLoading: isLoading,
      width: width,
      height: height,
      borderColor: borderColor,
      disabledBorderColor: disabledBorderColor,
      borderWidth: borderWidth,
      backgroundColor: backgroundColor,
      disabledBackgroundColor: disabledBackgroundColor,
      borderRadius: BorderRadius.circular(9999),
      padding: padding,
      alignment: alignment,
      minimumSize: minimumSize,
      expand: expand,
      child: child,
    );
  }

  /// 文本边框按钮
  factory MyOutlinedButton.text({
    required String text,
    MyOutlinedButtonType type = MyOutlinedButtonType.primary,
    Key? key,
    bool isLoading = false,
    VoidCallback? onPressed,
    double? width,
    double? height,
    EdgeInsets? padding,
    Color? borderColor,
    Color? disabledBorderColor,
    double? borderWidth,
    Color? backgroundColor,
    Color? disabledBackgroundColor,
    Color? foregroundColor,
    Color? disabledForegroundColor,
    BorderRadius? borderRadius,
    TextStyle? textStyle,
    double? fontSize,
    Widget? icon,
    double? space,
    AlignmentGeometry alignment = Alignment.center,
    Size? minimumSize,
    bool expand = false,
  }) {
    return MyOutlinedButton(
      key: key,
      onPressed: onPressed,
      type: type,
      isLoading: isLoading,
      width: width,
      height: height,
      padding: padding,
      borderColor: borderColor,
      disabledBorderColor: disabledBorderColor,
      borderWidth: borderWidth,
      backgroundColor: backgroundColor,
      disabledBackgroundColor: disabledBackgroundColor,
      borderRadius: borderRadius,
      alignment: alignment,
      minimumSize: minimumSize,
      expand: expand,
      child: Builder(
        builder: (context) {
          final mainColor = type == MyOutlinedButtonType.primary
              ? Theme.of(context).primaryColor
              : AppAdaptiveColors.neutral700(context);
          final buttonForegroundColor = foregroundColor ?? borderColor ?? mainColor;

          // 禁用状态判断
          final isDisabled = onPressed == null || isLoading;

          var mainTextStyle =
              textStyle ??
              Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: fontSize ?? 14.sp,
              );
          mainTextStyle = mainTextStyle?.copyWith(
            decoration: TextDecoration.none,
            color: !isDisabled
                ? buttonForegroundColor
                : (disabledForegroundColor ?? buttonForegroundColor.withValues(alpha: 0.6)),
            height: 1,
          );

          Widget child = Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: mainTextStyle,
          );

          if (icon != null) {
            child = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                icon,
                SizedBox(width: space ?? 4.sp),
                child,
              ],
            );
          }

          return child;
        },
      ),
    );
  }

  /// 圆角文本边框按钮
  factory MyOutlinedButton.roundText({
    required String text,
    MyOutlinedButtonType type = MyOutlinedButtonType.primary,
    Key? key,
    bool isLoading = false,
    VoidCallback? onPressed,
    double? width,
    double? height,
    EdgeInsets? padding,
    Color? borderColor,
    Color? disabledBorderColor,
    double? borderWidth,
    Color? backgroundColor,
    Color? disabledBackgroundColor,
    Color? foregroundColor,
    Color? disabledForegroundColor,
    TextStyle? textStyle,
    double? fontSize,
    Widget? icon,
    double? space,
    Size? minimumSize,
    bool expand = false,
  }) {
    // final btnHeight = height ?? 36.sp;
    return MyOutlinedButton.text(
      key: key,
      onPressed: onPressed,
      type: type,
      isLoading: isLoading,
      width: width,
      height: height,
      padding: padding,
      borderColor: borderColor,
      disabledBorderColor: disabledBorderColor,
      borderWidth: borderWidth,
      backgroundColor: backgroundColor,
      disabledBackgroundColor: disabledBackgroundColor,
      foregroundColor: foregroundColor,
      disabledForegroundColor: disabledForegroundColor,
      borderRadius: BorderRadius.circular(9999),
      textStyle: textStyle,
      fontSize: fontSize,
      text: text,
      icon: icon,
      space: space,
      minimumSize: minimumSize,
      expand: expand,
    );
  }

  final MyOutlinedButtonType type;
  final VoidCallback? onPressed;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final AlignmentGeometry alignment;
  final Widget child;
  final bool isLoading;
  // 边框相关属性
  final Color? borderColor;
  final Color? disabledBorderColor;
  final double? borderWidth;

  // 背景色相关属性（可选，用于半透明背景）
  final Color? backgroundColor;
  final Color? disabledBackgroundColor;
  final Size? minimumSize;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final mainColor = type == MyOutlinedButtonType.primary ? theme.primaryColor : AppAdaptiveColors.neutral500(context);

    final effectiveBorderColor = borderColor ?? mainColor;
    final effectiveDisabledBorderColor = disabledBorderColor ?? effectiveBorderColor.withValues(alpha: 0.6);
    final effectiveBorderWidth = borderWidth ?? 1.0;
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(8.r);

    // 禁用状态判断
    final isDisabled = onPressed == null || isLoading;

    // 计算内边距
    final effectivePadding =
        padding ??
        (width == null || height == null ? EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.w) : EdgeInsets.zero);

    // 构建按钮内容 - 使用 Align 配合 widthFactor 实现紧凑布局
    final buttonChild = Container(
      decoration: BoxDecoration(
        color: !isDisabled ? backgroundColor : (disabledBackgroundColor ?? backgroundColor?.withValues(alpha: 0.6)),
        border: Border.all(
          color: !isDisabled ? effectiveBorderColor : effectiveDisabledBorderColor,
          width: effectiveBorderWidth,
        ),
        borderRadius: effectiveBorderRadius,
      ),
      constraints: BoxConstraints(
        minWidth: width ?? minimumSize?.width ?? 0,
        minHeight: height ?? minimumSize?.height ?? 0,
        maxWidth: width ?? double.infinity,
        maxHeight: height ?? double.infinity,
      ),
      padding: effectivePadding,
      // 关键：使用 Align 的 widthFactor 和 heightFactor 让按钮收缩到内容大小
      child: Align(
        alignment: alignment,
        widthFactor: expand ? null : 1, // 收缩到子元素宽度
        heightFactor: expand ? null : 1, // 收缩到子元素高度
        child: isLoading
            ? MyCircularProgressIndicator(
                color: effectiveDisabledBorderColor,
              )
            : child,
      ),
    );

    final button = CupertinoButton(
      onPressed: isDisabled ? null : onPressed,
      padding: EdgeInsets.zero,
      borderRadius: effectiveBorderRadius,
      minimumSize: Size.zero,
      child: buttonChild,
    );

    // 只在明确指定了宽度或高度时才用 SizedBox 约束
    if (width != null || height != null) {
      return SizedBox(
        width: width,
        height: height,
        child: button,
      );
    }

    return button;
  }
}
