import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_clean_arch_template/shared/widgets/my_circular_progress_indicator.dart';

// 背景色是主题色，类ios按钮，默认圆角
class MyFilledButton extends StatelessWidget {
  const MyFilledButton({
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

  factory MyFilledButton.round({
    required Widget child,
    Color? foregroundColor,
    Key? key,
    bool isLoading = false,
    VoidCallback? onPressed,
    double? width,
    double? height,
    EdgeInsets? padding,
    Color? backgroundColor,
    Color? disableBackgroundColor,
    AlignmentGeometry alignment = Alignment.center,
    Size? minimumSize,
  }) {
    // final btnHeight = height ?? 36.sp;
    return MyFilledButton(
      key: key,
      isLoading: isLoading,
      onPressed: onPressed,
      width: width,
      height: height,
      backgroundColor: backgroundColor,
      disableBackgroundColor: disableBackgroundColor,
      borderRadius: BorderRadius.circular(99999),
      padding: padding,
      alignment: alignment,
      foregroundColor: foregroundColor,
      minimumSize: minimumSize,
      child: child,
    );
  }

  factory MyFilledButton.roundText({
    required String text,
    Key? key,
    bool isLoading = false,
    VoidCallback? onPressed,
    double? width,
    double? height,
    EdgeInsets? padding,
    Color? backgroundColor,
    Color? disableBackgroundColor,
    Color? foregroundColor,
    Color? disableForegroundColor,
    TextStyle? textStyle,
    double? fontSize,
    Widget? icon,
    double? space,
    Size? minimumSize,
  }) {
    // final btnHeight = height ?? 36.sp;
    return MyFilledButton.text(
      key: key,
      isLoading: isLoading,
      onPressed: onPressed,
      width: width,
      height: height,
      padding: padding,
      backgroundColor: backgroundColor,
      disableBackgroundColor: disableBackgroundColor,
      foregroundColor: foregroundColor,
      disableForegroundColor: disableForegroundColor,
      borderRadius: BorderRadius.circular(99999),
      textStyle: textStyle,
      fontSize: fontSize,
      text: text,
      icon: icon,
      space: space,
      minimumSize: minimumSize,
    );
  }

  factory MyFilledButton.text({
    required String text,
    Key? key,
    bool isLoading = false,
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
    double? space,
    Size? minimumSize,
  }) {
    return MyFilledButton(
      key: key,
      isLoading: isLoading,
      onPressed: onPressed,
      width: width,
      height: height,
      padding: padding,
      backgroundColor: backgroundColor,
      disableBackgroundColor: disableBackgroundColor,
      borderRadius: borderRadius,
      minimumSize: minimumSize,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final buttonForegroundColor = foregroundColor ?? theme.colorScheme.onPrimary;
          final buttonDisableForegroundColor = disableForegroundColor ?? (buttonForegroundColor.withValues(alpha: 0.6));
          final isDisabled = onPressed == null || isLoading;

          var mainTextStyle =
              textStyle ??
              theme.textTheme.bodyMedium?.copyWith(
                fontSize: fontSize ?? 14.sp,
              );
          mainTextStyle = mainTextStyle?.copyWith(
            decoration: TextDecoration.none,
            color: !isDisabled ? buttonForegroundColor : buttonDisableForegroundColor,
            height: 1,
          );

          Widget child = Text(
            text,
            style: mainTextStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
  final AlignmentGeometry alignment;
  final Widget child;
  final bool isLoading;
  final Size? minimumSize;
  @override
  Widget build(BuildContext context) {
    final widget = _buildButton(context);
    // 只有在没有设置 minimumSize 的情况下才使用 SizedBox 固定尺寸
    // 如果设置了 minimumSize，让 CupertinoButton 自己处理尺寸
    if ((height != null || width != null) && minimumSize == null) {
      return SizedBox(
        width: width,
        height: height,
        child: widget,
      );
    }
    return widget;
  }

  Widget _buildButton(BuildContext context) {
    final buttonBackgroundColor = backgroundColor ?? Theme.of(context).primaryColor;
    final buttonDisableBackgroundColor =
        disableBackgroundColor ??
        (buttonBackgroundColor == Colors.transparent
            ? Colors.transparent
            : (buttonBackgroundColor.withValues(alpha: 0.6)));
    final isDisabled = onPressed == null || isLoading;
    final actualPadding =
        padding ??
        (width == null || height == null ? EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.w) : EdgeInsets.zero);

    final Widget widget = CupertinoButton.filled(
      onPressed: isDisabled ? null : onPressed,
      // sizeStyle: CupertinoButtonSize.small,
      padding: actualPadding,
      color: buttonBackgroundColor,
      foregroundColor: foregroundColor,
      borderRadius: borderRadius ?? const BorderRadius.all(Radius.circular(8)),
      disabledColor: buttonDisableBackgroundColor,
      alignment: alignment,
      minimumSize: minimumSize ?? Size.zero,
      child: isLoading
          ? MyCircularProgressIndicator(
              color: foregroundColor,
            )
          : child,
    );

    return widget;
  }
}
