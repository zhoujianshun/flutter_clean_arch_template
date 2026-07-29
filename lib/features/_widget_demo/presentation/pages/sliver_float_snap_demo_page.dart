import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 场景 2：浮动 + 吸附（floating + snap）
///
/// 关键属性：
/// - `floating: true`：向下滚动时 AppBar 立刻弹出（不必回到顶部）
/// - `snap: true`：松手后自动吸附到完全展开或完全收起
/// - `pinned: false`（默认）：完全滚出视口后消失
///
/// 业务场景：搜索栏快速弹出、新闻/社交 Feed 列表
@RoutePage()
class SliverFloatSnapDemoPage extends StatefulWidget {
  const SliverFloatSnapDemoPage({super.key});

  @override
  State<SliverFloatSnapDemoPage> createState() =>
      _SliverFloatSnapDemoPageState();
}

class _SliverFloatSnapDemoPageState extends State<SliverFloatSnapDemoPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            expandedHeight: 130.h,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                alignment: Alignment.bottomCenter,
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
                child: SearchBar(
                  controller: _searchController,
                  hintText: '搜索商品、店铺、品牌...',
                  leading: const Icon(Icons.search),
                  trailing: [
                    IconButton(
                      icon: const Icon(Icons.mic_outlined),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
            title: const Text('搜索'),
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
                      '• floating: true → 向下滚动时 AppBar 立刻弹出\n'
                      '• snap: true → 松手后自动吸附（全展开 or 全收起）\n'
                      '• pinned: false → 向上滚动后完全消失\n\n'
                      '操作提示：先向上滚动让列表滑出，再稍微向下滚动观察 AppBar 弹出效果',
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 对比说明
          SliverToBoxAdapter(
            child: Card(
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              color: theme.colorScheme.tertiaryContainer,
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('行为对比', style: theme.textTheme.titleSmall),
                    SizedBox(height: 8.h),
                    const Text(
                      '• floating 单独使用：向下滚一点就弹出，但可以停在半展开状态\n'
                      '• floating + snap：松手后自动全展开或全收起，体验更流畅\n'
                      '• floating + pinned：AppBar 始终可见，但 flexibleSpace 可弹出\n'
                      '• 注意：snap 必须搭配 floating 使用，不能单独设置',
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 模拟 Feed 列表
          SliverList.builder(
            itemCount: 40,
            itemBuilder: (context, index) => Card(
              margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text('${index + 1}'),
                ),
                title: Text('Feed 内容 #${index + 1}'),
                subtitle: const Text('向上滚动隐藏搜索栏，再向下滚动观察弹出效果'),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
