import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/features/_riverpod_demo/presentation/providers/demo_optimistic_provider.dart';
import 'package:flutter_clean_arch_template/shared/responsive/content_constraint.dart';
import 'package:flutter_clean_arch_template/shared/widgets/pop/my_easy_pop_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Demo 4: 乐观更新（Optimistic Update）
///
/// 核心模式：点击后立即更新 UI → 异步请求 → 失败时回滚 + Toast
/// 适用场景：点赞、收藏、关注等需要即时反馈的操作
@RoutePage()
class OptimisticUpdateDemoPage extends ConsumerStatefulWidget {
  const OptimisticUpdateDemoPage({super.key});

  @override
  ConsumerState<OptimisticUpdateDemoPage> createState() =>
      _OptimisticUpdateDemoPageState();
}

class _OptimisticUpdateDemoPageState
    extends ConsumerState<OptimisticUpdateDemoPage> {
  bool _shouldFail = false;

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(demoOptimisticProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('乐观更新 Optimistic')),
      body: ContentConstraint(
        child: Column(
          children: [
            Card(
              margin: EdgeInsets.all(16.w),
              child: SwitchListTile(
                title: const Text('模拟收藏失败'),
                subtitle: const Text('开启后操作将失败并自动回滚'),
                value: _shouldFail,
                onChanged: (v) => setState(() => _shouldFail = v),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: items.length,
                separatorBuilder: (_, __) => SizedBox(height: 4.h),
                itemBuilder: (_, index) {
                  final item = items[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: item.isFavorited
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surfaceContainerHighest,
                        child: Text('${index + 1}'),
                      ),
                      title: Text(item.title),
                      subtitle: Text(
                        item.isFavorited ? '已收藏' : '未收藏',
                        style: TextStyle(
                          color: item.isFavorited
                              ? theme.colorScheme.primary
                              : null,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          item.isFavorited
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: item.isFavorited ? Colors.red : null,
                        ),
                        onPressed: () => _handleToggle(item.id),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleToggle(String id) async {
    try {
      await ref
          .read(demoOptimisticProvider.notifier)
          .toggleFavorite(id, shouldFail: _shouldFail);
    } on Exception catch (e) {
      MyEasyPopMessage.showErrorUnawaited('$e — 已回滚');
    }
  }
}
