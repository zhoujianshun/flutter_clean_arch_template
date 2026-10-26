import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_clean_arch_template/core/responsive/adaptive_builder.dart';
import 'package:flutter_clean_arch_template/core/responsive/breakpoints.dart';

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
/// - [DisplayFeatureType.fold]：折痕，不遮挡内容（连续屏折叠处）
/// - [DisplayFeatureType.cutout]：摄像头开孔，不纳入折叠语义
///
/// 姿态（仅 hinge/fold 有效）：
/// - [DisplayFeatureState.postureFlat]：完全展开
/// - [DisplayFeatureState.postureHalfOpened]：半开（帐篷/笔记本形态）
///
/// **平台限制**：iOS 上 [MediaQuery.displayFeaturesOf] 恒返回空列表
///（flutter/flutter#192515），因此 [FoldInfo] 在 iOS 上恒为 [none]。
///
/// **折痕（fold）说明**：[HingePaneLayout] 仅处理物理铰链（hinge），
/// 不处理折痕。折痕不遮挡内容，分栏布局可自行选择是否按折痕对齐。
@immutable
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
  /// 坐标为窗口全局坐标，不可直接用作局部布局的分栏位置。
  final Rect? obstruction;

  /// 折痕区域（仅 [DisplayFeatureType.fold]，如连续屏折叠处）。
  ///
  /// 折痕不遮挡内容，[HingePaneLayout] 不处理折痕。
  /// 如需按折痕对齐分栏，请自行实现布局逻辑。
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
    return bounds.width > bounds.height
        ? FoldAxis.horizontal
        : FoldAxis.vertical;
  }

  /// 首个铰链或折痕的 bounds（优先铰链）。
  ///
  /// **注意**：此坐标为窗口全局坐标，不可直接用作局部布局的分栏位置。
  /// 局部布局请使用 [HingePaneLayout]，它会自动处理坐标和回退。
  Rect? get _primaryBounds => obstruction ?? foldCrease;

  /// 是否折叠屏设备（有铰链或折痕）。
  bool get isFoldable => obstruction != null || foldCrease != null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FoldInfo &&
        other.obstruction == obstruction &&
        other.foldCrease == foldCrease &&
        other.isHalfOpened == isHalfOpened &&
        listEquals(other.features, features);
  }

  @override
  int get hashCode => Object.hash(
    obstruction,
    foldCrease,
    isHalfOpened,
    Object.hashAll(features),
  );

  @override
  String toString() {
    if (!isFoldable) return 'FoldInfo.none';
    final parts = <String>[
      if (obstruction != null) 'obstruction: $obstruction',
      if (foldCrease != null) 'foldCrease: $foldCrease',
      if (isHalfOpened) 'halfOpened',
      if (axis != null) 'axis: ${axis!.name}',
      'features: ${features.length}',
    ];
    return 'FoldInfo(${parts.join(', ')})';
  }
}

// ---------------------------------------------------------------------------
// 私有工具：窗口覆盖检测
// ---------------------------------------------------------------------------

/// 容差阈值：0.5dp，足以吸收浮点精度差异，
/// 但远小于任何真实 UI 组件（AppBar ≥ 56dp, SafeArea ≥ 20dp）。
const double _windowCoverTolerance = 0.5;

/// 检查约束是否沿指定轴覆盖了完整窗口。
///
/// [FoldAwareBuilder] 和 [HingePaneLayout] 共用此判定，
/// 避免全局坐标在嵌套子面板中被误用为局部分栏位置。
bool _coversWindow(BoxConstraints c, Size window, Axis axis) {
  final (double? local, double global) = switch (axis) {
    Axis.horizontal => (c.hasBoundedWidth ? c.maxWidth : null, window.width),
    Axis.vertical => (c.hasBoundedHeight ? c.maxHeight : null, window.height),
  };
  return local != null && (local - global).abs() < _windowCoverTolerance;
}

/// 为分栏后的 pane 移除 displayFeatures，
/// 避免子树中的 [FoldAwareBuilder] / [HingePaneLayout] 重新读到同一铰链。
Widget _wrapPaneWithCleanedFeatures(BuildContext context, Widget child) {
  final data = MediaQuery.of(context);
  if (data.displayFeatures.isEmpty) return child;
  return MediaQuery(
    data: data.copyWith(displayFeatures: const []),
    child: child,
  );
}

// ---------------------------------------------------------------------------
// FoldAwareBuilder
// ---------------------------------------------------------------------------

