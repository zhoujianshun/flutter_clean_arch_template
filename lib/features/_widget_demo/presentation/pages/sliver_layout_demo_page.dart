import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 场景 7：SliverLayoutBuilder
///
/// 根据 SliverConstraints 动态构建布局：
/// - crossAxisExtent → 可用宽度，用于响应式判断
/// - viewportMainAxisExtent → 视口高度
/// - 根据宽度切换单列/双列/三列布局
///
/// 业务场景：响应式列表、平板/手机自适应
@RoutePage()
class SliverLayoutDemoPage extends StatelessWidget {
  const SliverLayoutDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.medium(title: const Text('SliverLayoutBuilder')),

          SliverToBoxAdapter(
            child: Card(
              margin: EdgeInsets.all(16.w),
              color: theme.colorScheme.surfaceContainerLow,
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('核心原理', style: theme.textTheme.titleSmall),
                    SizedBox(height: 8.h),
                    const Text(
                      'SliverLayoutBuilder 类似 LayoutBuilder，但在 Sliver 体系中使用。\n\n'
                      '通过 SliverConstraints 获取：\n'
                      '• crossAxisExtent → 横轴可用宽度\n'
                      '• viewportMainAxisExtent → 视口主轴长度\n'
                      '• precedingScrollExtent → 前面已滚过的距离\n\n'
                      '旋转屏幕或在平板上查看，观察列数自动变化。',
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 动态响应式网格
          SliverLayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.crossAxisExtent;
              final columns = width < 400 ? 2 : (width < 700 ? 3 : 4);

              return SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 8.h,
                    crossAxisSpacing: 8.w,
                    childAspectRatio: 1.2,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildItem(theme, index, columns),
                    childCount: 12,
                  ),
                ),
              );
            },
          ),

          // 宽度信息展示
          SliverLayoutBuilder(
            builder: (context, constraints) {
              return SliverToBoxAdapter(
                child: Card(
                  margin: EdgeInsets.all(16.w),
                  child: Padding(
                    padding: EdgeInsets.all(12.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('当前 Constraints',
                            style: theme.textTheme.titleSmall),
                        SizedBox(height: 8.h),
                        _buildInfoRow(theme, 'crossAxisExtent',
                            '${constraints.crossAxisExtent.toStringAsFixed(1)} px'),
                        _buildInfoRow(theme, 'viewportMainAxisExtent',
                            '${constraints.viewportMainAxisExtent.toStringAsFixed(1)} px'),
                        _buildInfoRow(theme, 'precedingScrollExtent',
                            '${constraints.precedingScrollExtent.toStringAsFixed(1)} px'),
                        _buildInfoRow(theme, '计算列数',
                            constraints.crossAxisExtent < 400
                                ? '2 列（窄屏）'
                                : constraints.crossAxisExtent < 700
                                    ? '3 列（中等）'
                                    : '4 列（宽屏）'),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // 对比说明
          SliverToBoxAdapter(
            child: Card(
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              color: theme.colorScheme.tertiaryContainer,
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('vs MaxCrossAxisExtent',
                        style: theme.textTheme.titleSmall),
                    SizedBox(height: 8.h),
                    const Text(
                      '• MaxCrossAxisExtent：自动计算列数，无法获取精确宽度\n'
                      '• SliverLayoutBuilder：可获取精确宽度，自定义任意布局逻辑\n\n'
                      '适用场景：\n'
                      '• 需要根据宽度切换完全不同的 Sliver 组件时\n'
                      '• 需要宽度值做其他计算时（如间距、字号调整）\n'
                      '• 与项目的 AdaptiveBuilder 配合实现 Sliver 层响应式',
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 更多内容
          SliverList.builder(
            itemCount: 10,
            itemBuilder: (context, index) => ListTile(
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text('额外列表项 ${index + 1}'),
              subtitle: const Text('SliverLayoutBuilder 后可跟任意 Sliver'),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: 32.h)),
        ],
      ),
    );
  }

  Widget _buildItem(ThemeData theme, int index, int columns) {
    return Card(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.widgets_outlined,
                color: theme.colorScheme.primary, size: 24),
            SizedBox(height: 4.h),
            Text('Item $index', style: theme.textTheme.labelMedium),
            Text('$columns 列', style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        children: [
          SizedBox(
            width: 180.w,
            child: Text(label, style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
            )),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            )),
          ),
        ],
      ),
    );
  }
}
