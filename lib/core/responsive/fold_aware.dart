import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_clean_arch_template/core/responsive/breakpoints.dart';
import 'package:flutter_clean_arch_template/core/responsive/constraints_scope.dart';

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
/// iPhone Duo 为连续内屏且折痕极小，理论上 [obstruction] 为 null，
/// 两栏布局可按逻辑折痕（[foldCrease]）对齐分栏线。
///
/// **平台限制**：iOS 上 [MediaQuery.displayFeaturesOf] 恒返回空列表
///（flutter/flutter#192515），因此 [FoldInfo] 在 iOS 上恒为 [none]。
/// 上述「按折痕对齐」的路径当前仅在 Android 折叠屏上生效。
class FoldInfo {
  const FoldInfo({
    this.obstruction,
    this.foldCrease,
    this.isHalfOpened = false,
  });

  /// 解析 [MediaQuery.displayFeaturesOf] 得到折叠姿态。
  ///
  /// 遍历所有 [DisplayFeature]，取首个 hinge 和首个 fold。
  /// 实际设备不会同时出现 hinge + fold，故 [isHalfOpened] 取两者中首个
  /// 非 flat 姿态即可。若同时存在，hinge 优先（[hingeBounds] 也优先返回
  /// [obstruction]）。
  factory FoldInfo.fromContext(BuildContext context) {
    final features = MediaQuery.displayFeaturesOf(context);
    Rect? obstruction;
    Rect? foldCrease;
    var isHalfOpened = false;

    for (final feature in features) {
      switch (feature.type) {
        case DisplayFeatureType.hinge:
          // 取首个 hinge，忽略后续（实际设备至多一个）
          obstruction ??= feature.bounds;
          if (feature.state == DisplayFeatureState.postureHalfOpened) {
            isHalfOpened = true;
          }
        case DisplayFeatureType.fold:
          foldCrease ??= feature.bounds;
          if (feature.state == DisplayFeatureState.postureHalfOpened) {
            isHalfOpened = true;
          }
        // cutout（摄像头开孔）和 unknown 不携带折叠语义，跳过。
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
/// 基于 [LayoutBuilder] 约束宽度选择断点布局，同时暴露 [FoldInfo]，
/// 供两栏布局将分栏线对齐折痕（对齐后内容不会压在铰链上）。
///
/// [FoldInfo] 和 [BoxConstraints] 在同一个 [LayoutBuilder] 回调内读取，
/// 保证两者在同一帧同步更新，避免折叠↔展开过渡帧中状态不一致。
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final fold = FoldInfo.fromContext(context);
        final windowClass = ResponsiveBreakpoints.fromConstraints(constraints);
        final builder = ResponsiveBreakpoints.resolve(
          windowClass: windowClass,
          compact: compact,
          medium: medium,
          expanded: expanded,
        );
        return ConstraintsScope(
          constraints: constraints,
          windowClass: windowClass,
          child: builder(constraints, fold),
        );
      },
    );
  }
}

/// 将子组件拆分到铰链两侧的双面板布局。
///
/// 适用于有物理铰链（[DisplayFeatureType.hinge]）的折叠屏设备，
/// 且仅限**覆盖完整窗口宽度**的场景（如全屏 body）。
///
/// 使用 [fallback] 布局的场景：
/// - 铰链无遮挡（连续屏）或非折叠设备
/// - 嵌套在子面板中（本地宽度 < 窗口宽度）：铰链 bounds 为全局坐标，
///   面板存在未知的水平偏移，无法可靠换算为局部坐标，保守回退
/// - 约束宽度无界
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

        // 无铰链或铰链宽度非法时回退
        if (hinge == null || hinge.width <= 0) {
          return fallback;
        }

        // 无界约束（如横向可滚动区域）无法定位面板，回退
        if (!constraints.hasBoundedWidth) {
          return fallback;
        }

        // 仅当面板覆盖完整窗口宽度时，铰链全局坐标才与本地坐标一致；
        // 嵌套子面板存在未知水平偏移，无法可靠换算为局部坐标，保守回退。
        if (constraints.maxWidth != MediaQuery.sizeOf(context).width) {
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
