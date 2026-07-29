import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/features/_riverpod_demo/presentation/providers/demo_form_provider.dart';
import 'package:flutter_clean_arch_template/shared/responsive/content_constraint.dart';
import 'package:flutter_clean_arch_template/shared/widgets/pop/my_easy_pop_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Demo 6: 表单提交（Mutation 模式）
///
/// 核心模式：`AsyncValue<void>` 管理提交状态，ref.listen 监听结果
/// 适用场景：表单提交、数据创建/更新等一次性异步操作
@RoutePage()
class FormSubmitDemoPage extends ConsumerStatefulWidget {
  const FormSubmitDemoPage({super.key});

  @override
  ConsumerState<FormSubmitDemoPage> createState() =>
      _FormSubmitDemoPageState();
}

class _FormSubmitDemoPageState extends ConsumerState<FormSubmitDemoPage> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  bool _shouldFail = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 监听提交结果
    ref.listen(demoFormSubmitProvider, (previous, next) {
      next.whenOrNull(
        data: (message) {
          if (message != null) {
            MyEasyPopMessage.showSuccessUnawaited(message);
            _titleController.clear();
            _descController.clear();
            ref.read(demoFormSubmitProvider.notifier).reset();
          }
        },
        error: (error, _) {
          MyEasyPopMessage.showErrorUnawaited(error.toString());
          ref.read(demoFormSubmitProvider.notifier).reset();
        },
      );
    });

    final asyncState = ref.watch(demoFormSubmitProvider);
    final isSubmitting = asyncState.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('表单提交 Form')),
      body: ContentConstraint(
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            // 控制面板
            Card(
              child: SwitchListTile(
                title: const Text('模拟提交失败'),
                subtitle: const Text('开启后提交将触发错误'),
                value: _shouldFail,
                onChanged: isSubmitting
                    ? null
                    : (v) => setState(() => _shouldFail = v),
              ),
            ),
            SizedBox(height: 24.h),

            // 表单
            TextField(
              controller: _titleController,
              enabled: !isSubmitting,
              decoration: const InputDecoration(
                labelText: '标题',
                hintText: '输入标题...',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _descController,
              enabled: !isSubmitting,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: '描述',
                hintText: '输入描述内容...',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24.h),

            // 提交按钮
            FilledButton(
              onPressed: isSubmitting ? null : _handleSubmit,
              style: FilledButton.styleFrom(
                minimumSize: Size(double.infinity, 48.h),
              ),
              child: isSubmitting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    )
                  : const Text('提交'),
            ),
            SizedBox(height: 12.h),

            // 使用说明
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: const Text(
                  '要点：\n'
                  '• Provider 使用 AsyncValue<String?> 管理状态\n'
                  '• null = 空闲，Loading = 提交中\n'
                  '• ref.listen 监听成功/失败 → Toast 提示\n'
                  '• 成功后清空表单 + reset()',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSubmit() {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();

    if (title.isEmpty) {
      MyEasyPopMessage.showInfoUnawaited('请输入标题');
      return;
    }

    unawaited(
      ref.read(demoFormSubmitProvider.notifier).submit(
            title: title,
            description: desc,
            shouldFail: _shouldFail,
          ),
    );
  }
}
