import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/core/router/app_router.dart';
import 'package:flutter_clean_arch_template/shared/responsive/content_constraint.dart';
import 'package:flutter_clean_arch_template/shared/responsive/responsive_tokens.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// SliverAppBar Demo 入口页面
///
/// 7 个场景覆盖 SliverAppBar 从基础到高级的全部核心用法
@RoutePage()
class SliverAppBarHubPage extends StatelessWidget {
  const SliverAppBarHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final demos = [
      _DemoEntry(
        title: '① 基础折叠 Pinned',
        subtitle: 'pinned + FlexibleSpaceBar，商品详情页大图折叠',
        icon: Icons.expand_less,
        onTap: () =>
            unawaited(context.router.push(const SliverBasicDemoRoute())),
      ),
      _DemoEntry(
        title: '② 浮动吸附 Float + Snap',
        subtitle: 'floating + snap，搜索栏快速弹出',
        icon: Icons.swap_vert,
        onTap: () =>
            unawaited(context.router.push(const SliverFloatSnapDemoRoute())),
      ),
      _DemoEntry(
        title: '③ 拉伸效果 Stretch',
        subtitle: 'stretch + stretchTriggerOffset，iOS 弹性拉伸',
        icon: Icons.open_in_full,
        onTap: () =>
            unawaited(context.router.push(const SliverStretchDemoRoute())),
      ),
      _DemoEntry(
        title: '④ TabBar 吸顶',
        subtitle: 'NestedScrollView + pinned + bottom: TabBar',
        icon: Icons.tab,
        onTap: () =>
            unawaited(context.router.push(const SliverTabbarDemoRoute())),
      ),
      _DemoEntry(
        title: '⑤ 渐变透明背景',
        subtitle: 'ScrollNotification 监听滚动，动态计算透明度',
        icon: Icons.gradient,
        onTap: () =>
            unawaited(context.router.push(const SliverFadeDemoRoute())),
      ),
      _DemoEntry(
        title: '⑥ M3 Medium / Large',
        subtitle: 'SliverAppBar.medium / .large，Material 3 标题变体',
        icon: Icons.title,
        onTap: () =>
            unawaited(context.router.push(const SliverM3DemoRoute())),
      ),
      _DemoEntry(
        title: '⑦ 多 Sliver 组合',
        subtitle: 'SliverList + SliverGrid + SliverPersistentHeader',
        icon: Icons.view_comfy_alt,
        onTap: () =>
            unawaited(context.router.push(const SliverMultiSliverDemoRoute())),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('SliverAppBar Demo')),
      body: ContentConstraint(
        maxWidth: ResponsiveTokens.maxWidthList,
        child: ListView.separated(
          padding: EdgeInsets.all(16.w),
          itemCount: demos.length,
          separatorBuilder: (context, index) => SizedBox(height: 8.h),
          itemBuilder: (context, index) {
            final demo = demos[index];
            return Card(
              child: ListTile(
                leading: Icon(
                  demo.icon,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(demo.title),
                subtitle: Text(
                  demo.subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: demo.onTap,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DemoEntry {
  const _DemoEntry({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
}
