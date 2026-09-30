import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/shared/responsive/fold_aware.dart';

/// 折叠屏适配示例
///
/// 演示 fold_aware.dart 提供的三项能力：
/// 1. [FoldInfo] —— 读取折叠姿态（铰链/折痕/半开）
/// 2. [FoldAwareBuilder] —— 断点布局 + 分栏线对齐折痕
/// 3. [HingeSplitLayout] —— 交互元素物理避让铰链
///
/// 由于 displayFeatures 只在 Android 折叠屏上由系统填充，
/// 普通设备/模拟器上 [FoldInfo] 恒为 none。因此本页提供
/// 「模拟铰链」开关：开启后通过 [MediaQuery] 覆盖注入虚拟铰链，
/// 便于在没有真机的情况下演示和调试。
@RoutePage()
class FoldAwareDemoPage extends StatefulWidget {
  const FoldAwareDemoPage({super.key});

  @override
  State<FoldAwareDemoPage> createState() => _FoldAwareDemoPageState();
}

class _FoldAwareDemoPageState extends State<FoldAwareDemoPage> {
  /// 模拟铰链：Android 真机外通常无 displayFeatures，手动注入以便演示
  bool _simulateHinge = false;

  /// 模拟半开姿态（帐篷/笔记本形态）
  bool _simulateHalfOpened = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('折叠屏适配示例')),
      body: _withSimulatedDisplayFeatures(
        child: _buildBody(context),
      ),
    );
  }

  /// 无模拟时原样返回；开启模拟时注入虚拟 hinge feature。
  ///
  /// 真实设备上系统的 displayFeatures 会与模拟值合并——
  /// 真机折叠屏建议关闭模拟开关观察真实数据。
  Widget _withSimulatedDisplayFeatures({required Widget child}) {
    if (!_simulateHinge) return child;

    return Builder(
      builder: (context) {
        final size = MediaQuery.sizeOf(context);
        // 铰链竖直横贯屏幕、位于水平中线附近（模拟 Galaxy Fold 形态）
        final hingeLeft = size.width / 2 - 5;
        final simulatedHinge = DisplayFeature(
          bounds: Rect.fromLTRB(hingeLeft, 0, hingeLeft + 10, size.height),
          type: DisplayFeatureType.hinge,
          state: _simulateHalfOpened
              ? DisplayFeatureState.postureHalfOpened
              : DisplayFeatureState.postureFlat,
        );

        final existing = MediaQuery.displayFeaturesOf(context);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            displayFeatures: [...existing, simulatedHinge],
          ),
          child: child,
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSimulatorControls(context),
        const SizedBox(height: 16),
        _buildFoldInfoCard(context),
        const SizedBox(height: 16),
        _buildFoldAwareBuilderDemo(context),
        const SizedBox(height: 16),
        _buildHingeSplitDemo(context),
      ],
    );
  }

  /// 模拟控制区：普通设备上用来演示折叠屏效果
  Widget _buildSimulatorControls(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bug_report_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text('模拟铰链（调试用）', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'displayFeatures 仅 Android 折叠屏由系统填充， '
              '普通设备开启模拟后可预览折叠屏布局效果',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('注入虚拟铰链'),
              value: _simulateHinge,
              onChanged: (v) => setState(() => _simulateHinge = v),
            ),
            if (_simulateHinge)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('半开姿态（帐篷模式）'),
                value: _simulateHalfOpened,
                onChanged: (v) => setState(() => _simulateHalfOpened = v),
              ),
          ],
        ),
      ),
    );
  }

  /// 能力 1：FoldInfo 姿态信息展示
  Widget _buildFoldInfoCard(BuildContext context) {
    final fold = FoldInfo.fromContext(context);
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.screen_rotation_alt_outlined, color: scheme.primary),
                const SizedBox(width: 8),
                Text('FoldInfo 姿态解析', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'isFoldable（是否折叠屏）',
              value: fold.isFoldable ? 'true' : 'false',
              highlighted: fold.isFoldable,
            ),
            _InfoRow(
              label: 'obstruction（物理铰链/遮挡）',
              value: fold.obstruction?.toString() ?? 'null',
              highlighted: fold.obstruction != null,
            ),
            _InfoRow(
              label: 'foldCrease（折痕/不遮挡）',
              value: fold.foldCrease?.toString() ?? 'null',
              highlighted: fold.foldCrease != null,
            ),
            _InfoRow(
              label: 'isHalfOpened（半开姿态）',
              value: fold.isHalfOpened ? 'true' : 'false',
              highlighted: fold.isHalfOpened,
            ),
            _InfoRow(
              label: 'hingeBounds（分栏参考线）',
              value: fold.hingeBounds?.toString() ?? 'null',
              highlighted: fold.hingeBounds != null,
            ),
            if (fold.isHalfOpened)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.laptop_mac, color: scheme.onTertiaryContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '半开姿态：可做帐篷/笔记本形态的专属 UI '
                        '（如上半屏视频 + 下半屏控制）',
                        style: TextStyle(color: scheme.onTertiaryContainer),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 能力 2：FoldAwareBuilder 分栏对齐折痕
  Widget _buildFoldAwareBuilderDemo(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.vertical_split_outlined, color: scheme.primary),
                const SizedBox(width: 8),
                Text('FoldAwareBuilder 分栏', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '分栏线优先对齐铰链/折痕左侧；无铰链时按断点比例分栏',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: FoldAwareBuilder(
                compact: (_, _) => _PanePlaceholder(
                  label: 'Compact\n单栏列表',
                  color: scheme.surfaceContainerHighest,
                ),
                medium: (constraints, fold) => _buildAlignedSplit(
                  constraints,
                  fold,
                  scheme,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 分栏线对齐 hingeBounds.left；铰链区域本身留空
  Widget _buildAlignedSplit(
    BoxConstraints constraints,
    FoldInfo fold,
    ColorScheme scheme,
  ) {
    final hingeBounds = fold.hingeBounds;
    final masterWidth = hingeBounds?.left ?? constraints.maxWidth * 0.4;
    final hingeWidth = fold.obstruction?.width ?? 0;

    return Row(
      children: [
        SizedBox(
          width: masterWidth,
          child: _PanePlaceholder(
            label: 'Master\n宽度对齐折痕',
            color: scheme.primaryContainer,
          ),
        ),
        if (hingeWidth > 0)
          SizedBox(
            width: hingeWidth,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
              child: Icon(
                Icons.more_vert,
                color: scheme.outline,
                size: 16,
              ),
            ),
          ),
        Expanded(
          child: _PanePlaceholder(
            label: 'Detail',
            color: scheme.secondaryContainer,
          ),
        ),
      ],
    );
  }

  /// 能力 3：HingeSplitLayout 物理避让铰链
  Widget _buildHingeSplitDemo(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.call_split_outlined, color: scheme.primary),
                const SizedBox(width: 8),
                Text('HingeSplitLayout 避让铰链', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '交互按钮拆分到铰链两侧；无铰链设备自动回退单排布局',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: HingeSplitLayout(
                hingeMargin: 8,
                left: _PanePlaceholder(
                  label: '拍摄',
                  color: scheme.primaryContainer,
                  center: true,
                ),
                right: _PanePlaceholder(
                  label: '相册',
                  color: scheme.secondaryContainer,
                  center: true,
                ),
                fallback: Row(
                  children: [
                    Expanded(
                      child: _PanePlaceholder(
                        label: '拍摄 ｜ 相册（普通设备）',
                        color: scheme.surfaceContainerHighest,
                        center: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 面板占位：演示分栏区域
class _PanePlaceholder extends StatelessWidget {
  const _PanePlaceholder({
    required this.label,
    required this.color,
    this.center = false,
  });

  final String label;
  final Color color;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: center ? Alignment.center : null,
      padding: const EdgeInsets.all(12),
      child: center
          ? Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall,
            )
          : Align(
              alignment: Alignment.topLeft,
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
    );
  }
}

/// 信息行：展示 FoldInfo 解析结果
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 200,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: highlighted
                    ? scheme.primaryContainer.withValues(alpha: 0.5)
                    : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color: highlighted
                          ? scheme.onPrimaryContainer
                          : scheme.onSurfaceVariant,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
