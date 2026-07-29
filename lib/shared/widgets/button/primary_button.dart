import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/shared/responsive/responsive_tokens.dart';

/// 带加载状态的按钮组件
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    super.key,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.elevation,
    this.borderRadius,
    this.width,
    this.height,
    this.isRounded = false,
    this.disabledBackgroundColor,
    this.disabledForegroundColor,
    this.minimumSize,
    this.roundedRadius,
  });

  factory PrimaryButton.roundText({
    required String text,
    Key? key,
    VoidCallback? onPressed,
    double? width,
    double? height,
    Color? foregroundColor,
    Color? disabledForegroundColor,
    TextStyle? textStyle,
    double? fontSize,
    double? radius,
  }) {
    return PrimaryButton.text(
      key: key,
      onPressed: onPressed,
      isRounded: true,
      width: width,
      height: height,
      text: text,
      foregroundColor: foregroundColor,
      disabledForegroundColor: disabledForegroundColor,
      textStyle: textStyle,
      fontSize: fontSize,
      roundedRadius: radius,
    );
  }

  factory PrimaryButton.text({
    required String text,
    Key? key,
    bool isRounded = false,
    VoidCallback? onPressed,
    double? width,
    double? height,
    Color? foregroundColor,
    Color? disabledForegroundColor,
    TextStyle? textStyle,
    double? fontSize,
    double? roundedRadius,
  }) {
    return PrimaryButton(
      key: key,
      isRounded: isRounded,
      roundedRadius: roundedRadius,
      onPressed: onPressed,
      foregroundColor: foregroundColor,
      disabledForegroundColor: disabledForegroundColor,
      width: width,
      height: height,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final fgColor =
              foregroundColor ?? theme.colorScheme.surfaceContainerHighest;
          var mainTextStyle =
              textStyle ??
              theme.textTheme.bodyMedium?.copyWith(
                fontSize:
                    fontSize ??
                    ResponsiveTokens.font(14, medium: 14, expanded: 14),
              );
          mainTextStyle = mainTextStyle?.copyWith(
            decoration: TextDecoration.none,
            color: onPressed != null
                ? fgColor
                : (disabledForegroundColor ?? fgColor.withValues(alpha: 0.6)),
            height: 1,
          );
          return Text(
            text,
            style: mainTextStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        },
      ),
    );
  }

  factory PrimaryButton.round({
    required Widget child,
    Key? key,
    bool isLoading = false,
    VoidCallback? onPressed,
    double? width,
    double? height,
    Color? backgroundColor,
    Color? foregroundColor,
    Color? disabledBackgroundColor,
    Color? disabledForegroundColor,
    EdgeInsetsGeometry? padding,
    double? elevation,
    BorderRadius? borderRadius,
    double? radius,
  }) {
    return PrimaryButton(
      isRounded: true,
      roundedRadius: radius,
      isLoading: isLoading,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      disabledBackgroundColor: disabledBackgroundColor,
      disabledForegroundColor: disabledForegroundColor,
      padding: padding,
      elevation: elevation,
      borderRadius: borderRadius,
      key: key,
      onPressed: onPressed,
      width: width,
      height: height,
      child: child,
    );
  }
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget child;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? disabledBackgroundColor;
  final Color? disabledForegroundColor;
  final EdgeInsetsGeometry? padding;
  final double? elevation;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;
  final Size? minimumSize;
  final double? roundedRadius;

  /// 是否圆角
  final bool isRounded;

  @override
  Widget build(BuildContext context) {
    if (width != null || height != null) {
      return SizedBox(
        width: width,
        height: height,
        child: _buildButton(context),
      );
    }

    return _buildButton(context);
  }

  Widget _buildButton(BuildContext context) {
    final theme = Theme.of(context);
    // 圆角优先级：
    // 1) 显式传入 borderRadius
    // 2) roundedRadius（无论 isRounded 是否为 true 都生效）
    // 3) isRounded=true 时使用胶囊圆角
    final effectiveBorderRadius =
        borderRadius ??
        (roundedRadius != null
            ? BorderRadius.circular(roundedRadius!)
            : (isRounded ? BorderRadius.circular(999999) : null));

    final bgColor = backgroundColor ?? theme.primaryColor;
    final fgColor =
        foregroundColor ?? theme.colorScheme.surfaceContainerHighest;

    final actualPadding = minimumSize == null && width == null && height == null
        ? const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          )
        : padding;

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        disabledBackgroundColor:
            disabledBackgroundColor ?? bgColor.withValues(alpha: 0.6),
        disabledForegroundColor:
            disabledForegroundColor ?? fgColor.withValues(alpha: 0.7),
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        // 去除按钮的padding
        padding: actualPadding,
        minimumSize: minimumSize,
        elevation: elevation ?? 0,
        shape: effectiveBorderRadius != null
            ? RoundedRectangleBorder(borderRadius: effectiveBorderRadius)
            : null,
      ),
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  foregroundColor ?? theme.colorScheme.onPrimary,
                ),
              ),
            )
          : child,
    );
  }
}
