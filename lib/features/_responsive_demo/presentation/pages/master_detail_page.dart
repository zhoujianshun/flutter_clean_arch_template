import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/core/router/app_router.dart';
import 'package:flutter_clean_arch_template/shared/responsive/adaptive_builder.dart';
import 'package:flutter_clean_arch_template/shared/responsive/content_constraint.dart';
import 'package:flutter_clean_arch_template/shared/responsive/layout_semantics.dart';
import 'package:flutter_clean_arch_template/shared/responsive/responsive_tokens.dart';

/// Master-Detail 分栏示例
///
/// 演示列表 → 详情的两种导航模式：
/// - **手机**：列表页点击后 push 全屏详情页
/// - **平板**：左侧列表面板 + 右侧详情面板，并排显示
///
/// 这是平板适配中最有价值的模式，充分利用大屏横向空间。
@RoutePage()
class MasterDetailPage extends StatefulWidget {
  const MasterDetailPage({super.key});

  @override
  State<MasterDetailPage> createState() => _MasterDetailPageState();
}

class _MasterDetailPageState extends State<MasterDetailPage> {
  int? _selectedIndex;

  static const _items = [
    _MessageItem(
      sender: '张三',
      subject: '项目进展更新',
      preview: '本周完成了用户模块的开发，下周计划开始测试...',
      time: '10:30',
    ),
    _MessageItem(
      sender: '李四',
      subject: '设计稿评审',
      preview: '新版设计稿已上传到 Figma，请各位抽空评审...',
      time: '09:15',
    ),
    _MessageItem(
      sender: '王五',
      subject: '线上问题反馈',
      preview: '用户反馈在 iOS 14 上出现闪退，已定位到...',
      time: '昨天',
    ),
    _MessageItem(
      sender: '赵六',
      subject: '会议纪要',
      preview: '本次迭代目标确认：完成平板适配和性能优化...',
      time: '昨天',
    ),
    _MessageItem(
      sender: '系统通知',
      subject: 'CI/CD 构建成功',
      preview: 'Build #256 已成功部署到测试环境...',
      time: '前天',
    ),
    _MessageItem(
      sender: '孙七',
      subject: '技术方案讨论',
      preview: '关于状态管理方案，建议从 Provider 迁移到 Riverpod...',
      time: '前天',
    ),
    _MessageItem(
      sender: '周八',
      subject: '代码评审建议',
      preview: '在 PR #89 中发现几个可以优化的地方...',
      time: '3天前',
    ),
    _MessageItem(
      sender: '吴九',
      subject: '新功能需求',
      preview: '产品希望在下个版本中加入暗色模式切换...',
      time: '3天前',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Master-Detail 示例')),
      body: AdaptiveLayoutBuilder(
        compact: (_) => _buildCompactLayout(),
        medium: (constraints) => _buildSplitLayout(constraints),
      ),
    );
  }

  /// 手机布局：纯列表，点击 push 详情页
  Widget _buildCompactLayout() {
    return ListView.builder(
      key: const PageStorageKey<String>('master_detail_compact_list'),
      padding: EdgeInsets.all(ResponsiveTokens.size(8, medium: 8, expanded: 8)),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return _MessageListTile(
          item: item,
          isSelected: false,
          onTap: () => _showDetailPage(context, index),
        );
      },
    );
  }

  /// 平板布局：左右分栏
  Widget _buildSplitLayout(BoxConstraints constraints) {
    final masterRatio = LayoutSemantics.masterPaneRatio(constraints);

    return Row(
      children: [
        // 左侧列表面板
        SizedBox(
          width: constraints.maxWidth * masterRatio,
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              return _MessageListTile(
                item: item,
                isSelected: _selectedIndex == index,
                onTap: () => setState(() => _selectedIndex = index),
              );
            },
          ),
        ),
        const VerticalDivider(width: 1),
        // 右侧详情面板
        Expanded(
          child: _selectedIndex != null
              ? _DetailPanel(item: _items[_selectedIndex!])
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.mail_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '选择一条消息查看详情',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  /// 手机模式：通过 AutoRoute 导航到独立的详情页面
  ///
  /// 使用 AutoRoute 而非 Navigator.push 的好处：
  /// - 经过路由守卫（AuthGuard、DebouncerGuard 等）
  /// - 支持 deep link
  /// - 统一转场动画
  /// - 路由观察器可追踪
  void _showDetailPage(BuildContext context, int index) {
    final item = _items[index];
    unawaited(
      context.router.push(
        MasterDetailDetailRoute(
          sender: item.sender,
          subject: item.subject,
          preview: item.preview,
          time: item.time,
        ),
      ),
    );
  }
}

// ── 子组件 ────────────────────────────────────────────────────────────────

class _MessageItem {
  const _MessageItem({
    required this.sender,
    required this.subject,
    required this.preview,
    required this.time,
  });

  final String sender;
  final String subject;
  final String preview;
  final String time;
}

class _MessageListTile extends StatelessWidget {
  const _MessageListTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final _MessageItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
      child: ListTile(
        leading: CircleAvatar(child: Text(item.sender[0])),
        title: Text(item.subject, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          item.preview,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(item.time, style: Theme.of(context).textTheme.bodySmall),
        onTap: onTap,
      ),
    );
  }
}

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({required this.item});
  final _MessageItem item;

  @override
  Widget build(BuildContext context) {
    return ContentConstraint(
      maxWidth: ResponsiveTokens.maxWidthDetail,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  child: Text(
                    item.sender[0],
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.sender,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        item.time,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              item.subject,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              '${item.preview}\n\n'
              '这是一段示例正文内容，用于展示详情面板在不同屏幕尺寸下的显示效果。在手机上，这个面板会以全屏页面的形式展示；在平板上，它会显示在右侧的详情区域中，与左侧的列表并排显示。\n\n'
              '通过 ContentConstraint 组件，即使在超大屏幕上，正文的阅读宽度也会被限制在 680dp 以内，确保良好的阅读体验。\n\n'
              'Master-Detail 模式是平板适配中最常见也最有价值的模式，适用于：\n'
              '• 邮件列表 → 邮件详情\n'
              '• 聊天列表 → 对话窗口\n'
              '• 设置分类 → 设置项\n'
              '• 文件列表 → 文件预览',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(height: 1.8),
            ),
          ],
        ),
      ),
    );
  }
}
