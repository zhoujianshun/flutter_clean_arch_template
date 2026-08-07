import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/features/_riverpod_demo/presentation/providers/demo_pagination_sliver_provider.dart';
import 'package:flutter_clean_arch_template/shared/models/pagination_state.dart';
import 'package:flutter_clean_arch_template/shared/responsive/content_constraint.dart';
import 'package:flutter_clean_arch_template/shared/widgets/pagination_list/pagination_sliver_view.dart';
import 'package:flutter_clean_arch_template/shared/widgets/states/app_empty_widget.dart';
import 'package:flutter_clean_arch_template/shared/widgets/states/app_error_widget.dart';
import 'package:flutter_clean_arch_template/shared/widgets/states/app_loading_indicator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Demo: PaginationSliverView 分页列表
///
/// 核心模式：`PaginationState<T>` + `PaginationSliverView<T>` + Sliver 组合
/// 适用场景：复杂页面（头图/筛选条/统计卡片）+ 列表分页
@RoutePage()
class PaginationSliverDemoPage extends ConsumerWidget {
  const PaginationSliverDemoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(demoPaginationSliverProvider);
    final notifier = ref.read(demoPaginationSliverProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('分页 Sliver PaginationSliverView'),
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
        child: Builder(
          builder: (context) {
            if (state.isLoading && state.items.isEmpty) {
              return const AppLoadingIndicator();
            }
            if (state.hasError && state.items.isEmpty) {
              return AppErrorWidget(
                error: state.error ?? '加载失败',
                onRetry: () => ref.invalidate(demoPaginationSliverProvider),
              );
            }

            return PaginationSliverView<String>(
              state: state,
              onRefresh: notifier.refresh,
              onLoadMore: notifier.loadMore,
              slivers: _buildSlivers(context, state),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildSlivers(BuildContext context, PaginationState<String> state) {
    final theme = Theme.of(context);
    final slivers = <Widget>[
      SliverToBoxAdapter(
        child: Card(
          margin: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 8.h),
          color: theme.colorScheme.surfaceContainerLow,
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Text(
              '该示例演示 PaginationSliverView 与 CustomScrollView 配合使用：\n'
              '1) 上方可放统计说明等 Sliver 头部\n'
              '2) 中间是可分页的 Sliver 列表\n'
              '3) 下拉刷新和上拉加载由组件内部统一收口',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ),
      ),
    ];

    if (state.hasError && state.items.isNotEmpty) {
      slivers.add(
        SliverToBoxAdapter(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Text(
              '最近一次请求失败：${state.error}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ),
      );
    }

    if (state.items.isEmpty) {
      slivers.add(
        const SliverFillRemaining(
          hasScrollBody: false,
          child: AppEmptyWidget(message: '暂无数据，下拉刷新试试'),
        ),
      );
      return slivers;
    }

    slivers
      ..add(
        SliverList.builder(
          itemCount: state.items.length,
          itemBuilder: (context, index) {
            final item = state.items[index];
            return Padding(
              padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 8.h),
              child: Card(
                child: ListTile(
                  leading: Icon(
                    Icons.layers_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(item),
                  subtitle: Text('index: $index'),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                ),
              ),
            );
          },
        ),
      )
      ..add(SliverToBoxAdapter(child: SizedBox(height: 12.h)));
    return slivers;
  }
}
