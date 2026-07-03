import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/shared/responsive/responsive_tokens.dart';

/// Content width constraint for large layouts.
///
/// - compact windows: no visual change
/// - medium/expanded windows: constrain width for readability
class ContentConstraint extends StatelessWidget {
  const ContentConstraint({
    required this.child,
    super.key,
    this.maxWidth = ResponsiveTokens.maxWidthList,
    this.alignment = Alignment.topCenter,
    this.padding,
  });

  final Widget child;
  final double maxWidth;
  final Alignment alignment;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    Widget current = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    );

    if (padding != null) {
      current = Padding(padding: padding!, child: current);
    }

    return Align(alignment: alignment, child: current);
  }
}
