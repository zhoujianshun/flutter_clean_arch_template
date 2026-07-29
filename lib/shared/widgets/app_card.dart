import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/core/theme/app_theme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 主题化卡片容器
///
/// 提供统一的卡片样式，支持圆角、阴影、背景色等自定义。
/// 当 [decoration] 不为 null 时，[borderRadius]、[color]、[boxShadow]
/// 等快捷参数会被忽略，以 [decoration] 为准。
///
/// 设置 [onTap] 后默认启用按压缩放动画（类似 App Store 卡片效果），
/// 可通过 [enablePressAnimation] 控制是否启用。
class AppCard extends StatefulWidget {
  const AppCard({
    required this.child,
    this.padding,
    this.margin,
    this.decoration,
    this.width,
    this.height,
    super.key,
    this.onTap,
    this.clipBehavior = Clip.none,
    this.constraints,
    this.borderRadius,
    this.color,
    this.boxShadow,
    this.border,
    this.enablePressAnimation,
    this.pressScale = 0.96,
  });

  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  /// 完全自定义装饰，设置后会忽略 [borderRadius]、[color]、[boxShadow]、[border]
  final BoxDecoration? decoration;
  final double? width;
  final double? height;
  final GestureTapCallback? onTap;
  final Clip clipBehavior;
  final BoxConstraints? constraints;

  /// 圆角半径，默认 16.r
  final BorderRadiusGeometry? borderRadius;

  /// 背景色，默认 neutral100
  final Color? color;

  /// 阴影，默认无阴影
  final List<BoxShadow>? boxShadow;

  /// 边框
  final BoxBorder? border;

  /// 是否启用按压缩放动画，默认在 [onTap] 不为 null 时自动启用
  final bool? enablePressAnimation;

  /// 按压时的缩放比例，默认 0.96（缩小 4%）
  final double pressScale;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  bool get _shouldAnimate =>
      widget.enablePressAnimation ?? widget.onTap != null;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(
      begin: 1,
      end: widget.pressScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (_shouldAnimate) unawaited(_controller.forward());
  }

  void _onTapUp(TapUpDetails _) {
    if (_shouldAnimate) unawaited(_controller.reverse());
  }

  void _onTapCancel() {
    if (_shouldAnimate) unawaited(_controller.reverse());
  }

  @override
  Widget build(BuildContext context) {
    final effectiveDecoration = widget.decoration ??
        BoxDecoration(
          color: widget.color ?? AppAdaptiveColors.neutral100(context),
          borderRadius:
              widget.borderRadius ?? BorderRadius.circular(16.r),
          boxShadow: widget.boxShadow,
          border: widget.border,
        );

    Widget card = Container(
      width: widget.width,
      height: widget.height,
      constraints: widget.constraints,
      clipBehavior: widget.clipBehavior,
      padding: widget.padding ??
          EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.w),
      margin: widget.margin,
      decoration: effectiveDecoration,
      child: widget.child,
    );

    if (widget.onTap != null || _shouldAnimate) {
      card = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: card,
      );
    }

    if (_shouldAnimate) {
      return AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: card,
      );
    }

    return card;
  }
}
