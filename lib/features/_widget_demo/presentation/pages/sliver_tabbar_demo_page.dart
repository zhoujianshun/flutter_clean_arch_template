import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 场景 4：嵌套 TabBar 吸顶
///
/// 关键属性：
/// - `pinned: true` + `bottom: TabBar(...)` → 折叠后 TabBar 吸顶
/// - `NestedScrollView` → 解决外层 SliverAppBar 与内层 Tab 列表的滚动冲突
/// - `SliverOverlapAbsorber / SliverOverlapInjector` → 正确处理重叠区域
///
/// 业务场景：电商分类页、新闻频道页、用户主页
@RoutePage()
class SliverTabbarDemoPage extends StatefulWidget {
  const SliverTabbarDemoPage({super.key});

  @override
  State<SliverTabbarDemoPage> createState() => _SliverTabbarDemoPageState();
}

class _SliverTabbarDemoPageState extends State<SliverTabbarDemoPage>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = ['推荐', '热销', '新品', '优惠'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 200.h,
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            forceElevated: innerBoxIsScrolled,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primaryContainer,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: kToolbarHeight),
                      Icon(
                        Icons.store_outlined,
                        size: 48,
                        color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        '品牌旗舰店',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            title: const Text('TabBar 吸顶'),
            bottom: TabBar(
              controller: _tabController,
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
              labelColor: theme.colorScheme.onPrimary,
              unselectedLabelColor:
                  theme.colorScheme.onPrimary.withValues(alpha: 0.6),
              indicatorColor: theme.colorScheme.onPrimary,
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            for (int tabIndex = 0; tabIndex < _tabs.length; tabIndex++)
              _buildTabContent(context, _tabs[tabIndex], tabIndex),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, String tabName, int tabIndex) {
    final theme = Theme.of(context);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // 说明卡片（仅第一个 Tab 显示）
        if (tabIndex == 0)
          Card(
            margin: EdgeInsets.all(16.w),
            color: theme.colorScheme.surfaceContainerLow,
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('关键属性', style: theme.textTheme.titleSmall),
                  SizedBox(height: 8.h),
                  const Text(
                    '• pinned: true → 折叠后 AppBar + TabBar 吸顶\n'
                    '• bottom: TabBar(...) → TabBar 作为 AppBar 底部附件\n'
                    '• NestedScrollView → 解决外层折叠与内层 Tab 列表的滚动冲突\n'
                    '• forceElevated: innerBoxIsScrolled → 内层滚动时显示阴影',
                  ),
                ],
              ),
            ),
          ),

        // 模拟内容
        ...List.generate(
          20,
          (index) => Card(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text('${index + 1}'),
              ),
              title: Text('$tabName 商品 ${index + 1}'),
              subtitle: Text('$tabName 分类下的商品描述'),
              trailing: Text(
                '¥${(index + 1) * 99}',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
