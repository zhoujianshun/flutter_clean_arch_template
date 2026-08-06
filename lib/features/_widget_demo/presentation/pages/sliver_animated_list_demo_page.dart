import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 场景 4：SliverAnimatedList
///
/// 演示带动画的动态增删列表：
/// - `insertItem` / `removeItem` 触发动画
/// - 自定义动画效果（fade + slide）
/// - 结合 GlobalKey<SliverAnimatedListState> 控制
///
/// 业务场景：购物车、收藏夹、待办清单
@RoutePage()
class SliverAnimatedListDemoPage extends StatefulWidget {
  const SliverAnimatedListDemoPage({super.key});

  @override
  State<SliverAnimatedListDemoPage> createState() =>
      _SliverAnimatedListDemoPageState();
}

class _SliverAnimatedListDemoPageState
    extends State<SliverAnimatedListDemoPage> {
  final _listKey = GlobalKey<SliverAnimatedListState>();
  final _items = <String>[];
  int _counter = 0;

  void _addItem() {
    _counter++;
    final index = _items.length;
    _items.add('商品 $_counter');
    _listKey.currentState?.insertItem(index,
        duration: const Duration(milliseconds: 400));
  }

  void _removeItem(int index) {
    final removed = _items.removeAt(index);
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildItem(removed, animation, removing: true),
      duration: const Duration(milliseconds: 300),
    );
  }

  void _removeAll() {
    for (var i = _items.length - 1; i >= 0; i--) {
      final removed = _items.removeAt(i);
      _listKey.currentState?.removeItem(
        i,
        (context, animation) => _buildItem(removed, animation, removing: true),
        duration: const Duration(milliseconds: 200),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.medium(
            title: const Text('SliverAnimatedList'),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_sweep),
                tooltip: '清空',
                onPressed: _items.isEmpty ? null : _removeAll,
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Card(
              margin: EdgeInsets.all(16.w),
              color: theme.colorScheme.surfaceContainerLow,
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('使用要点', style: theme.textTheme.titleSmall),
                    SizedBox(height: 8.h),
                    const Text(
                      '• GlobalKey<SliverAnimatedListState> 控制增删\n'
                      '• insertItem(index) → 触发插入动画\n'
                      '• removeItem(index, builder) → builder 构建退出动画\n'
                      '• 动画结合 SizeTransition + FadeTransition',
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverAnimatedList(
            key: _listKey,
            initialItemCount: _items.length,
            itemBuilder: (context, index, animation) =>
                _buildItem(_items[index], animation),
          ),

          // 空状态提示
          if (_items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shopping_cart_outlined, size: 48,
                        color: theme.colorScheme.outline),
                    SizedBox(height: 12.h),
                    Text('购物车为空', style: theme.textTheme.bodyLarge),
                    SizedBox(height: 4.h),
                    Text('点击右下角按钮添加商品',
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addItem,
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('添加'),
      ),
    );
  }

  Widget _buildItem(String title, Animation<double> animation,
      {bool removing = false}) {
    final theme = Theme.of(context);

    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: Card(
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          color: removing
              ? theme.colorScheme.errorContainer
              : theme.colorScheme.surface,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: removing
                  ? theme.colorScheme.error
                  : theme.colorScheme.primaryContainer,
              child: Icon(
                removing ? Icons.remove : Icons.shopping_bag_outlined,
                color: removing
                    ? theme.colorScheme.onError
                    : theme.colorScheme.onPrimaryContainer,
                size: 20,
              ),
            ),
            title: Text(title),
            subtitle: Text(removing ? '正在移除...' : '左滑或点击删除'),
            trailing: removing
                ? null
                : IconButton(
                    icon: Icon(Icons.delete_outline,
                        color: theme.colorScheme.error),
                    onPressed: () {
                      final idx = _items.indexOf(title);
                      if (idx != -1) _removeItem(idx);
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
