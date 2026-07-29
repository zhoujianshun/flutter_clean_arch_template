import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/shared/responsive/content_constraint.dart';
import 'package:flutter_clean_arch_template/shared/widgets/app_card.dart';
import 'package:flutter_clean_arch_template/shared/widgets/app_rating_bar.dart';
import 'package:flutter_clean_arch_template/shared/widgets/app_tag.dart';
import 'package:flutter_clean_arch_template/shared/widgets/badges/red_dot_badge.dart';
import 'package:flutter_clean_arch_template/shared/widgets/gradient_icon.dart';
import 'package:flutter_clean_arch_template/shared/widgets/row_item/info_row.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

@RoutePage()
class DataDisplayDemoPage extends StatefulWidget {
  const DataDisplayDemoPage({super.key});

  @override
  State<DataDisplayDemoPage> createState() => _DataDisplayDemoPageState();
}

class _DataDisplayDemoPageState extends State<DataDisplayDemoPage> {
  double _rating = 3.5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('数据展示 Data Display')),
      body: ContentConstraint(
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            // AppCard
            const _SectionTitle('AppCard', '主题化卡片容器（支持圆角/阴影/边框）'),
            const AppCard(
              child: Text('默认样式 AppCard，带有主题化的背景色和 16.r 圆角'),
            ),
            SizedBox(height: 8.h),
            AppCard(
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              child: const Text('自定义圆角 24.r + 阴影'),
            ),
            SizedBox(height: 8.h),
            AppCard(
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: theme.colorScheme.outlineVariant),
              padding: EdgeInsets.all(12.w),
              child: const Text('小圆角 8.r + 边框'),
            ),
            SizedBox(height: 8.h),
            AppCard(
              onTap: () {},
              padding: EdgeInsets.all(12.w),
              child: Row(
                children: [
                  Icon(Icons.touch_app, color: theme.colorScheme.primary),
                  SizedBox(width: 8.w),
                  const Expanded(
                    child: Text('按压缩放动画（onTap 自动启用）'),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            AppCard(
              onTap: () {},
              pressScale: 0.92,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
              child: Row(
                children: [
                  Icon(Icons.apps, size: 40.r, color: theme.colorScheme.primary),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'App Store 风格',
                          style: theme.textTheme.titleSmall,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          '按压缩小至 92%，松手弹回',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // InfoRow
            const _SectionTitle('InfoRow', '标签-值信息行'),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  children: [
                    const InfoRow(label: '订单编号', value: 'ORD-2026-001234'),
                    SizedBox(height: 12.h),
                    const InfoRow(label: '下单时间', value: '2026-07-29 14:00'),
                    SizedBox(height: 12.h),
                    const InfoRow(
                      label: '订单状态',
                      value: '已完成',
                      valueColor: Colors.green,
                    ),
                    SizedBox(height: 12.h),
                    InfoRow(
                      label: '操作',
                      value: '',
                      tailWidget: TextButton(
                        onPressed: () {},
                        child: const Text('查看详情'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // AppTag
            const _SectionTitle('AppTag', '标签组件'),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: [
                    AppTag(text: '热门推荐', color: theme.colorScheme.primary),
                    const AppTag(text: '已完成', color: Colors.green),
                    const AppTag(text: '待处理', color: Colors.orange),
                    const AppTag(text: '已取消', color: Colors.red),
                    const AppTag(text: '新品上市', color: Colors.purple),
                    AppTag(text: 'VIP专享', color: Colors.amber.shade700),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // AppRatingBar
            const _SectionTitle('AppRatingBar', '评分组件（支持半星）'),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('可交互评分：${_rating.toStringAsFixed(1)}', style: theme.textTheme.bodyMedium),
                    SizedBox(height: 8.h),
                    AppRatingBar(
                      rating: _rating,
                      onRatingUpdate: (v) => setState(() => _rating = v),
                    ),
                    SizedBox(height: 16.h),
                    Text('只读评分（带文字）', style: theme.textTheme.bodyMedium),
                    SizedBox(height: 8.h),
                    const SkyRatingDisplay(
                      rating: 4.5,
                      showRatingText: true,
                    ),
                    SizedBox(height: 16.h),
                    Text('渐变色只读评分', style: theme.textTheme.bodyMedium),
                    SizedBox(height: 8.h),
                    const SkyRatingDisplay(
                      rating: 3.5,
                    ),
                    SizedBox(height: 16.h),
                    Text('适老化大尺寸评分', style: theme.textTheme.bodyMedium),
                    SizedBox(height: 8.h),
                    SkyElderlyRatingBar(
                      rating: 4,
                      onRatingUpdate: (_) {},
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // RedDotBadge
            const _SectionTitle('RedDotBadge', '红点/数字徽章'),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        RedDotBadge(
                          showBadge: true,
                          child: Icon(Icons.mail_outline, size: 32.w),
                        ),
                        SizedBox(height: 8.h),
                        const Text('红点'),
                      ],
                    ),
                    Column(
                      children: [
                        RedDotBadge(
                          showBadge: true,
                          badgeCount: 5,
                          child: Icon(Icons.notifications_none, size: 32.w),
                        ),
                        SizedBox(height: 8.h),
                        const Text('数字(5)'),
                      ],
                    ),
                    Column(
                      children: [
                        RedDotBadge(
                          showBadge: true,
                          badgeCount: 120,
                          child: Icon(Icons.chat_bubble_outline, size: 32.w),
                        ),
                        SizedBox(height: 8.h),
                        const Text('数字(99+)'),
                      ],
                    ),
                    Column(
                      children: [
                        const TabBadge(
                          showBadge: true,
                          badgeCount: 3,
                          child: Text('Tab'),
                        ),
                        SizedBox(height: 8.h),
                        const Text('TabBadge'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // GradientIcon
            const _SectionTitle('GradientIcon', '渐变图标'),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        LinearGradientIcon(
                          icon: Icons.favorite,
                          size: 40.w,
                          colors: const [Colors.pink, Colors.red],
                        ),
                        SizedBox(height: 8.h),
                        const Text('线性渐变'),
                      ],
                    ),
                    Column(
                      children: [
                        RadialGradientIcon(
                          icon: Icons.star,
                          size: 40.w,
                          colors: const [Colors.amber, Colors.orange],
                        ),
                        SizedBox(height: 8.h),
                        const Text('径向渐变'),
                      ],
                    ),
                    Column(
                      children: [
                        GradientIcon(
                          icon: Icons.wb_sunny,
                          size: 40.w,
                          gradient: const LinearGradient(
                            colors: [Colors.cyan, Colors.blue, Colors.purple],
                          ),
                        ),
                        SizedBox(height: 8.h),
                        const Text('自定义渐变'),
                      ],
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
