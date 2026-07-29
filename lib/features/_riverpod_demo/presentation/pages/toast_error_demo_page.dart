import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/features/_riverpod_demo/presentation/providers/demo_toast_error_provider.dart';
import 'package:flutter_clean_arch_template/shared/responsive/content_constraint.dart';
import 'package:flutter_clean_arch_template/shared/widgets/pop/my_easy_pop_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Demo 2: ref.listen + Toast 错误提示
///
/// 核心模式：刷新失败时保留旧数据，仅用 Toast 提示错误
/// 适用场景：已有数据的列表刷新、后台同步失败等不应替换 UI 的场景
@RoutePage()
class ToastErrorDemoPage extends ConsumerStatefulWidget {
  const ToastErrorDemoPage({super.key});

  @override
  ConsumerState<ToastErrorDemoPage> createState() => _ToastErrorDemoPageState();
}

class _ToastErrorDemoPageState extends ConsumerState<ToastErrorDemoPage> {
  bool _shouldFail = false;

  @override
  Widget build(BuildContext context) {
    // 监听 error 态 → 弹 Toast
    ref.listen(demoToastErrorProvider, (previous, next) {
      if (next is AsyncError) {
        MyEasyPopMessage.showErrorUnawaited(
          (next as AsyncError).error.toString(),
        );
      }
    });

    final asyncData = ref.watch(demoToastErrorProvider);
    final items = asyncData.value ?? [];
    final isLoading = asyncData.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Toast 错误提示'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isLoading
                ? null
                : () => ref
                    .read(demoToastErrorProvider.notifier)
                    .refresh(shouldFail: _shouldFail),
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
                title: const Text('模拟刷新失败'),
                subtitle: const Text('开启后刷新将触发 Toast 错误，数据保留'),
                value: _shouldFail,
                onChanged: (v) => setState(() => _shouldFail = v),
              ),
            ),

            // loading 指示器
            if (isLoading) const LinearProgressIndicator(),

            // 数据列表（始终展示，不因错误消失）
            Expanded(
              child: items.isEmpty
                  ? const Center(child: Text('暂无数据'))
                  : ListView.separated(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => SizedBox(height: 8.h),
                      itemBuilder: (_, index) => Card(
                        child: ListTile(
                          leading: CircleAvatar(child: Text('${index + 1}')),
                          title: Text(items[index]),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
