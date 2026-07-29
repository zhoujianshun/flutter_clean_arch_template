import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 场景 1：基础折叠（pinned + FlexibleSpaceBar）
///
/// 关键属性：
/// - `pinned: true`：折叠后 AppBar 固定在顶部
/// - `expandedHeight`：展开时的总高度
/// - `FlexibleSpaceBar`：提供视差折叠效果（title + background）
///
/// 业务场景：商品详情页、个人主页顶部大图
@RoutePage()
class SliverBasicDemoPage extends StatelessWidget {
  const SliverBasicDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 280.h,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('商品详情'),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primaryContainer,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        size: 80,
                        color: theme.colorScheme.onPrimary.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  // 底部渐变遮罩，让标题更清晰
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(0, 0.6),
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black26],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 属性说明
          SliverToBoxAdapter(
            child: Card(
              margin: EdgeInsets.all(16.w),
              color: theme.colorScheme.surfaceContainerLow,
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('关键属性', style: theme.textTheme.titleSmall),
                    SizedBox(height: 8.h),
                    const Text(
                      '• pinned: true → 折叠后 AppBar 固定在顶部\n'
                      '• expandedHeight: 280 → 展开时总高度\n'
                      '• FlexibleSpaceBar → 视差折叠 + 标题缩放\n'
                      '• collapseMode: parallax → 背景视差滚动（默认）',
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 模拟内容列表
          SliverList.builder(
            itemCount: 30,
            itemBuilder: (context, index) => ListTile(
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text('商品规格 ${index + 1}'),
              subtitle: Text('详细描述信息 #${index + 1}'),
            ),
          ),
        ],
      ),
    );
  }
}
