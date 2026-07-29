import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/features/_riverpod_demo/presentation/providers/demo_filter_provider.dart';
import 'package:flutter_clean_arch_template/shared/responsive/content_constraint.dart';
import 'package:flutter_clean_arch_template/shared/widgets/states/app_error_widget.dart';
import 'package:flutter_clean_arch_template/shared/widgets/states/app_loading_indicator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Demo 5: 多 Provider 联动（筛选 + 列表）
///
/// 核心模式：Notifier 管理筛选条件 → 列表 Provider ref.watch 筛选条件
///          → 筛选变化时列表自动重新加载
/// 适用场景：分类筛选、搜索过滤、条件查询等需要响应式依赖的场景
@RoutePage()
class FilterListDemoPage extends ConsumerWidget {
  const FilterListDemoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(filterCategoryProvider);
    final asyncItems = ref.watch(demoFilterListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('筛选联动 Filter')),
      body: ContentConstraint(
        child: Column(
          children: [
            // 筛选栏
            SizedBox(
              height: 56.h,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                children: [
                  Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: ChoiceChip(
                      label: const Text('全部'),
                      selected: selectedCategory == null,
                      onSelected: (_) => ref
                          .read(filterCategoryProvider.notifier)
                          .select(null),
                    ),
                  ),
                  ...DemoFilterList.categories.map(
                    (cat) => Padding(
                      padding: EdgeInsets.only(right: 8.w),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: selectedCategory == cat,
                        onSelected: (_) => ref
                            .read(filterCategoryProvider.notifier)
                            .select(cat),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // 列表
            Expanded(
              child: asyncItems.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const Center(child: Text('该分类暂无商品'));
                  }
                  return ListView.separated(
                    padding: EdgeInsets.all(16.w),
                    itemCount: items.length,
                    separatorBuilder: (context, index) => SizedBox(height: 8.h),
                    itemBuilder: (_, index) {
                      final item = items[index];
                      return Card(
                        child: ListTile(
                          leading: Icon(
                            Icons.shopping_bag_outlined,
                            color: theme.colorScheme.primary,
                          ),
                          title: Text(item.name),
                          subtitle: Text(item.category),
                          trailing: Chip(
                            label: Text(
                              item.category,
                              style: theme.textTheme.labelSmall,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const AppLoadingIndicator(),
                error: (error, _) => AppErrorWidget(
                  error: error.toString(),
                  onRetry: () => ref.invalidate(demoFilterListProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
