import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/core/router/app_router.dart';
import 'package:flutter_clean_arch_template/features/_example/domain/entities/example_item.dart';
import 'package:flutter_clean_arch_template/features/_example/presentation/providers/example_list_provider.dart';
import 'package:flutter_clean_arch_template/shared/responsive/responsive_utils.dart';
import 'package:flutter_clean_arch_template/shared/widgets/states/app_error_widget.dart';
import 'package:flutter_clean_arch_template/shared/widgets/states/app_loading_indicator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

@RoutePage()
class ExampleListPage extends ConsumerWidget {
  const ExampleListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(exampleListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(exampleListProvider.notifier).refresh(),
          ),
        ],
      ),
      body: asyncItems.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No items yet'));
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(exampleListProvider.notifier).refresh(),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = ResponsiveUtils.gridColumns(constraints);
                if (columns > 1) {
                  return GridView.builder(
                    padding: EdgeInsets.all(16.w),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 8.w,
                      mainAxisSpacing: 8.w,
                      childAspectRatio: 3.5,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _ExampleItemCard(
                        item: item,
                        onTap: () => unawaited(context.router.push(ExampleDetailRoute(itemId: item.id))),
                      );
                    },
                  );
                }
                return ListView.separated(
                  padding: EdgeInsets.all(16.w),
                  itemCount: items.length,
                  separatorBuilder: (context, index) => SizedBox(height: 8.h),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _ExampleItemCard(
                      item: item,
                      onTap: () => unawaited(context.router.push(ExampleDetailRoute(itemId: item.id))),
                    );
                  },
                );
              },
            ),
          );
        },
        loading: () => const AppLoadingIndicator(),
        error: (error, stack) =>
            AppErrorWidget(error: error.toString(), onRetry: () => ref.invalidate(exampleListProvider)),
      ),
    );
  }
}

class _ExampleItemCard extends StatelessWidget {
  const _ExampleItemCard({required this.item, this.onTap});
  final ExampleItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: item.isCompleted
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Icon(
            item.isCompleted ? Icons.check : Icons.circle_outlined,
            color: item.isCompleted
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(item.title),
        subtitle: item.description != null
            ? Text(item.description!, maxLines: 1, overflow: TextOverflow.ellipsis)
            : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
