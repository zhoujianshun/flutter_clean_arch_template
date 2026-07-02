import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/shared/responsive/adaptive_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 响应式 Dashboard 示例
///
/// 演示手机和平板上截然不同的布局结构：
/// - **手机**：单列纵向排列所有卡片
/// - **平板竖屏**：2 列网格 + 顶部横幅
/// - **平板横屏/桌面**：左侧主面板 + 右侧边栏
@RoutePage()
class ResponsiveDashboardPage extends StatelessWidget {
  const ResponsiveDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard 示例')),
      body: AdaptiveLayoutBuilder(
        compact: (_) => const _CompactDashboard(),
        medium: (constraints) => _MediumDashboard(constraints: constraints),
        expanded: (constraints) => _ExpandedDashboard(constraints: constraints),
      ),
    );
  }
}

/// 手机布局：单列卡片列表
class _CompactDashboard extends StatelessWidget {
  const _CompactDashboard();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        _buildBanner(context, '欢迎回来！'),
        SizedBox(height: 16.h),
        const _StatCard(title: '今日访问', value: '1,234', icon: Icons.visibility, color: Colors.blue),
        SizedBox(height: 12.h),
        const _StatCard(title: '新增用户', value: '56', icon: Icons.person_add, color: Colors.green),
        SizedBox(height: 12.h),
        const _StatCard(title: '订单数量', value: '89', icon: Icons.shopping_cart, color: Colors.orange),
        SizedBox(height: 12.h),
        const _StatCard(title: '总收入', value: '¥12,450', icon: Icons.attach_money, color: Colors.purple),
        SizedBox(height: 16.h),
        const _SectionTitle(title: '最近动态'),
        SizedBox(height: 8.h),
        ...List.generate(5, (i) => _ActivityItem(index: i)),
      ],
    );
  }
}

/// 平板竖屏布局：2 列统计网格 + 动态列表
class _MediumDashboard extends StatelessWidget {
  const _MediumDashboard({required this.constraints});
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(24),
      children: [
        _buildBanner(context, '欢迎回来！今天是美好的一天。'),
        const SizedBox(height: 24),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.2,
          children: const [
            _StatCard(title: '今日访问', value: '1,234', icon: Icons.visibility, color: Colors.blue),
            _StatCard(title: '新增用户', value: '56', icon: Icons.person_add, color: Colors.green),
            _StatCard(title: '订单数量', value: '89', icon: Icons.shopping_cart, color: Colors.orange),
            _StatCard(title: '总收入', value: '¥12,450', icon: Icons.attach_money, color: Colors.purple),
          ],
        ),
        const SizedBox(height: 24),
        const _SectionTitle(title: '最近动态'),
        const SizedBox(height: 12),
        ...List.generate(5, (i) => _ActivityItem(index: i)),
      ],
    );
  }
}

/// 平板横屏/桌面布局：左侧主内容 + 右侧边栏
class _ExpandedDashboard extends StatelessWidget {
  const _ExpandedDashboard({required this.constraints});
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左侧主面板（占 65%）
        Expanded(
          flex: 65,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildBanner(context, '欢迎回来！这是你的数据概览。'),
              const SizedBox(height: 24),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.8,
                children: const [
                  _StatCard(title: '今日访问', value: '1,234', icon: Icons.visibility, color: Colors.blue),
                  _StatCard(title: '新增用户', value: '56', icon: Icons.person_add, color: Colors.green),
                  _StatCard(title: '订单数量', value: '89', icon: Icons.shopping_cart, color: Colors.orange),
                  _StatCard(title: '总收入', value: '¥12,450', icon: Icons.attach_money, color: Colors.purple),
                ],
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        // 右侧边栏（占 35%）
        Expanded(
          flex: 35,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(24),
                child: _SectionTitle(title: '最近动态'),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: 10,
                  itemBuilder: (_, i) => _ActivityItem(index: i),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── 共享子组件 ──────────────────────────────────────────────────────────

Widget _buildBanner(BuildContext context, String text) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Theme.of(context).colorScheme.primary,
          Theme.of(context).colorScheme.tertiary,
        ],
      ),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold));
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  const _ActivityItem({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    final activities = [
      ('张三完成了订单 #1024', Icons.check_circle, Colors.green),
      ('李四注册了新账号', Icons.person_add, Colors.blue),
      ('系统完成了数据备份', Icons.backup, Colors.orange),
      ('王五提交了反馈', Icons.feedback, Colors.purple),
      ('新版本 v2.1 已发布', Icons.new_releases, Colors.red),
    ];
    final (text, icon, color) = activities[index % activities.length];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ListTile(
          leading: Icon(icon, color: color, size: 20),
          title: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          subtitle: Text('${index + 1} 小时前', style: Theme.of(context).textTheme.bodySmall),
        ),
      ),
    );
  }
}
