import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/core/router/app_router.dart';
import 'package:flutter_clean_arch_template/shared/responsive/content_constraint.dart';
import 'package:flutter_clean_arch_template/shared/responsive/responsive_tokens.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 组件库 Demo 入口页面
@RoutePage()
class WidgetDemoHubPage extends StatelessWidget {
  const WidgetDemoHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final demos = [
      _DemoEntry(
        title: '按钮 Buttons',
        subtitle: 'MyButton / MyFilledButton / MyOutlinedButton / PrimaryButton',
        icon: Icons.smart_button_outlined,
        onTap: () => unawaited(context.router.push(const ButtonDemoRoute())),
      ),
      _DemoEntry(
        title: '对话框与弹窗 Dialogs',
        subtitle: 'Material / Cupertino 对话框、Toast、Loading',
        icon: Icons.chat_bubble_outline,
        onTap: () => unawaited(context.router.push(const DialogDemoRoute())),
      ),
      _DemoEntry(
        title: '底部面板与选择器 Sheets',
        subtitle: 'BottomSheet / Selector / CupertinoPicker',
        icon: Icons.vertical_align_bottom_outlined,
        onTap: () => unawaited(context.router.push(const SheetDemoRoute())),
      ),
      _DemoEntry(
        title: '数据展示 Data Display',
        subtitle: 'AppCard / InfoRow / AppTag / RatingBar / Badge / GradientIcon',
        icon: Icons.dashboard_outlined,
        onTap: () =>
            unawaited(context.router.push(const DataDisplayDemoRoute())),
      ),
      _DemoEntry(
        title: '表单与输入 Form & Input',
        subtitle: 'FormTitle / RoundCheckBox / VerificationCodeButton',
        icon: Icons.edit_note_outlined,
        onTap: () =>
            unawaited(context.router.push(const FormInputDemoRoute())),
      ),
      _DemoEntry(
        title: '状态页 State Widgets',
        subtitle: 'Empty / Error / Loading / Placeholder',
        icon: Icons.hourglass_empty_outlined,
        onTap: () => unawaited(context.router.push(const StateDemoRoute())),
      ),
      _DemoEntry(
        title: '导航与 TabBar',
        subtitle: 'AppBar / TabIndicator / BottomNavigationBar',
        icon: Icons.tab_outlined,
        onTap: () =>
            unawaited(context.router.push(const NavigationDemoRoute())),
      ),
      _DemoEntry(
        title: '功能组件 Utilities',
        subtitle: 'Clock / Countdown / CachedImage / PaginationList / Switchers',
        icon: Icons.build_outlined,
        onTap: () => unawaited(context.router.push(const UtilityDemoRoute())),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('组件库 Demo')),
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
