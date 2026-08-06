import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 场景 5：SliverPersistentHeader 进阶
///
/// 深入 SliverPersistentHeaderDelegate：
/// - minExtent ≠ maxExtent → 弹性高度变化
/// - shrinkOffset 驱动动画（透明度、缩放等）
/// - pinned: true → 吸顶固定
/// - floating: true → 浮动弹出
///
/// 业务场景：通讯录字母索引、动态变化的分区标题
@RoutePage()
class SliverHeaderDemoPage extends StatelessWidget {
  const SliverHeaderDemoPage({super.key});

  static const _contacts = {
    'A': ['Alice', 'Andy', 'Anna'],
    'B': ['Bob', 'Bella', 'Ben'],
    'C': ['Charlie', 'Catherine', 'Chris'],
    'D': ['David', 'Diana', 'Daniel'],
    'E': ['Emma', 'Ethan', 'Emily'],
    'F': ['Frank', 'Fiona'],
    'G': ['Grace', 'George', 'Gina'],
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.medium(title: const Text('PersistentHeader 进阶')),

          // 说明
          SliverToBoxAdapter(
            child: Card(
              margin: EdgeInsets.all(16.w),
              color: theme.colorScheme.surfaceContainerLow,
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('可变高度 Header', style: theme.textTheme.titleSmall),
                    SizedBox(height: 8.h),
                    const Text(
                      '• minExtent = 48, maxExtent = 100 → 高度随滚动变化\n'
                      '• shrinkOffset 计算收缩比例 → 驱动字号/透明度动画\n'
                      '• pinned: true → 字母索引吸顶\n'
                      '• shouldRebuild → 控制是否需要重建',
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 通讯录列表
          for (final entry in _contacts.entries) ...[
            SliverPersistentHeader(
              pinned: true,
              delegate: _ContactSectionDelegate(
                letter: entry.key,
                theme: theme,
              ),
            ),
            SliverList.list(
              children: entry.value
                  .map((name) => ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(name[0]),
                        ),
                        title: Text(name),
                        subtitle: Text('138****${name.hashCode.abs() % 10000}'),
                      ))
                  .toList(),
            ),
          ],

          SliverToBoxAdapter(child: SizedBox(height: 32.h)),
        ],
      ),
    );
  }
}

/// 可变高度的 Header Delegate
///
/// maxExtent = 100（展开）→ minExtent = 48（折叠）
/// shrinkOffset 驱动：
/// - 字号从 24 缩小到 16
/// - 副标题从可见变为透明
class _ContactSectionDelegate extends SliverPersistentHeaderDelegate {
  _ContactSectionDelegate({required this.letter, required this.theme});

  final String letter;
  final ThemeData theme;

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 100;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final shrinkRatio = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final fontSize = 24 - (8 * shrinkRatio); // 24 → 16
    final subtitleOpacity = 1.0 - shrinkRatio;

    return Container(
      color: theme.colorScheme.surface,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            letter,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          if (subtitleOpacity > 0.1)
            Opacity(
              opacity: subtitleOpacity,
              child: Text(
                '联系人分组',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _ContactSectionDelegate oldDelegate) =>
      letter != oldDelegate.letter;
}
