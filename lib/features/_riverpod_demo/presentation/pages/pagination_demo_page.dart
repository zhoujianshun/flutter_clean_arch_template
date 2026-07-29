import 'package:auto_route/auto_route.dart';
import 'package:easy_refresh/easy_refresh.dart';
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
class PaginationDemoPage extends ConsumerStatefulWidget {
  const PaginationDemoPage({super.key});

  @override
  ConsumerState<PaginationDemoPage> createState() =>
      _PaginationDemoPageState();
}

class _PaginationDemoPageState extends ConsumerState<PaginationDemoPage> {
  late final EasyRefreshController _refreshController;

  @override
  void initState() {
    super.initState();
    _refreshController = EasyRefreshController(
      controlFinishRefresh: true,
      controlFinishLoad: true,
    );
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          controller: _refreshController,
          onRefresh: () async {
            await notifier.refresh();
            _refreshController.finishRefresh();
          },
          onLoadMore: () async {
            await notifier.loadMore();
            _refreshController.finishLoad(
              state.hasMore ? IndicatorResult.success : IndicatorResult.noMore,
            );
          },
          onRetry: () => ref.invalidate(demoPaginationProvider),
          itemBuilder: (context, item) => Card(
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
