import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_clean_arch_template/core/responsive/breakpoints.dart';
import 'package:flutter_clean_arch_template/core/responsive/constraints_scope.dart';

/// 铰链/折痕的方向轴。
///
/// 从 [DisplayFeature.bounds] 的长边方向推导：
/// - [vertical]：铰链竖直，左右分屏（如 Galaxy Fold 展开态）
/// - [horizontal]：铰链水平，上下分屏（如笔记本形态/帐篷形态）
enum FoldAxis {
  /// 垂直铰链——左右分栏。
  vertical,

  /// 水平铰链——上下分栏。
  horizontal,
}

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
    this.features = const [],
  });

  /// 解析 [MediaQuery.displayFeaturesOf] 得到折叠姿态。
  ///
  /// 遍历所有 [DisplayFeature]，取首个 hinge 和首个 fold。
  /// 实际设备不会同时出现 hinge + fold，故 [isHalfOpened] 取两者中首个
  /// 非 flat 姿态即可。若同时存在，hinge 优先。
  factory FoldInfo.fromContext(BuildContext context) {
    final rawFeatures = MediaQuery.displayFeaturesOf(context);
    Rect? obstruction;
    Rect? foldCrease;
    var isHalfOpened = false;
    final filteredFeatures = <DisplayFeature>[];

    for (final feature in rawFeatures) {
      switch (feature.type) {
        case DisplayFeatureType.hinge:
          obstruction ??= feature.bounds;
          filteredFeatures.add(feature);
          if (feature.state == DisplayFeatureState.postureHalfOpened) {
            isHalfOpened = true;
          }
        case DisplayFeatureType.fold:
          foldCrease ??= feature.bounds;
          filteredFeatures.add(feature);
          if (feature.state == DisplayFeatureState.postureHalfOpened) {
            isHalfOpened = true;
          }
        case DisplayFeatureType.cutout:
        case DisplayFeatureType.unknown:
          break;
      }
    }

    return FoldInfo(
      obstruction: obstruction,
      foldCrease: foldCrease,
      isHalfOpened: isHalfOpened,
      features: List.unmodifiable(filteredFeatures),
    );
  }

  /// 无折叠姿态的普通设备。
  static const FoldInfo none = FoldInfo();

  /// 物理铰链遮挡区域（仅 [DisplayFeatureType.hinge]）。
  ///
  /// 铰链会遮挡屏幕内容，需要避让。null 表示无铰链。
  @visibleForTesting
  final Rect? obstruction;

  /// 折痕区域（仅 [DisplayFeatureType.fold]，如连续屏折叠处）。
  ///
  /// 折痕不遮挡内容，但可作为两栏布局的天然分隔参考线。
  @visibleForTesting
  final Rect? foldCrease;

  /// 设备是否处于半开姿态（帐篷/笔记本形态）。
  final bool isHalfOpened;

  /// 过滤后的折叠特征列表（不可变，仅包含 hinge 和 fold）。
  ///
  /// 保留完整的 [DisplayFeature] 信息，供高级用法使用。
  final List<DisplayFeature> features;

  /// 主铰链/折痕的方向轴。
  ///
  /// 从 bounds 的宽高比推导：宽 > 高 → 水平铰链（上下分栏），
  /// 否则 → 垂直铰链（左右分栏）。无铰链/折痕时返回 null。
  FoldAxis? get axis {
    final bounds = _primaryBounds;
    if (bounds == null) return null;
    return bounds.width > bounds.height ? FoldAxis.horizontal : FoldAxis.vertical;
  }

  /// 首个铰链或折痕的 bounds（优先铰链）。
  ///
  /// **注意**：此坐标为窗口全局坐标，不可直接用作局部布局的分栏位置。
  /// 局部布局请使用 [HingePaneLayout]，它会自动处理坐标和回退。
  Rect? get _primaryBounds => obstruction ?? foldCrease;

  /// 是否折叠屏设备（有铰链或折痕）。
  bool get isFoldable => obstruction != null || foldCrease != null;
}

