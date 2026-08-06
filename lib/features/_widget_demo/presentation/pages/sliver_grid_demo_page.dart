import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 场景 2：SliverGrid 多种布局
///
/// 对比不同 GridDelegate 的行为：
/// - `SliverGridDelegateWithFixedCrossAxisCount`：固定列数
/// - `SliverGridDelegateWithMaxCrossAxisExtent`：最大宽度自适应列数
/// - 便捷构造：`SliverGrid.count`, `SliverGrid.extent`
@RoutePage()
class SliverGridDemoPage extends StatelessWidget {
  const SliverGridDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.medium(title: const Text('SliverGrid 多种布局')),

          _buildSection(context, 'FixedCrossAxisCount（固定 2 列）',
              '无论屏幕宽度如何，始终 2 列'),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8.h,
                crossAxisSpacing: 8.w,
                childAspectRatio: 1.5,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildGridItem(theme, index, Colors.blue),
                childCount: 6,
              ),
            ),
          ),

          _buildSection(context, 'MaxCrossAxisExtent（最大宽度 180）',
              '每项最大宽度 180，列数自动计算，横屏/平板列数更多'),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 180,
                mainAxisSpacing: 8.h,
                crossAxisSpacing: 8.w,
                childAspectRatio: 1.2,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildGridItem(theme, index, Colors.teal),
                childCount: 9,
              ),
            ),
          ),

          _buildSection(context, 'SliverGrid.count（便捷 3 列）',
              '等同于 FixedCrossAxisCount(crossAxisCount: 3)'),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            sliver: SliverGrid.count(
              crossAxisCount: 3,
              mainAxisSpacing: 8.h,
              crossAxisSpacing: 8.w,
              children: List.generate(
                6,
                (index) => _buildGridItem(theme, index, Colors.orange),
              ),
            ),
          ),

          _buildSection(context, 'SliverGrid.extent（便捷最大 120）',
              '等同于 MaxCrossAxisExtent(maxCrossAxisExtent: 120)'),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            sliver: SliverGrid.extent(
              maxCrossAxisExtent: 120,
              mainAxisSpacing: 8.h,
              crossAxisSpacing: 8.w,
              children: List.generate(
                8,
                (index) => _buildGridItem(theme, index, Colors.purple),
              ),
            ),
          ),

          // 总结
          SliverToBoxAdapter(
            child: Card(
              margin: EdgeInsets.all(16.w),
              color: theme.colorScheme.surfaceContainerLow,
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('选择建议', style: theme.textTheme.titleSmall),
                    SizedBox(height: 8.h),
                    const Text(
                      '• 固定列数（不管屏幕大小）→ FixedCrossAxisCount\n'
                      '• 自适应列数（平板/横屏更多列）→ MaxCrossAxisExtent\n'
                      '• .count / .extent 是便捷构造器，适合子项已知的情况\n'
                      '• 需要懒加载 → 使用 SliverGrid + SliverChildBuilderDelegate\n'
                      '• childAspectRatio 控制宽高比（默认 1.0 即正方形）',
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: 32.h)),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildSection(
      BuildContext context, String title, String subtitle) {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 8.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
            SizedBox(height: 2.h),
            Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(ThemeData theme, int index, Color color) {
    return Card(
      color: color.withValues(alpha: 0.08),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_outlined, color: color, size: 28),
            SizedBox(height: 4.h),
            Text('Item $index', style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
