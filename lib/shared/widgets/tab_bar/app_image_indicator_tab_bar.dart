import 'package:flutter/material.dart';

/// 通用图片指示器 TabBar 组件。
///
/// 支持固定尺寸图片 indicator、可选高度/背景色，
/// 并可按需去除点击高亮（overlay/splash）。
class AppImageIndicatorTabBar extends StatelessWidget {
  const AppImageIndicatorTabBar({
    required this.controller,
    required this.tabs,
    required this.indicatorAsset,
    super.key,
    this.height,
    this.backgroundColor,
    this.indicatorWidth = 46,
    this.indicatorHeight = 5,
    this.indicatorBottomPadding = 0,
    this.isScrollable = true,
    this.tabAlignment = TabAlignment.center,
    this.labelColor,
    this.unselectedLabelColor,
    this.labelStyle,
    this.unselectedLabelStyle,
    this.labelPadding,
    this.indicatorSize = TabBarIndicatorSize.label,
    this.removeTapHighlight = false,
  });

  final TabController controller;
  final List<Widget> tabs;
  final String indicatorAsset;
  final double? height;
  final Color? backgroundColor;
  final double indicatorWidth;
  final double indicatorHeight;
  final double indicatorBottomPadding;
  final bool isScrollable;
  final TabAlignment tabAlignment;
  final Color? labelColor;
  final Color? unselectedLabelColor;
  final TextStyle? labelStyle;
  final TextStyle? unselectedLabelStyle;
  final EdgeInsetsGeometry? labelPadding;
  final TabBarIndicatorSize indicatorSize;
  final bool removeTapHighlight;

  @override
  Widget build(BuildContext context) {
    final tabBar = ColoredBox(
      color: backgroundColor ?? Colors.transparent,
      child: TabBar(
        controller: controller,
        isScrollable: isScrollable,
        tabAlignment: tabAlignment,
        labelColor: labelColor,
        unselectedLabelColor: unselectedLabelColor,
        labelStyle: labelStyle,
        unselectedLabelStyle: unselectedLabelStyle,
        labelPadding: labelPadding,
        indicatorSize: indicatorSize,
        indicator: _FixedSizeAssetIndicator(
          image: AssetImage(indicatorAsset),
          width: indicatorWidth,
          height: indicatorHeight,
        ),
        indicatorPadding: EdgeInsets.only(bottom: indicatorBottomPadding),
        overlayColor: removeTapHighlight
            ? WidgetStateProperty.all(Colors.transparent)
            : null,
        splashFactory: removeTapHighlight ? NoSplash.splashFactory : null,
        tabs: tabs,
      ),
    );

    if (height == null) {
      return tabBar;
    }

    return SizedBox(
      height: height,
      child: tabBar,
    );
  }
}

class _FixedSizeAssetIndicator extends Decoration {
  const _FixedSizeAssetIndicator({
    required this.image,
    required this.width,
    required this.height,
  });

  final ImageProvider image;
  final double width;
  final double height;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _FixedSizeAssetIndicatorPainter(this, onChanged);
  }
}

class _FixedSizeAssetIndicatorPainter extends BoxPainter {
  _FixedSizeAssetIndicatorPainter(this.decoration, super.onChanged)
    : _imagePainter = DecorationImage(
        image: decoration.image,
        fit: BoxFit.fill,
      ).createPainter(onChanged ?? () {});

  final _FixedSizeAssetIndicator decoration;
  final DecorationImagePainter _imagePainter;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (size == null) return;

    final rect = Rect.fromLTWH(
      offset.dx + (size.width - decoration.width) / 2,
      offset.dy + size.height - decoration.height,
      decoration.width,
      decoration.height,
    );

    _imagePainter.paint(
      canvas,
      rect,
      null,
      configuration.copyWith(size: rect.size),
    );
  }
}
