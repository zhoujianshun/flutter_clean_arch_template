import 'package:flutter/material.dart';

/// 圆角TabBar指示器
///
/// 用于创建带圆角的TabBar下划线指示器
/// 支持自定义颜色、粗细和圆角半径
class RoundedRectangleTabIndicator extends Decoration {
  /// 创建圆角TabBar指示器
  ///
  /// [color] 指示器颜色
  /// [weight] 指示器粗细/高度
  /// [radius] 圆角半径
  /// [insets] 指示器内边距，用于控制指示器宽度
  const RoundedRectangleTabIndicator({
    required this.color,
    required this.weight,
    required this.radius,
    this.insets = EdgeInsets.zero,
  });

  /// 指示器颜色
  final Color color;

  /// 指示器粗细/高度
  final double weight;

  /// 圆角半径
  final double radius;

  /// 指示器内边距
  final EdgeInsetsGeometry insets;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _RoundedRectanglePainter(
      color: color,
      weight: weight,
      radius: radius,
      insets: insets,
    );
  }

  @override
  Decoration? lerpFrom(Decoration? a, double t) {
    if (a is RoundedRectangleTabIndicator) {
      return RoundedRectangleTabIndicator(
        color: Color.lerp(a.color, color, t)!,
        weight: lerpDouble(a.weight, weight, t)!,
        radius: lerpDouble(a.radius, radius, t)!,
        insets: EdgeInsetsGeometry.lerp(a.insets, insets, t)!,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  Decoration? lerpTo(Decoration? b, double t) {
    if (b is RoundedRectangleTabIndicator) {
      return RoundedRectangleTabIndicator(
        color: Color.lerp(color, b.color, t)!,
        weight: lerpDouble(weight, b.weight, t)!,
        radius: lerpDouble(radius, b.radius, t)!,
        insets: EdgeInsetsGeometry.lerp(insets, b.insets, t)!,
      );
    }
    return super.lerpTo(b, t);
  }
}

/// 圆角TabBar指示器绘制器
class _RoundedRectanglePainter extends BoxPainter {
  _RoundedRectanglePainter({
    required this.color,
    required this.weight,
    required this.radius,
    required this.insets,
  });

  final Color color;
  final double weight;
  final double radius;
  final EdgeInsetsGeometry insets;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size!;
    final resolvedInsets = insets.resolve(configuration.textDirection);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // 计算指示器的位置和大小
    final indicatorRect = Rect.fromLTWH(
      offset.dx + resolvedInsets.left,
      offset.dy + size.height - weight,
      size.width - resolvedInsets.horizontal,
      weight,
    );

    // 绘制圆角矩形
    final rrect = RRect.fromRectAndRadius(
      indicatorRect,
      Radius.circular(radius),
    );

    canvas.drawRRect(rrect, paint);
  }
}

/// 便捷方法：创建常用样式的圆角指示器
extension RoundedTabIndicatorExtension on RoundedRectangleTabIndicator {
  /// 创建细线圆角指示器
  static RoundedRectangleTabIndicator thin({
    required Color color,
    double radius = 1.0,
    EdgeInsetsGeometry insets = EdgeInsets.zero,
  }) {
    return RoundedRectangleTabIndicator(
      color: color,
      weight: 2,
      radius: radius,
      insets: insets,
    );
  }

  /// 创建粗线圆角指示器
  static RoundedRectangleTabIndicator thick({
    required Color color,
    double radius = 2.0,
    EdgeInsetsGeometry insets = EdgeInsets.zero,
  }) {
    return RoundedRectangleTabIndicator(
      color: color,
      weight: 4,
      radius: radius,
      insets: insets,
    );
  }

  /// 创建胶囊形指示器
  static RoundedRectangleTabIndicator pill({
    required Color color,
    double weight = 3.0,
    EdgeInsetsGeometry insets = EdgeInsets.zero,
  }) {
    return RoundedRectangleTabIndicator(
      color: color,
      weight: weight,
      radius: weight / 2, // 半径为高度的一半，形成胶囊形
      insets: insets,
    );
  }
}

/// 用于lerp函数的辅助方法
double? lerpDouble(double? a, double? b, double t) {
  if (a == null && b == null) return null;
  a ??= 0.0;
  b ??= 0.0;
  return a + (b - a) * t;
}
