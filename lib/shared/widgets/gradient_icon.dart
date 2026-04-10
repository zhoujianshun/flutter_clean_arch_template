import 'package:flutter/material.dart';

/// 渐变色图标组件
/// 支持线性和径向渐变
class GradientIcon extends StatelessWidget {
  const GradientIcon({
    required this.icon,
    required this.gradient,
    this.size = 24.0,
    super.key,
  });

  /// 图标数据
  final IconData icon;

  /// 渐变配置
  final Gradient gradient;

  /// 图标大小
  final double size;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: gradient.createShader,
      child: Icon(
        icon,
        size: size,
        color: Colors.white, // 必须设置为白色才能显示渐变
      ),
    );
  }
}

/// 线性渐变图标组件
class LinearGradientIcon extends StatelessWidget {
  const LinearGradientIcon({
    required this.icon,
    required this.colors,
    this.size = 24.0,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
    this.stops,
    super.key,
  });

  /// 图标数据
  final IconData icon;

  /// 渐变颜色列表
  final List<Color> colors;

  /// 图标大小
  final double size;

  /// 渐变开始位置
  final Alignment begin;

  /// 渐变结束位置
  final Alignment end;

  /// 颜色停止点
  final List<double>? stops;

  @override
  Widget build(BuildContext context) {
    return GradientIcon(
      icon: icon,
      size: size,
      gradient: LinearGradient(
        colors: colors,
        begin: begin,
        end: end,
        stops: stops,
      ),
    );
  }
}

/// 径向渐变图标组件
class RadialGradientIcon extends StatelessWidget {
  const RadialGradientIcon({
    required this.icon,
    required this.colors,
    this.size = 24.0,
    this.center = Alignment.center,
    this.radius = 0.5,
    this.stops,
    super.key,
  });

  /// 图标数据
  final IconData icon;

  /// 渐变颜色列表
  final List<Color> colors;

  /// 图标大小
  final double size;

  /// 渐变中心点
  final Alignment center;

  /// 渐变半径
  final double radius;

  /// 颜色停止点
  final List<double>? stops;

  @override
  Widget build(BuildContext context) {
    return GradientIcon(
      icon: icon,
      size: size,
      gradient: RadialGradient(
        colors: colors,
        center: center,
        radius: radius,
        stops: stops,
      ),
    );
  }
}