/// 组合约束 + 折叠姿态的自适应布局构建器。
///
/// 基于 [LayoutBuilder] 约束宽度选择断点布局，同时暴露 [FoldInfo]，
/// 供折叠屏设备做姿态感知的布局决策。
///
/// [FoldInfo] 和 [BoxConstraints] 在同一个 [LayoutBuilder] 回调内读取，
/// 保证两者在同一帧同步更新，避免折叠↔展开过渡帧中状态不一致。
///
/// **安全保护**：当组件不覆盖铰链对应轴向的完整窗口尺寸时（如嵌套在
/// NavigationRail 旁的面板、弹窗、带 AppBar/bottomNavigationBar 的
/// Scaffold body 等），自动将 [FoldInfo] 替换为 [FoldInfo.none]，
/// 避免全局坐标被误用为局部分栏位置。校验按铰链轴向匹配：
/// 垂直铰链（左右分栏）要求宽度覆盖完整窗口；水平铰链（上下分栏）
/// 要求高度覆盖完整窗口——与 [HingePaneLayout] 的分栏逻辑对齐。
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
        // 按铰链轴向匹配校验——垂直铰链（左右分栏）依赖横向坐标对齐，
        // 仅要求宽度覆盖；水平铰链（上下分栏）仅要求高度覆盖。
        // 与 HingePaneLayout 的分栏轴向逻辑保持一致。
        final windowSize = MediaQuery.sizeOf(context);
        final coversWindowAxis = switch (rawFold.axis) {
          // 水平铰链（上下分栏）→ 检查高度是否覆盖完整窗口
          FoldAxis.horizontal => _coversWindow(
            constraints,
            windowSize,
            Axis.vertical,
          ),
          // 垂直铰链（左右分栏）或无铰链 → 检查宽度是否覆盖完整窗口
          FoldAxis.vertical || null => _coversWindow(
            constraints,
            windowSize,
            Axis.horizontal,
          ),
        };
        final fold = coversWindowAxis ? rawFold : FoldInfo.none;

        final windowClass = ResponsiveBreakpoints.fromConstraints(
          context,
          constraints,
        );
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

// ---------------------------------------------------------------------------
// HingePaneLayout
// ---------------------------------------------------------------------------

/// 将子组件拆分到铰链两侧的双面板布局（支持垂直和水平铰链）。
///
/// 自动检测铰链方向：
/// - **垂直铰链**（[FoldAxis.vertical]）：使用 [Row]，左右分栏
/// - **水平铰链**（[FoldAxis.horizontal]）：使用 [Column]，上下分栏
///
/// 仅处理物理铰链（[DisplayFeatureType.hinge]），不处理折痕（fold）。
/// **使用契约**：组件必须覆盖完整窗口（如全屏 body、`MaterialApp.builder`），
/// 每个 pane 内部自带 `Scaffold` / `AppBar`。这与官方
/// [DisplayFeatureSubScreen] 和 `dual_screen` 包 `TwoPane` 的推荐用法一致。
///
/// 使用 [fallback] 布局的场景：
/// - 无物理铰链或非折叠设备
/// - 嵌套在子面板中（约束尺寸 ≠ 窗口尺寸），铰链 bounds 为全局坐标不可用
/// - 约束宽度/高度无界
/// - pane 尺寸计算后不合法（≤ 0）
///
/// 分栏成功后，子树中的 [MediaQuery.displayFeaturesOf] 将不再包含铰链信息，
/// 避免嵌套的 [FoldAwareBuilder] / [HingePaneLayout] 重复使用同一铰链。
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
          if (!_coversWindow(constraints, windowSize, Axis.horizontal)) {
            return fallback;
          }

          final firstWidth = hinge.left - hingeMargin;
          if (firstWidth <= 0) return fallback;

          return Row(
            children: [
              SizedBox(
                width: firstWidth,
                child: _wrapPaneWithCleanedFeatures(context, first),
              ),
              SizedBox(width: hinge.width + hingeMargin * 2),
              Expanded(child: _wrapPaneWithCleanedFeatures(context, second)),
            ],
          );
        } else {
          if (!_coversWindow(constraints, windowSize, Axis.vertical)) {
            return fallback;
          }

          final firstHeight = hinge.top - hingeMargin;
          if (firstHeight <= 0) return fallback;

          return Column(
            children: [
              SizedBox(
                height: firstHeight,
                child: _wrapPaneWithCleanedFeatures(context, first),
              ),
              SizedBox(height: hinge.height + hingeMargin * 2),
              Expanded(child: _wrapPaneWithCleanedFeatures(context, second)),
            ],
          );
        }
      },
    );
  }
}
