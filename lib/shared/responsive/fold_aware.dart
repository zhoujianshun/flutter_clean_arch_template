import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_clean_arch_template/shared/responsive/adaptive_builder.dart';

/// 折叠屏姿态信息（来自 [MediaQuery.displayFeaturesOf]）。
///
/// 三种 [DisplayFeatureType]：
/// - [DisplayFeatureType.hinge]：物理铰链，**遮挡**内容（Galaxy Fold 等）
/// - [DisplayFeatureType.fold]：折痕，不遮挡内容（iPhone Duo 等连续屏）
/// - [DisplayFeatureType.cutout]：摄像头开孔，不纳入折叠语义
///
/// 姿态（仅 hinge/fold 有效）：
/// - [DisplayFeatureState.postureFlat]：完全展开
/// - [DisplayFeatureState.postureHalfOpened]：半开（帐篷/笔记本形态）
///
/// iPhone Duo 为连续内屏且折痕极小，[obstruction] 通常为 null，
/// 两栏布局的分栏线按逻辑折痕（[foldCrease]）对齐即可。
class FoldInfo {
  const FoldInfo({
    this.obstruction,
    this.foldCrease,
    this.isHalfOpened = false,
  });

  /// 解析 [MediaQuery.displayFeaturesOf] 得到折叠姿态。
  factory FoldInfo.fromContext(BuildContext context) {
    final features = MediaQuery.displayFeaturesOf(context);
    Rect? obstruction;
    Rect? foldCrease;
    var isHalfOpened = false;

    for (final feature in features) {
      switch (feature.type) {
        case DisplayFeatureType.hinge:
          obstruction = feature.bounds;
          isHalfOpened = feature.state == DisplayFeatureState.postureHalfOpened;
        case DisplayFeatureType.fold:
          foldCrease = feature.bounds;
          isHalfOpened = feature.state == DisplayFeatureState.postureHalfOpened;
        case DisplayFeatureType.cutout:
        case DisplayFeatureType.unknown:
          break;
      }
    }

    return FoldInfo(
      obstruction: obstruction,
      foldCrease: foldCrease,
      isHalfOpened: isHalfOpened,
    );
  }

  /// 无折叠姿态的普通设备。
  static const FoldInfo none = FoldInfo();

  /// 物理铰链遮挡区域（仅 [DisplayFeatureType.hinge]）。
  ///
  /// 铰链会遮挡屏幕内容，需要避让。null 表示无铰链。
  final Rect? obstruction;

  /// 折痕区域（仅 [DisplayFeatureType.fold]，如连续屏折叠处）。
  ///
  /// 折痕不遮挡内容，但可作为两栏布局的天然分隔参考线。
  final Rect? foldCrease;

  /// 设备是否处于半开姿态（帐篷/笔记本形态）。
  final bool isHalfOpened;

  /// 铰链或折痕区域（优先铰链），用于两栏布局分栏参考。
  Rect? get hingeBounds => obstruction ?? foldCrease;

  /// 是否折叠屏设备（有铰链或折痕）。
  bool get isFoldable => obstruction != null || foldCrease != null;
}

/// 组合约束 + 折叠姿态的自适应布局构建器。
///
/// 在 [AdaptiveLayoutBuilder] 语义之上额外暴露 [FoldInfo]，
/// 供两栏布局将分栏线对齐折痕（对齐后内容不会压在铰链上）。
///
/// ```dart
/// FoldAwareBuilder(
///   compact: (_, __) => ListPage(),
///   medium: (constraints, fold) => TwoPane(
///     dividerPosition: fold.hingeBounds?.left ?? constraints.maxWidth * 0.4,
///   ),
/// )
/// ```
class FoldAwareBuilder extends StatelessWidget {
  const FoldAwareBuilder({
    required this.compact,
    super.key,
    this.medium,
    this.expanded,
  });

  /// 紧凑布局构建器（手机），宽度 < 600dp
  final Widget Function(BoxConstraints constraints, FoldInfo fold) compact;

  /// 中等布局构建器（平板竖屏），宽度 600-839dp
  final Widget Function(BoxConstraints constraints, FoldInfo fold)? medium;

  /// 扩展布局构建器（平板横屏/桌面），宽度 >= 840dp
  final Widget Function(BoxConstraints constraints, FoldInfo fold)? expanded;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final fold = FoldInfo.fromContext(context);
        return AdaptiveLayoutBuilder(
          compact: (constraints) => compact(constraints, fold),
          medium: medium == null
              ? null
              : (constraints) => medium!(constraints, fold),
          expanded: expanded == null
              ? null
              : (constraints) => expanded!(constraints, fold),
        );
      },
    );
  }
}

/// 将子组件拆分到铰链两侧的双面板布局。
///
/// 适用于有物理铰链（[DisplayFeatureType.hinge]）的折叠屏设备。
/// 铰链无遮挡（连续屏）或非折叠设备时，使用 [fallback] 布局。
///
/// 对话框等浮层避铰链请直接使用官方 [DisplayFeatureSubScreen]。
class HingeSplitLayout extends StatelessWidget {
  const HingeSplitLayout({
    required this.left,
    required this.right,
    required this.fallback,
    super.key,
    this.hingeMargin = 0,
  });

  /// 铰链左侧内容。
  final Widget left;

  /// 铰链右侧内容。
  final Widget right;

  /// 非折叠设备或无铰链时使用的默认布局。
  final Widget fallback;

  /// 铰链两侧的额外安全间距。
  final double hingeMargin;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fold = FoldInfo.fromContext(context);
        final hinge = fold.obstruction;

        // 无铰链或铰链不在本地可用宽度内（如嵌套在子面板）时回退
        if (hinge == null ||
            hinge.width <= 0 ||
            hinge.right > constraints.maxWidth) {
          return fallback;
        }

        final leftWidth = hinge.left - hingeMargin;
        final rightWidth = constraints.maxWidth - hinge.right - hingeMargin;

        if (leftWidth <= 0 || rightWidth <= 0) {
          return fallback;
        }

        return Row(
          children: [
            SizedBox(width: leftWidth, child: left),
            SizedBox(width: hinge.width + hingeMargin * 2),
            SizedBox(width: rightWidth, child: right),
          ],
        );
      },
    );
  }
}
