import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/core/l10n/language_provider.dart';
import 'package:flutter_clean_arch_template/core/responsive/content_constraint.dart';
import 'package:flutter_clean_arch_template/core/router/app_router.dart';
import 'package:flutter_clean_arch_template/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_clean_arch_template/generated/l10n/app_localizations.dart';
import 'package:flutter_clean_arch_template/shared/widgets/language_switcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@RoutePage()
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(appLanguageSettingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ContentConstraint(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(Icons.person, size: 40, color: Theme.of(context).colorScheme.onPrimaryContainer),
                    ),
                    const SizedBox(height: 16),
                    Text('Template User', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
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
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.language_outlined),
                    title: Text(AppLocalizations.of(context).profile_language),
                    subtitle: Text(currentLanguage.displayName),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => unawaited(LanguageSwitcherDialog.show(context)),
                  ),
                  const Divider(height: 1),
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
            const SizedBox(height: 32),
            FilledButton.tonal(
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}
