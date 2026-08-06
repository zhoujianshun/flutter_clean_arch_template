import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/core/router/app_router.dart';
import 'package:flutter_clean_arch_template/shared/responsive/content_constraint.dart';
import 'package:flutter_clean_arch_template/shared/responsive/responsive_tokens.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// CustomScrollView & Sliver 组件 Demo 入口页面
///
/// 7 个场景覆盖 Sliver 体系从基础到高级的核心用法
@RoutePage()
class CustomScrollHubPage extends StatelessWidget {
  const CustomScrollHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final demos = [
      _DemoEntry(
        title: '① SliverList 全家桶',
        subtitle: '.builder / .separated / .list / FixedExtent / Prototype',
        icon: Icons.view_list,
        onTap: () =>
            unawaited(context.router.push(const SliverListDemoRoute())),
      ),
      _DemoEntry(
        title: '② SliverGrid 多种布局',
        subtitle: 'FixedCrossAxisCount / MaxCrossAxisExtent / 自适应',
        icon: Icons.grid_view,
        onTap: () =>
            unawaited(context.router.push(const SliverGridDemoRoute())),
      ),
      _DemoEntry(
        title: '③ FillRemaining & FillViewport',
        subtitle: '空状态填充 / 底部固定按钮 / 全屏分页',
        icon: Icons.vertical_align_bottom,
        onTap: () =>
            unawaited(context.router.push(const SliverFillDemoRoute())),
      ),
      _DemoEntry(
        title: '④ SliverAnimatedList',
        subtitle: '带动画的动态增删列表',
        icon: Icons.animation,
        onTap: () =>
            unawaited(context.router.push(const SliverAnimatedListDemoRoute())),
      ),
      _DemoEntry(
        title: '⑤ PersistentHeader 进阶',
        subtitle: '可变高度 / 弹性拉伸 / 分区索引',
        icon: Icons.push_pin,
        onTap: () =>
            unawaited(context.router.push(const SliverHeaderDemoRoute())),
      ),
      _DemoEntry(
        title: '⑥ ScrollController 滚动控制',
        subtitle: '监听位置 / animateTo / 返回顶部',
        icon: Icons.swap_vert_circle,
        onTap: () =>
            unawaited(context.router.push(const ScrollControllerDemoRoute())),
      ),
      _DemoEntry(
        title: '⑦ SliverLayoutBuilder',
        subtitle: '根据 Constraints 动态构建布局',
        icon: Icons.dashboard_customize,
        onTap: () =>
            unawaited(context.router.push(const SliverLayoutDemoRoute())),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('CustomScrollView Demo')),
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
