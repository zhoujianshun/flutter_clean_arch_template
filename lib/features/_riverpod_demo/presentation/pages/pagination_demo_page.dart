import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/features/_riverpod_demo/presentation/providers/demo_pagination_provider.dart';
import 'package:flutter_clean_arch_template/shared/responsive/content_constraint.dart';
import 'package:flutter_clean_arch_template/shared/widgets/pagination_list/pagination_list.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Demo 3: PaginationList 分页列表
///
/// 核心模式：`PaginationState<T>` + `PaginationList<T>` + EasyRefresh
/// 适用场景：消息列表、订单列表、商品列表等需要分页加载的场景
@RoutePage()
class PaginationDemoPage extends ConsumerWidget {
  const PaginationDemoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(demoPaginationProvider);
    final notifier = ref.read(demoPaginationProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('分页列表 PaginationList'),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: Center(
              child: Text(
                '${state.items.length}/${state.total}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
      body: ContentConstraint(
        child: PaginationList<String>(
          state: state,
          onRefresh: notifier.refresh,
          onLoadMore: notifier.loadMore,
          onRetry: () => ref.invalidate(demoPaginationProvider),
          itemBuilder: (context, item, index) => Card(
            child: ListTile(
              leading: Icon(
                Icons.article_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(item),
              trailing: const Icon(Icons.chevron_right, size: 18),
            ),
          ),
        ),
      ),
    );
  }
}
