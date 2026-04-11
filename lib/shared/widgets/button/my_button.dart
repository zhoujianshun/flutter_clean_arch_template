import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/shared/widgets/my_circular_progress_indicator.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// 无背景色，类ios按钮
class MyButton extends StatelessWidget {
  const MyButton({
    required this.child,
    super.key,
    this.foregroundColor,
    this.isLoading = false,
    this.backgroundColor,
    this.disableBackgroundColor,
    this.width,
    this.height,
    this.padding,
    this.onPressed,
    this.borderRadius,
    this.alignment = Alignment.center,
    this.minimumSize,
  });

  factory MyButton.round({
    required Widget child,
    Key? key,
    VoidCallback? onPressed,
    Color? foregroundColor,
    double? width,
    double? height,
    EdgeInsets? padding,
    Color? backgroundColor,
    Color? disableBackgroundColor,
    AlignmentGeometry alignment = Alignment.center,
    Size? minimumSize,
  }) {
    // final btnHeight = height ?? 36.sp;
    return MyButton(
      key: key,
      onPressed: onPressed,
      width: width,
      height: height,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      disableBackgroundColor: disableBackgroundColor,
      borderRadius: BorderRadius.circular(9999),
      padding: padding,
      alignment: alignment,
      minimumSize: minimumSize,
      child: child,
    );
  }

  factory MyButton.text({
    required String text,
    Key? key,
    VoidCallback? onPressed,
    double? width,
    double? height,
    EdgeInsets? padding,
    Color? backgroundColor,
    Color? disableBackgroundColor,
    Color? foregroundColor,
    Color? disableForegroundColor,
    BorderRadius? borderRadius,
    TextStyle? textStyle,
    double? fontSize,
    Widget? icon,
    bool isLoading = false,
    double? space,
    Size? minimumSize,
  }) {
    return MyButton(
      key: key,
      onPressed: onPressed,
      width: width,
      height: height,
      padding: padding,
      isLoading: isLoading,
      backgroundColor: backgroundColor,
      disableBackgroundColor: disableBackgroundColor,
      borderRadius: borderRadius,
      foregroundColor: foregroundColor,
      minimumSize: minimumSize,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final buttonForegroundColor = foregroundColor ?? theme.textTheme.bodyMedium?.color;
          final isDisabled = onPressed == null || isLoading;

          var mainTextStyle =
              textStyle ??
              theme.textTheme.bodyMedium?.copyWith(
                fontSize: fontSize ?? 14.sp,
              );
          mainTextStyle = mainTextStyle?.copyWith(
            decoration: TextDecoration.none,
            color: !isDisabled
                ? buttonForegroundColor
                : (disableForegroundColor ?? buttonForegroundColor?.withValues(alpha: 0.6)),
          );
          Widget child = Text(
            text,
            style: mainTextStyle,
          );
          if (icon != null) {
            child = Row(
              children: [
                icon,
                SizedBox(
                  width: space ?? 4.sp,
                ),
                child,
              ],
            );
          }
          return child;
        },
      ),
    );
  }
  final VoidCallback? onPressed;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final Color? disableBackgroundColor;
  final bool isLoading;
  final AlignmentGeometry alignment;
  final Size? minimumSize;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final widget = _buildButton(context);
    if ((width != null || height != null) && minimumSize == null) {
      return SizedBox(
        width: width,
        height: height,
        child: widget,
      );
    }
    return widget;
  }

  Widget _buildButton(BuildContext context) {
    // final theme = Theme.of(context);
    final isDisabled = onPressed == null || isLoading;

    final foregroundColor = this.foregroundColor ?? DefaultTextStyle.of(context).style.color;

    // 如果没有设置 minimumSize，则使用默认内边距
    final actualPadding =
        padding ??
        (width == null || height == null ? EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.w) : EdgeInsets.zero);

    final Widget widget = CupertinoButton(
      onPressed: isDisabled ? null : onPressed,
      padding: actualPadding,
      color: backgroundColor,
      foregroundColor: foregroundColor,
      borderRadius: borderRadius,
      disabledColor: disableBackgroundColor ?? CupertinoColors.quaternarySystemFill,
      alignment: alignment,
      minimumSize: minimumSize,
      child: isLoading
          ? MyCircularProgressIndicator(
              color: isDisabled ? foregroundColor?.withValues(alpha: 0.6) : foregroundColor,
            )
          : child,
    );

    return widget;
  }
}
