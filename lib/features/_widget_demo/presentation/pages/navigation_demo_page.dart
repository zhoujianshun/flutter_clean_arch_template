import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/shared/responsive/content_constraint.dart';
import 'package:flutter_clean_arch_template/shared/widgets/app_bar/my_app_bar.dart';
import 'package:flutter_clean_arch_template/shared/widgets/indicators/rounded_tab_indicator.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

@RoutePage()
class NavigationDemoPage extends StatefulWidget {
  const NavigationDemoPage({super.key});

  @override
  State<NavigationDemoPage> createState() => _NavigationDemoPageState();
}

class _NavigationDemoPageState extends State<NavigationDemoPage>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      appBar: AppBar(title: const Text('导航与 TabBar')),
      body: ContentConstraint(
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            // AppBar 变体
            _SectionTitle('AppBarExtension', 'AppBar 工厂方法（静态预览）'),

            // Primary AppBar
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                        left: 16.w, top: 12.h, bottom: 4.h),
                    child: Text('primary',
                        style: theme.textTheme.labelMedium),
                  ),
                  SizedBox(
                    height: kToolbarHeight,
                    child: AppBarExtension.primary(
                      context: context,
                      title: 'Primary AppBar',
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.h),

            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                        left: 16.w, top: 12.h, bottom: 4.h),
                    child: Text('defaultAppBar',
                        style: theme.textTheme.labelMedium),
                  ),
                  SizedBox(
                    height: kToolbarHeight,
                    child: AppBarExtension.defaultAppBar(
                      context: context,
                      title: 'Default AppBar',
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.h),

            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                        left: 16.w, top: 12.h, bottom: 4.h),
                    child: Text('bgColorAppBar',
                        style: theme.textTheme.labelMedium),
                  ),
                  SizedBox(
                    height: kToolbarHeight,
                    child: AppBarExtension.bgColorAppBar(
                      context: context,
                      title: 'BgColor AppBar',
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // RoundedRectangleTabIndicator
            _SectionTitle(
              'RoundedRectangleTabIndicator',
              '圆角 TabBar 指示器（可交互）',
            ),
            Card(
              child: Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    indicator: RoundedRectangleTabIndicator(
                      color: theme.colorScheme.primary,
                      radius: 3.r,
                      weight: 4.h,
                    ),
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                    tabs: const [
                      Tab(text: '推荐'),
                      Tab(text: '关注'),
                      Tab(text: '热门'),
                    ],
                  ),
                  SizedBox(
                    height: 100.h,
                    child: TabBarView(
                      controller: _tabController,
                      children: const [
                        Center(child: Text('推荐内容')),
                        Center(child: Text('关注内容')),
                        Center(child: Text('热门内容')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // AppImageIndicatorTabBar
            _SectionTitle(
              'AppImageIndicatorTabBar',
              '图片指示器 TabBar（需提供 indicatorAsset 图片资源）',
            ),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Text(
                  '使用方式：\n'
                  'AppImageIndicatorTabBar(\n'
                  '  controller: tabController,\n'
                  '  tabs: [Tab(text: "A"), Tab(text: "B")],\n'
                  '  indicatorAsset: "assets/icons/tab_indicator.png",\n'
                  ')\n\n'
                  '注意：需要在 assets/icons/ 下提供自定义的指示器图片资源。',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // BottomNavigationBar 预览
            _SectionTitle(
              'NavigationBar',
              '底部导航栏预览（静态展示）',
            ),
            Card(
              clipBehavior: Clip.antiAlias,
              child: NavigationBar(
                selectedIndex: _navIndex,
                onDestinationSelected: (i) => setState(() => _navIndex = i),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: '首页',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.search_outlined),
                    selectedIcon: Icon(Icons.search),
                    label: '发现',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.chat_bubble_outline),
                    selectedIcon: Icon(Icons.chat_bubble),
                    label: '消息',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person),
                    label: '我的',
                  ),
                ],
              ),
            ),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, this.subtitle);

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: 2.h),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
