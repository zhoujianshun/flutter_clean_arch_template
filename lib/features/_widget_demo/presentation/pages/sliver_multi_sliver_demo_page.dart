import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 场景 7：多 Sliver 组合布局
///
/// 演示 SliverAppBar 与其他 Sliver 组件的组合使用：
/// - `SliverToBoxAdapter` → 插入普通 Widget
/// - `SliverList` → 普通列表
/// - `SliverGrid` → 网格布局
/// - `SliverPersistentHeader` → 自定义吸顶标题
/// - `SliverPadding` → 为 Sliver 添加内边距
///
/// 业务场景：首页复杂布局、商城首页
@RoutePage()
class SliverMultiSliverDemoPage extends StatelessWidget {
  const SliverMultiSliverDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar ──
          SliverAppBar(
            pinned: true,
            expandedHeight: 200.h,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('商城首页'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.tertiary,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.storefront_outlined,
                    size: 60,
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),

          // ── SliverToBoxAdapter: Banner 区域 ──
          SliverToBoxAdapter(
            child: Container(
              margin: EdgeInsets.all(16.w),
              height: 120.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primaryContainer,
                    theme.colorScheme.tertiaryContainer,
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.campaign_outlined, size: 32,
                        color: theme.colorScheme.onPrimaryContainer),
                    SizedBox(height: 4.h),
                    Text(
                      'SliverToBoxAdapter：可插入任意 Widget',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── SliverPersistentHeader: 吸顶分区标题 ──
          _buildSectionHeader(context, 'SliverGrid：推荐商品', Icons.grid_view),

          // ── SliverPadding + SliverGrid ──
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            sliver: SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8.h,
                crossAxisSpacing: 8.w,
                childAspectRatio: 1.2,
              ),
              itemCount: 4,
              itemBuilder: (context, index) => Card(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      [Icons.laptop, Icons.phone_android,
                       Icons.headphones, Icons.watch][index],
                      size: 36,
                      color: theme.colorScheme.primary,
                    ),
                    SizedBox(height: 8.h),
                    Text('商品 ${index + 1}',
                        style: theme.textTheme.titleSmall),
                    Text('¥${(index + 1) * 999}',
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.bold,
                        )),
                  ],
                ),
              ),
            ),
          ),

          // ── SliverPersistentHeader: 吸顶标题 ──
          _buildSectionHeader(context, 'SliverList：热销排行', Icons.trending_up),

          // ── SliverList ──
          SliverList.builder(
            itemCount: 5,
            itemBuilder: (context, index) => ListTile(
              leading: CircleAvatar(
                backgroundColor: index < 3
                    ? theme.colorScheme.error
                    : theme.colorScheme.surfaceContainerHighest,
                foregroundColor: index < 3 ? Colors.white : null,
                child: Text('${index + 1}'),
              ),
              title: Text('热销商品 ${index + 1}'),
              subtitle: Text('已售 ${(5 - index) * 1000}+ 件'),
              trailing: Text('¥${(index + 1) * 199}'),
            ),
          ),

          // ── SliverPersistentHeader ──
          _buildSectionHeader(context, 'SliverGrid：分类入口', Icons.category),

          // ── SliverPadding + SliverGrid: 分类入口 ──
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            sliver: SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8.h,
                crossAxisSpacing: 8.w,
              ),
              itemCount: 8,
              itemBuilder: (context, index) {
                final categories = [
                  ('手机', Icons.phone_android),
                  ('电脑', Icons.laptop),
                  ('耳机', Icons.headphones),
                  ('手表', Icons.watch),
                  ('相机', Icons.camera_alt),
                  ('游戏', Icons.sports_esports),
                  ('家电', Icons.tv),
                  ('更多', Icons.more_horiz),
                ];
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(categories[index].$2, size: 20),
                    ),
                    SizedBox(height: 4.h),
                    Text(categories[index].$1,
                        style: theme.textTheme.labelSmall),
                  ],
                );
              },
            ),
          ),

          // ── SliverPersistentHeader ──
          _buildSectionHeader(context, 'SliverList：为你推荐', Icons.recommend),

          // ── SliverList: 推荐列表 ──
          SliverList.builder(
            itemCount: 15,
            itemBuilder: (context, index) => Card(
              margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  child: Text('${index + 1}'),
                ),
                title: Text('推荐内容 ${index + 1}'),
                subtitle: const Text('基于你的浏览历史推荐'),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
          ),

          // 底部说明
          SliverToBoxAdapter(
            child: Card(
              margin: EdgeInsets.all(16.w),
              color: theme.colorScheme.surfaceContainerLow,
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('本页使用的 Sliver 组件',
                        style: theme.textTheme.titleSmall),
                    SizedBox(height: 8.h),
                    const Text(
                      '• SliverAppBar → 顶部折叠导航\n'
                      '• SliverToBoxAdapter → 插入 Banner 等普通 Widget\n'
                      '• SliverPersistentHeader → 吸顶的分区标题\n'
                      '• SliverGrid → 网格布局（商品、分类）\n'
                      '• SliverList → 列表布局（排行、推荐）\n'
                      '• SliverPadding → 为 Sliver 添加内边距\n\n'
                      '所有 Sliver 组件都在同一个 CustomScrollView 中，'
                      '共享同一个滚动控制器，实现统一的滚动体验。',
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

  SliverPersistentHeader _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SectionHeaderDelegate(
        title: title,
        icon: icon,
        theme: Theme.of(context),
      ),
    );
  }
}

class _SectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  _SectionHeaderDelegate({
    required this.title,
    required this.icon,
    required this.theme,
  });

  final String title;
  final IconData icon;
  final ThemeData theme;

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: theme.colorScheme.surface,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          SizedBox(width: 8.w),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SectionHeaderDelegate oldDelegate) =>
      title != oldDelegate.title;
}
