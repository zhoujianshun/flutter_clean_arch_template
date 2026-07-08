import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/shared/responsive/adaptive_builder.dart';
import 'package:flutter_clean_arch_template/shared/responsive/breakpoints.dart';
import 'package:flutter_clean_arch_template/shared/responsive/content_constraint.dart';

/// 响应式设置页示例
///
/// 演示设置/偏好页面的两种经典布局：
/// - **手机**：全屏分组列表，点击分类进入子设置页
/// - **平板**：左侧分类导航 + 右侧设置项详情，类似 iOS/macOS 设置
///
/// 这是除了 Master-Detail 之外另一种常见的分栏模式，
/// 区别在于左侧是固定的分类菜单而非数据列表。
@RoutePage()
class ResponsiveSettingsPage extends StatefulWidget {
  const ResponsiveSettingsPage({super.key});

  @override
  State<ResponsiveSettingsPage> createState() => _ResponsiveSettingsPageState();
}

class _ResponsiveSettingsPageState extends State<ResponsiveSettingsPage> {
  int _selectedCategory = 0;

  static const _categories = [
    _SettingsCategory(
      title: '通用',
      icon: Icons.settings_outlined,
      items: [
        _SettingsItem(
          title: '语言',
          subtitle: '简体中文',
          type: _ItemType.navigation,
        ),
        _SettingsItem(
          title: '时区',
          subtitle: 'UTC+8 北京时间',
          type: _ItemType.navigation,
        ),
        _SettingsItem(
          title: '日期格式',
          subtitle: 'YYYY-MM-DD',
          type: _ItemType.navigation,
        ),
      ],
    ),
    _SettingsCategory(
      title: '外观',
      icon: Icons.palette_outlined,
      items: [
        _SettingsItem(title: '深色模式', subtitle: '跟随系统', type: _ItemType.toggle),
        _SettingsItem(
          title: '字体大小',
          subtitle: '标准',
          type: _ItemType.navigation,
        ),
        _SettingsItem(title: '主题色', subtitle: '紫色', type: _ItemType.navigation),
        _SettingsItem(
          title: '圆角风格',
          subtitle: '圆润',
          type: _ItemType.navigation,
        ),
      ],
    ),
    _SettingsCategory(
      title: '通知',
      icon: Icons.notifications_outlined,
      items: [
        _SettingsItem(title: '推送通知', subtitle: '已开启', type: _ItemType.toggle),
        _SettingsItem(
          title: '消息提醒',
          subtitle: '声音和振动',
          type: _ItemType.navigation,
        ),
        _SettingsItem(
          title: '免打扰',
          subtitle: '22:00 - 08:00',
          type: _ItemType.navigation,
        ),
      ],
    ),
    _SettingsCategory(
      title: '隐私',
      icon: Icons.lock_outlined,
      items: [
        _SettingsItem(
          title: '生物识别',
          subtitle: '指纹 / 面容',
          type: _ItemType.toggle,
        ),
        _SettingsItem(
          title: '应用锁',
          subtitle: '已关闭',
          type: _ItemType.navigation,
        ),
        _SettingsItem(
          title: '数据同步',
          subtitle: '仅 Wi-Fi',
          type: _ItemType.navigation,
        ),
        _SettingsItem(
          title: '清除缓存',
          subtitle: '128 MB',
          type: _ItemType.action,
        ),
      ],
    ),
    _SettingsCategory(
      title: '关于',
      icon: Icons.info_outlined,
      items: [
        _SettingsItem(
          title: '版本',
          subtitle: 'v2.1.0 (Build 256)',
          type: _ItemType.info,
        ),
        _SettingsItem(title: '服务条款', subtitle: '', type: _ItemType.navigation),
        _SettingsItem(title: '隐私政策', subtitle: '', type: _ItemType.navigation),
        _SettingsItem(title: '开源许可', subtitle: '', type: _ItemType.navigation),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('响应式设置示例')),
      body: AdaptiveLayoutBuilder(
        compact: (_) => _buildCompactLayout(context),
        medium: (constraints) => _buildSplitLayout(context, constraints),
      ),
    );
  }

  /// 手机布局：全屏分组列表
  Widget _buildCompactLayout(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                category.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  for (var i = 0; i < category.items.length; i++) ...[
                    if (i > 0) const Divider(height: 1, indent: 56),
                    _buildSettingsItemTile(context, category.items[i]),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// 平板布局：左分类 + 右设置项
  Widget _buildSplitLayout(BuildContext context, BoxConstraints constraints) {
    final category = _categories[_selectedCategory];
    final masterWidth = ResponsiveBreakpoints.isExpanded(constraints) ? 280.0 : 240.0;

    return Row(
      children: [
        // 左侧分类导航
        SizedBox(
          width: masterWidth,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final isSelected = index == _selectedCategory;
              return ListTile(
                leading: Icon(
                  cat.icon,
                  color: isSelected ? Theme.of(context).colorScheme.primary : null,
                ),
                title: Text(
                  cat.title,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Theme.of(context).colorScheme.primary : null,
                  ),
                ),
                selected: isSelected,
                selectedTileColor: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () => setState(() => _selectedCategory = index),
              );
            },
          ),
        ),
        const VerticalDivider(width: 1),
        // 右侧设置项
        Expanded(
          child: ContentConstraint(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  category.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      for (var i = 0; i < category.items.length; i++) ...[
                        if (i > 0) const Divider(height: 1, indent: 56),
                        _buildSettingsItemTile(context, category.items[i]),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItemTile(BuildContext context, _SettingsItem item) {
    return ListTile(
      title: Text(item.title),
      subtitle: item.subtitle.isNotEmpty ? Text(item.subtitle) : null,
      trailing: switch (item.type) {
        _ItemType.toggle => Switch(value: true, onChanged: (_) {}),
        _ItemType.navigation => const Icon(Icons.chevron_right),
        _ItemType.action => TextButton(
          onPressed: () {},
          child: const Text('清除'),
        ),
        _ItemType.info => null,
      },
    );
  }
}

// ── 数据模型 ──────────────────────────────────────────────────────────────

enum _ItemType { navigation, toggle, action, info }

class _SettingsCategory {
  const _SettingsCategory({
    required this.title,
    required this.icon,
    required this.items,
  });
  final String title;
  final IconData icon;
  final List<_SettingsItem> items;
}

class _SettingsItem {
  const _SettingsItem({
    required this.title,
    required this.subtitle,
    required this.type,
  });
  final String title;
  final String subtitle;
  final _ItemType type;
}
