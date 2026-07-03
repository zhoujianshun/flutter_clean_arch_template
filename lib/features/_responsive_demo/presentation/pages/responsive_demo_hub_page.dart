import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/core/router/app_router.dart';
import 'package:flutter_clean_arch_template/shared/responsive/content_constraint.dart';
import 'package:flutter_clean_arch_template/shared/responsive/responsive_tokens.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 响应式适配示例入口页面
///
/// 展示所有响应式适配的示例页面，方便学习和参考。
@RoutePage()
class ResponsiveDemoHubPage extends StatelessWidget {
  const ResponsiveDemoHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final demos = [
      _DemoEntry(
        title: 'Dashboard 仪表盘',
        subtitle: '手机：单列卡片 → 平板：多面板网格布局',
        icon: Icons.dashboard_outlined,
        onTap: () =>
            unawaited(context.router.push(const ResponsiveDashboardRoute())),
      ),
      _DemoEntry(
        title: 'Master-Detail 分栏',
        subtitle: '手机：列表 → 全屏详情 → 平板：左列表 + 右详情',
        icon: Icons.view_sidebar_outlined,
        onTap: () => unawaited(context.router.push(const MasterDetailRoute())),
      ),
      _DemoEntry(
        title: '响应式表单',
        subtitle: '手机：全宽表单 → 平板：居中卡片 + 双列字段',
        icon: Icons.edit_note_outlined,
        onTap: () =>
            unawaited(context.router.push(const ResponsiveFormRoute())),
      ),
      _DemoEntry(
        title: '自适应网格画廊',
        subtitle: '根据屏幕宽度自动调整列数（2/3/4 列）',
        icon: Icons.grid_view_outlined,
        onTap: () =>
            unawaited(context.router.push(const ResponsiveGalleryRoute())),
      ),
      _DemoEntry(
        title: '设置页分栏',
        subtitle: '手机：分组列表 → 平板：左分类导航 + 右设置项',
        icon: Icons.settings_outlined,
        onTap: () =>
            unawaited(context.router.push(const ResponsiveSettingsRoute())),
      ),
      _DemoEntry(
        title: '图文详情页',
        subtitle: '手机：图上文下 → 平板：图左文右并排',
        icon: Icons.article_outlined,
        onTap: () =>
            unawaited(context.router.push(const ResponsiveArticleRoute())),
      ),
      _DemoEntry(
        title: '登录页',
        subtitle: '手机：全屏表单 → 平板：左品牌展示 + 右登录表单',
        icon: Icons.login_outlined,
        onTap: () =>
            unawaited(context.router.push(const ResponsiveLoginRoute())),
      ),
      _DemoEntry(
        title: '聊天对话',
        subtitle: '手机：全屏对话 → 平板：联系人列表 + 对话窗口',
        icon: Icons.chat_outlined,
        onTap: () =>
            unawaited(context.router.push(const ResponsiveChatRoute())),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('响应式适配示例')),
      body: ContentConstraint(
        maxWidth: ResponsiveTokens.maxWidthList,
        child: ListView.separated(
          padding: EdgeInsets.all(16.w),
          itemCount: demos.length,
          separatorBuilder: (_, _) => SizedBox(height: 8.h),
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
