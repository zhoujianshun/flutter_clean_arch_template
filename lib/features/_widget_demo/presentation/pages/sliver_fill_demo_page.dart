import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 场景 3：SliverFillRemaining & SliverFillViewport
///
/// - `SliverFillRemaining`：填充 CustomScrollView 剩余空间
///   - 空状态页（内容少时居中）
///   - 底部固定按钮（表单场景）
///   - `hasScrollBody: false` 让内容不可滚动
/// - `SliverFillViewport`：每个子项占满整个视口（全屏分页）
@RoutePage()
class SliverFillDemoPage extends StatefulWidget {
  const SliverFillDemoPage({super.key});

  @override
  State<SliverFillDemoPage> createState() => _SliverFillDemoPageState();
}

class _SliverFillDemoPageState extends State<SliverFillDemoPage>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fill 系列'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '空状态'),
            Tab(text: '底部按钮'),
            Tab(text: '全屏分页'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEmptyState(theme),
          _buildBottomButton(theme),
          _buildFullPageViewport(theme),
        ],
      ),
    );
  }

  /// Tab 1: SliverFillRemaining 空状态居中
  Widget _buildEmptyState(ThemeData theme) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Card(
            margin: EdgeInsets.all(16.w),
            color: theme.colorScheme.surfaceContainerLow,
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: const Text(
                'SliverFillRemaining + hasScrollBody: false\n'
                '→ 内容少时自动填充剩余空间并居中显示',
              ),
            ),
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox_outlined, size: 64,
                    color: theme.colorScheme.outline),
                SizedBox(height: 16.h),
                Text('暂无数据', style: theme.textTheme.titleMedium),
                SizedBox(height: 8.h),
                Text('当列表为空时，此区域自动填满剩余空间',
                    style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Tab 2: SliverFillRemaining 底部固定按钮
  Widget _buildBottomButton(ThemeData theme) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Card(
            margin: EdgeInsets.all(16.w),
            color: theme.colorScheme.surfaceContainerLow,
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: const Text(
                'SliverFillRemaining + hasScrollBody: false\n'
                '→ 表单内容少时，提交按钮固定在底部',
              ),
            ),
          ),
        ),

        // 模拟表单
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              children: [
                TextField(decoration: const InputDecoration(labelText: '用户名')),
                SizedBox(height: 12.h),
                TextField(decoration: const InputDecoration(labelText: '邮箱')),
                SizedBox(height: 12.h),
                TextField(decoration: const InputDecoration(labelText: '手机号')),
              ],
            ),
          ),
        ),

        // 按钮始终在底部
        SliverFillRemaining(
          hasScrollBody: false,
          child: Container(
            alignment: Alignment.bottomCenter,
            padding: EdgeInsets.all(16.w),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {},
                child: const Text('提交'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Tab 3: SliverFillViewport 全屏分页
  Widget _buildFullPageViewport(ThemeData theme) {
    final colors = [
      theme.colorScheme.primaryContainer,
      theme.colorScheme.secondaryContainer,
      theme.colorScheme.tertiaryContainer,
    ];

    return CustomScrollView(
      slivers: [
        SliverFillViewport(
          delegate: SliverChildBuilderDelegate(
            (context, index) => Container(
              color: colors[index % colors.length],
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Page ${index + 1}',
                      style: theme.textTheme.headlineMedium,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'SliverFillViewport: 每项占满整个视口',
                      style: theme.textTheme.bodyMedium,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '适用于 Onboarding、引导页等全屏分页场景',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            childCount: 3,
          ),
        ),
      ],
    );
  }
}
