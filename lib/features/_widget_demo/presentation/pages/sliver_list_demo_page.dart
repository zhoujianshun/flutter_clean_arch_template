import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 场景 1：SliverList 全家桶
///
/// 对比 SliverList 的多种构造方式及其适用场景：
/// - `.builder`：懒加载，适合长列表
/// - `.separated`：带分割线
/// - `.list`：固定子项列表
/// - `SliverFixedExtentList`：固定高度，滚动性能最优
/// - `SliverPrototypeExtentList`：用原型 Widget 推算高度
@RoutePage()
class SliverListDemoPage extends StatelessWidget {
  const SliverListDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.medium(title: const Text('SliverList 全家桶')),

          // 说明
          SliverToBoxAdapter(
            child: Card(
              margin: EdgeInsets.all(16.w),
              color: theme.colorScheme.surfaceContainerLow,
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: const Text(
                  'SliverList 有多种构造方式，各适用不同场景。\n'
                  '滚动下方列表，每个分区使用不同的构造器。',
                ),
              ),
            ),
          ),

          // ── SliverList.builder ──
          _buildSectionHeader(context, 'SliverList.builder',
              '懒加载，仅构建可视区域内的 Widget，适合长列表'),
          SliverList.builder(
            itemCount: 5,
            itemBuilder: (context, index) => _buildTile(
              theme, 'builder[$index]', Icons.construction, Colors.blue),
          ),

          // ── SliverList.separated ──
          _buildSectionHeader(context, 'SliverList.separated',
              '自带分割线，等同于 ListView.separated'),
          SliverList.separated(
            itemCount: 5,
            itemBuilder: (context, index) => _buildTile(
              theme, 'separated[$index]', Icons.horizontal_rule, Colors.green),
            separatorBuilder: (context, index) => Divider(
              height: 1,
              indent: 72.w,
            ),
          ),

          // ── SliverList.list ──
          _buildSectionHeader(context, 'SliverList.list',
              '固定子项，一次性构建所有 Widget，适合少量已知内容'),
          SliverList.list(
            children: List.generate(
              3,
              (index) => _buildTile(
                theme, 'list[$index]', Icons.list_alt, Colors.orange),
            ),
          ),

          // ── SliverFixedExtentList ──
          _buildSectionHeader(context, 'SliverFixedExtentList',
              '所有子项固定高度 = 60，滚动性能最优（无需测量）'),
          SliverFixedExtentList(
            itemExtent: 60,
            delegate: SliverChildBuilderDelegate(
              (context, index) => Container(
                margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Text('FixedExtent[$index] — 高度固定 60px',
                    style: theme.textTheme.bodyMedium),
              ),
              childCount: 5,
            ),
          ),

          // ── SliverPrototypeExtentList ──
          _buildSectionHeader(context, 'SliverPrototypeExtentList',
              '用一个"原型 Widget"推算高度，比 Fixed 更灵活'),
          SliverPrototypeExtentList(
            prototypeItem: _buildTile(
              theme, 'prototype', Icons.architecture, Colors.purple),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildTile(
                theme, 'prototype[$index]', Icons.architecture, Colors.purple),
              childCount: 5,
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
                      '• 长列表（100+项）→ .builder 或 FixedExtentList\n'
                      '• 需要分割线 → .separated\n'
                      '• 少量固定内容 → .list\n'
                      '• 所有项等高 → SliverFixedExtentList（性能最优）\n'
                      '• 项高度相同但值不确定 → SliverPrototypeExtentList',
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

  SliverToBoxAdapter _buildSectionHeader(
      BuildContext context, String title, String subtitle) {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            )),
            SizedBox(height: 2.h),
            Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(ThemeData theme, String label, IconData icon, Color color) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label),
      trailing: Icon(Icons.chevron_right, color: theme.colorScheme.outline),
    );
  }
}
