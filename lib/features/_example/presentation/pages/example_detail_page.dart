import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/core/di/service_locator.dart';
import 'package:flutter_clean_arch_template/features/_example/domain/repositories/example_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

@RoutePage()
class ExampleDetailPage extends ConsumerWidget {
  const ExampleDetailPage({@PathParam('itemId') required this.itemId, super.key});
  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('Item #$itemId')),
      body: FutureBuilder(
        future: getIt<ExampleRepository>().getDetail(itemId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final result = snapshot.data!;
          return result.fold(
            (failure) => Center(child: Text('Error: ${failure.message}')),
            (item) => Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: Theme.of(context).textTheme.headlineSmall),
                  SizedBox(height: 16.h),
                  if (item.description != null)
                    Text(item.description!, style: Theme.of(context).textTheme.bodyLarge),
                  SizedBox(height: 24.h),
                  Chip(
                    label: Text(item.isCompleted ? 'Completed' : 'Pending'),
                    backgroundColor: item.isCompleted ? Colors.green.shade100 : Colors.orange.shade100,
                  ),
                  if (item.createdAt != null) ...[
                    SizedBox(height: 16.h),
                    Text('Created: ${item.createdAt}', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