/// 组合约束 + 折叠姿态的自适应布局构建器。
///
/// 基于 [LayoutBuilder] 约束宽度选择断点布局，同时暴露 [FoldInfo]，
/// 供折叠屏设备做姿态感知的布局决策。
///
/// [FoldInfo] 和 [BoxConstraints] 在同一个 [LayoutBuilder] 回调内读取，
/// 保证两者在同一帧同步更新，避免折叠↔展开过渡帧中状态不一致。
///
/// **安全保护**：当组件不覆盖完整窗口宽度时（嵌套在 NavigationRail 旁的
/// 面板、弹窗等），自动将 [FoldInfo] 替换为 [FoldInfo.none]，
/// 避免全局坐标被误用为局部分栏位置。
///
/// ```dart
/// FoldAwareBuilder(
///   compact: (_, __) => ListPage(),
///   medium: (constraints, fold) => HingePaneLayout(
///     first: MasterList(),
///     second: DetailView(),
///     fallback: SplitView(ratio: 0.4),
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
        final rawFold = FoldInfo.fromContext(context);

        // 非全窗口场景：全局坐标不匹配局部约束，安全回退。
        final isFullWindow = constraints.hasBoundedWidth &&
            constraints.maxWidth == MediaQuery.sizeOf(context).width;
        final fold = isFullWindow ? rawFold : FoldInfo.none;

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

/// 将子组件拆分到铰链两侧的双面板布局（支持垂直和水平铰链）。
///
/// 自动检测铰链方向：
/// - **垂直铰链**（[FoldAxis.vertical]）：使用 [Row]，左右分栏
/// - **水平铰链**（[FoldAxis.horizontal]）：使用 [Column]，上下分栏
///
/// 适用于有物理铰链（[DisplayFeatureType.hinge]）的折叠屏设备，
/// 且仅限**覆盖完整窗口**的场景（如全屏 body）。
///
/// 使用 [fallback] 布局的场景：
/// - 铰链无遮挡（连续屏）或非折叠设备
/// - 嵌套在子面板中（本地尺寸 < 窗口尺寸）：铰链 bounds 为全局坐标，
///   面板存在未知偏移，无法可靠换算为局部坐标，保守回退
/// - 约束宽度/高度无界
/// - pane 尺寸计算后不合法（≤ 0）
///
/// 对话框等浮层避铰链请直接使用官方 [DisplayFeatureSubScreen]。
class HingePaneLayout extends StatelessWidget {
  const HingePaneLayout({
    required this.first,
    required this.second,
    required this.fallback,
    super.key,
    this.hingeMargin = 0,
  });

  /// 铰链第一侧内容（垂直铰链为左侧，水平铰链为上方）。
  final Widget first;

  /// 铰链第二侧内容（垂直铰链为右侧，水平铰链为下方）。
  final Widget second;

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

        if (hinge == null || (hinge.width <= 0 && hinge.height <= 0)) {
          return fallback;
        }

        final axis = fold.axis;
        if (axis == null) return fallback;

        final windowSize = MediaQuery.sizeOf(context);

        if (axis == FoldAxis.vertical) {
          if (!constraints.hasBoundedWidth) return fallback;
          if (constraints.maxWidth != windowSize.width) return fallback;

          final firstWidth = hinge.left - hingeMargin;
          final secondWidth = constraints.maxWidth - hinge.right - hingeMargin;
          if (firstWidth <= 0 || secondWidth <= 0) return fallback;

          return Row(
            children: [
              SizedBox(width: firstWidth, child: first),
              SizedBox(width: hinge.width + hingeMargin * 2),
              SizedBox(width: secondWidth, child: second),
            ],
          );
        } else {
          if (!constraints.hasBoundedHeight) return fallback;
          if (constraints.maxHeight != windowSize.height) return fallback;

          final firstHeight = hinge.top - hingeMargin;
          final secondHeight =
              constraints.maxHeight - hinge.bottom - hingeMargin;
          if (firstHeight <= 0 || secondHeight <= 0) return fallback;

          return Column(
            children: [
              SizedBox(height: firstHeight, child: first),
              SizedBox(height: hinge.height + hingeMargin * 2),
              SizedBox(height: secondHeight, child: second),
            ],
          );
        }
      },
    );
  }
}
