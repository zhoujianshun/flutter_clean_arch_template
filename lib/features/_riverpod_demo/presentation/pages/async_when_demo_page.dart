import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/features/_riverpod_demo/presentation/providers/demo_async_provider.dart';
import 'package:flutter_clean_arch_template/shared/responsive/content_constraint.dart';
import 'package:flutter_clean_arch_template/shared/widgets/states/app_error_widget.dart';
import 'package:flutter_clean_arch_template/shared/widgets/states/app_loading_indicator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Demo 1: AsyncValue.when 全页三态切换
///
/// 核心模式：ref.watch(provider).when(data:, loading:, error:)
/// 适用场景：页面首次加载、详情页加载等需要全屏切换状态的场景
@RoutePage()
class AsyncWhenDemoPage extends ConsumerWidget {
  const AsyncWhenDemoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(demoAsyncProvider);
    final notifier = ref.read(demoAsyncProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AsyncValue.when'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(demoAsyncProvider),
          ),
        ],
      ),
      body: ContentConstraint(
        child: Column(
          children: [
            // 控制面板
            Card(
              margin: EdgeInsets.all(16.w),
              child: SwitchListTile(
                title: const Text('模拟失败模式'),
                subtitle: const Text('开启后刷新将触发错误状态'),
                value: notifier.shouldFail,
                onChanged: (v) {
                  notifier.toggleFailMode(value: v);
                  ref.invalidate(demoAsyncProvider);
                },
              ),
            ),

            // 三态内容区域
            Expanded(
              child: asyncData.when(
                data: (items) => _buildContent(context, items),
                loading: () => const AppLoadingIndicator(),
                error: (error, _) => AppErrorWidget(
                  error: error.toString(),
                  onRetry: () => ref.invalidate(demoAsyncProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<String> items) {
    if (items.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: items.length,
      separatorBuilder: (_, __) => SizedBox(height: 8.h),
      itemBuilder: (_, index) => Card(
        child: ListTile(
          leading: CircleAvatar(child: Text('${index + 1}')),
          title: Text(items[index]),
        ),
      ),
    );
  }
}
