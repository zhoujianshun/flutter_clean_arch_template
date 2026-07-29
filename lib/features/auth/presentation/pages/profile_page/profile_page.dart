import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/core/router/app_router.dart';
import 'package:flutter_clean_arch_template/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_clean_arch_template/shared/responsive/content_constraint.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

@RoutePage()
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ContentConstraint(
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40.r,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(Icons.person, size: 40.r, color: Theme.of(context).colorScheme.onPrimaryContainer),
                    ),
                    SizedBox(height: 16.h),
                    Text('Template User', style: Theme.of(context).textTheme.titleLarge),
                    SizedBox(height: 4.h),
                    Text(
                      'user@example.com',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.palette_outlined),
                    title: const Text('Theme Settings'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => unawaited(context.router.push(const ThemeSettingsRoute())),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.bug_report_outlined),
                    title: const Text('Logger Viewer'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => unawaited(context.router.push(const LoggerViewerRoute())),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: const Text('Config Management'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => unawaited(context.router.push(const ConfigManagementRoute())),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.devices_outlined),
                    title: const Text('Responsive Demo'),
                    subtitle: const Text('手机/平板适配示例'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => unawaited(context.router.push(const ResponsiveDemoHubRoute())),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.widgets_outlined),
                    title: const Text('Widget Demo'),
                    subtitle: const Text('组件库使用示例'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => unawaited(context.router.push(const WidgetDemoHubRoute())),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.memory_outlined),
                    title: const Text('Riverpod Demo'),
                    subtitle: const Text('状态管理模式示例'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => unawaited(context.router.push(const RiverpodDemoHubRoute())),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32.h),
            FilledButton.tonal(
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
              },
              style: FilledButton.styleFrom(
                minimumSize: Size(double.infinity, 48.h),
              ),
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}
