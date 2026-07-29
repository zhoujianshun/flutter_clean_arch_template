import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/shared/responsive/content_constraint.dart';
import 'package:flutter_clean_arch_template/shared/widgets/cached_image/my_cached_network_image.dart';
import 'package:flutter_clean_arch_template/shared/widgets/countdown.dart';
import 'package:flutter_clean_arch_template/shared/widgets/language_switcher.dart';
import 'package:flutter_clean_arch_template/shared/widgets/theme_switcher.dart';
import 'package:flutter_clean_arch_template/shared/widgets/time/real_time_clock.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

@RoutePage()
class UtilityDemoPage extends StatelessWidget {
  const UtilityDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('功能组件 Utilities')),
      body: ContentConstraint(
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            // RealTimeClock
            _SectionTitle('RealTimeClock', '实时时钟（每秒更新）'),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: theme.colorScheme.primary),
                    SizedBox(width: 12.w),
                    const Text('当前时间：'),
                    RealTimeClock(
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Countdown
            _SectionTitle('Countdown', '倒计时组件'),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Countdown(
                    remainingTime: const Duration(minutes: 2, seconds: 30),
                    title: '剩余接单时间',
                    backgroundColor:
                        theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12.w),
                    child: Text(
                      '初始值 2分30秒，实时递减',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // MyCachedNetworkImage
            _SectionTitle('MyCachedNetworkImage', '网络缓存图片'),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: MyCachedNetworkImage(
                        imageUrl: 'https://picsum.photos/seed/demo1/200/200',
                        width: 80.w,
                        height: 80.w,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: MyCachedNetworkImage(
                        imageUrl: 'https://picsum.photos/seed/demo2/200/200',
                        width: 80.w,
                        height: 80.w,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    ClipOval(
                      child: MyCachedNetworkImage(
                        imageUrl: 'https://picsum.photos/seed/demo3/200/200',
                        width: 80.w,
                        height: 80.w,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // LanguageSwitcher
            _SectionTitle('LanguageSwitcher', '语言切换器'),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('完整模式（Full）', style: theme.textTheme.labelMedium),
                    SizedBox(height: 8.h),
                    const LanguageSwitcher(),
                    SizedBox(height: 16.h),
                    Text('紧凑模式（Compact）',
                        style: theme.textTheme.labelMedium),
                    SizedBox(height: 8.h),
                    const LanguageSwitcher(isCompact: true),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // ThemeSwitcher
            _SectionTitle('ThemeSwitcher', '主题切换器（4种样式）'),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ListTile 样式', style: theme.textTheme.labelMedium),
                    const ThemeSwitcher(style: ThemeSwitcherStyle.listTile),
                    Divider(height: 24.h),
                    Text('SegmentedButton 样式',
                        style: theme.textTheme.labelMedium),
                    SizedBox(height: 8.h),
                    const ThemeSwitcher(
                        style: ThemeSwitcherStyle.segmentedButton),
                    Divider(height: 24.h),
                    Text('Dropdown 样式', style: theme.textTheme.labelMedium),
                    SizedBox(height: 8.h),
                    const ThemeSwitcher(style: ThemeSwitcherStyle.dropdown),
                    Divider(height: 24.h),
                    Row(
                      children: [
                        Text('IconButton 样式',
                            style: theme.textTheme.labelMedium),
                        const Spacer(),
                        const ThemeSwitcher(
                            style: ThemeSwitcherStyle.iconButton),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // PaginationList 说明
            _SectionTitle('PaginationList', '分页列表组件'),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '使用方式：\n'
                      'PaginationList<T>(\n'
                      '  state: paginationState,\n'
                      '  onRefresh: () => ref.read(provider.notifier).refresh(),\n'
                      '  onLoadMore: () => ref.read(provider.notifier).loadMore(),\n'
                      '  itemBuilder: (ctx, item) => ListTile(...),\n'
                      '  onRetry: () => ref.read(provider.notifier).retry(),\n'
                      ')\n\n'
                      '组件内置了 EasyRefresh 下拉刷新/上拉加载更多，\n'
                      '以及 loading/error/empty 三种状态自动切换。\n'
                      '完整示例请查看 ExampleListPage。',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, this.subtitle);

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: 2.h),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
