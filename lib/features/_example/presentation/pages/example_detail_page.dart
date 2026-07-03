import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/features/_example/presentation/providers/example_detail_provider.dart';
import 'package:flutter_clean_arch_template/shared/responsive/content_constraint.dart';
import 'package:flutter_clean_arch_template/shared/responsive/responsive_tokens.dart';
import 'package:flutter_clean_arch_template/shared/widgets/states/app_error_widget.dart';
import 'package:flutter_clean_arch_template/shared/widgets/states/app_loading_indicator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

@RoutePage()
class ExampleDetailPage extends ConsumerWidget {
  const ExampleDetailPage({
    @PathParam('itemId') required this.itemId,
    super.key,
  });

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItem = ref.watch(exampleDetailProvider(itemId));

    return Scaffold(
      appBar: AppBar(title: Text('Item #$itemId')),
      body: asyncItem.when(
        data: (item) => ContentConstraint(
          maxWidth: ResponsiveTokens.maxWidthDetail,
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(height: 16.h),
                if (item.description != null)
                  Text(
                    item.description!,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                SizedBox(height: 24.h),
                Chip(
                  label: Text(item.isCompleted ? 'Completed' : 'Pending'),
                  backgroundColor: item.isCompleted
                      ? Colors.green.shade100
                      : Colors.orange.shade100,
                ),
                if (item.createdAt != null) ...[
                  SizedBox(height: 16.h),
                  Text(
                    'Created: ${item.createdAt}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
        loading: () => const AppLoadingIndicator(),
        error: (error, stack) => AppErrorWidget(
          error: error.toString(),
          onRetry: () => ref.invalidate(exampleDetailProvider(itemId)),
        ),
      ),
    );
  }
}
