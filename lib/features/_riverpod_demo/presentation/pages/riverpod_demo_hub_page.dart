import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/core/router/app_router.dart';
import 'package:flutter_clean_arch_template/shared/responsive/content_constraint.dart';
import 'package:flutter_clean_arch_template/shared/responsive/responsive_tokens.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Riverpod 状态管理 Demo 入口页面
@RoutePage()
class RiverpodDemoHubPage extends StatelessWidget {
  const RiverpodDemoHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final demos = [
      _DemoEntry(
        title: 'AsyncValue.when 三态切换',
        subtitle: 'loading → data / error 全页切换，ref.invalidate 重试',
        icon: Icons.swap_vert_outlined,
        onTap: () =>
            unawaited(context.router.push(const AsyncWhenDemoRoute())),
      ),
      _DemoEntry(
        title: 'Toast 错误提示',
        subtitle: 'ref.listen 监听错误 → Toast 提示，数据保留不消失',
        icon: Icons.notifications_outlined,
        onTap: () =>
            unawaited(context.router.push(const ToastErrorDemoRoute())),
      ),
      _DemoEntry(
        title: '分页列表 PaginationList',
        subtitle: 'PaginationState + EasyRefresh 下拉刷新/上拉加载更多',
        icon: Icons.view_list_outlined,
        onTap: () =>
            unawaited(context.router.push(const PaginationDemoRoute())),
      ),
      _DemoEntry(
        title: 'Retry 重试机制',
        subtitle: 'Riverpod 3.x 默认指数退避重试 vs 禁用重试对比',
        icon: Icons.replay_outlined,
        onTap: () =>
            unawaited(context.router.push(const RetryDemoRoute())),
      ),
      _DemoEntry(
        title: '乐观更新 Optimistic Update',
        subtitle: '立即更新 UI → 异步确认 → 失败自动回滚',
        icon: Icons.favorite_border,
        onTap: () =>
            unawaited(context.router.push(const OptimisticUpdateDemoRoute())),
      ),
      _DemoEntry(
        title: '悲观更新 Pessimistic Update',
        subtitle: '先 loading → 服务端确认 → 成功才更新 UI',
        icon: Icons.verified_outlined,
        onTap: () =>
            unawaited(context.router.push(const PessimisticUpdateDemoRoute())),
      ),
      _DemoEntry(
        title: '筛选联动 Filter',
        subtitle: 'StateProvider 筛选条件 → 列表 Provider 自动响应',
        icon: Icons.filter_list_outlined,
        onTap: () =>
            unawaited(context.router.push(const FilterListDemoRoute())),
      ),
      _DemoEntry(
        title: '表单提交 Form Mutation',
        subtitle: 'AsyncValue<void> 管理提交状态，ref.listen 处理结果',
        icon: Icons.send_outlined,
        onTap: () =>
            unawaited(context.router.push(const FormSubmitDemoRoute())),
      ),
      _DemoEntry(
        title: 'Dependencies 作用域',
        subtitle: 'ProviderScope override 实现列表项独立数据上下文',
        icon: Icons.account_tree_outlined,
        onTap: () =>
            unawaited(context.router.push(const DependenciesDemoRoute())),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Riverpod Demo')),
      body: ContentConstraint(
        maxWidth: ResponsiveTokens.maxWidthList,
        child: ListView.separated(
          padding: EdgeInsets.all(16.w),
          itemCount: demos.length,
          separatorBuilder: (_, __) => SizedBox(height: 8.h),
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
