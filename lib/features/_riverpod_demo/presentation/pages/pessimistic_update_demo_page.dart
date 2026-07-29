import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/features/_riverpod_demo/presentation/providers/demo_pessimistic_provider.dart';
import 'package:flutter_clean_arch_template/shared/responsive/content_constraint.dart';
import 'package:flutter_clean_arch_template/shared/widgets/pop/my_easy_pop_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Demo: 悲观更新（Pessimistic Update）
///
/// 与乐观更新相反：点击后先显示单项 loading → 等待异步结果 → 成功才更新 UI
/// 适用场景：支付、删除等不可逆操作，需要确认服务端成功后才更新
@RoutePage()
class PessimisticUpdateDemoPage extends ConsumerStatefulWidget {
  const PessimisticUpdateDemoPage({super.key});

  @override
  ConsumerState<PessimisticUpdateDemoPage> createState() =>
      _PessimisticUpdateDemoPageState();
}

class _PessimisticUpdateDemoPageState
    extends ConsumerState<PessimisticUpdateDemoPage> {
  bool _shouldFail = false;

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(demoPessimisticProvider);
    final notifier = ref.read(demoPessimisticProvider.notifier);
    final pendingIds = notifier.pendingIds;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('悲观更新 Pessimistic')),
      body: ContentConstraint(
        child: Column(
          children: [
            Card(
              margin: EdgeInsets.all(16.w),
              child: SwitchListTile(
                title: const Text('模拟操作失败'),
                subtitle: const Text('开启后收藏操作将失败，UI 不会变化'),
                value: _shouldFail,
                onChanged: (v) => setState(() => _shouldFail = v),
              ),
            ),

            // 对比说明
            Card(
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              color: theme.colorScheme.surfaceContainerLow,
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: const Text(
                  '悲观更新 vs 乐观更新：\n'
                  '• 悲观：点击 → loading → 服务端确认 → 更新 UI\n'
                  '• 乐观：点击 → 立即更新 UI → 服务端确认 → 失败则回滚',
                ),
              ),
            ),
            SizedBox(height: 8.h),

            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: items.length,
                separatorBuilder: (context, index) => SizedBox(height: 4.h),
                itemBuilder: (_, index) {
                  final item = items[index];
                  final isPending = pendingIds.contains(item.id);

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
                        isPending
                            ? '处理中...'
                            : (item.isFavorited ? '已收藏' : '未收藏'),
                        style: TextStyle(
                          color: isPending
                              ? theme.colorScheme.tertiary
                              : (item.isFavorited
                                  ? theme.colorScheme.primary
                                  : null),
                        ),
                      ),
                      trailing: isPending
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.primary,
                              ),
                            )
                          : IconButton(
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
          .read(demoPessimisticProvider.notifier)
          .toggleFavorite(id, shouldFail: _shouldFail);
      if (_shouldFail) return;
      MyEasyPopMessage.showSuccessUnawaited('操作成功');
    } on Exception catch (e) {
      MyEasyPopMessage.showErrorUnawaited('$e');
    }
  }
}
