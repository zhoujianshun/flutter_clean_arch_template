import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/shared/responsive/responsive_tokens.dart';

/// 内容宽度约束——当父级可用宽度大于 [maxWidth] 时限制内容宽度并居中。
///
/// 手机端父级通常窄于 [maxWidth]，约束不生效（无视觉变化）；
/// 平板/桌面端父级较宽时生效，确保阅读区域不过宽。
///
/// [maxHeight] 不会自动提供滚动能力，超出部分由内容自身的
/// 滚动行为接管（如 [ListView] / [SingleChildScrollView]）。
class ContentConstraint extends StatelessWidget {
  const ContentConstraint({
    required this.child,
    super.key,
    this.maxWidth = ResponsiveTokens.maxWidthList,
    this.maxHeight,
    this.alignment = Alignment.topCenter,
    this.padding,
  });

  final Widget child;

  /// 内容最大宽度（默认列表语义 600dp）。
  final double maxWidth;

  /// 内容最大高度；null 表示不限制。
  ///
  /// 适用于展开态横持等纵向空间有限的形态，
  /// 超出部分由内容的滚动行为接管。
  final double? maxHeight;

  final Alignment alignment;

  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    Widget current = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
        maxHeight: maxHeight ?? double.infinity,
      ),
      child: child,
    );

    if (padding != null) {
      current = Padding(padding: padding!, child: current);
    }

    return Align(alignment: alignment, child: current);
  }
}
