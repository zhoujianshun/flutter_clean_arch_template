import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/features/_riverpod_demo/presentation/providers/demo_retry_provider.dart';
import 'package:flutter_clean_arch_template/shared/responsive/content_constraint.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Demo: Riverpod 3.x Retry 机制三种策略对比
///
/// 1. 默认 retry（指数退避）
/// 2. 禁用 retry
/// 3. 自定义 retry（最多 3 次、仅 TimeoutException）
@RoutePage()
class RetryDemoPage extends ConsumerWidget {
  const RetryDemoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final withRetry = ref.watch(demoRetryWithDefaultProvider);
    final withRetryNotifier = ref.read(demoRetryWithDefaultProvider.notifier);

    final noRetry = ref.watch(demoRetryDisabledProvider);
    final noRetryNotifier = ref.read(demoRetryDisabledProvider.notifier);

    final customRetry = ref.watch(demoRetryCustomProvider);
    final customNotifier = ref.read(demoRetryCustomProvider.notifier);

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Retry 重试机制')),
      body: ContentConstraint(
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            Card(
              color: theme.colorScheme.surfaceContainerLow,
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: const Text(
                  'Riverpod 3.x 新特性：build() 抛出 Exception 后，'
                  '框架自动执行指数退避重试（200ms → 400ms → ... → 6400ms）。\n\n'
                  '重试期间状态为 AsyncLoading 而非 AsyncError，'
                  '因此 .when(error:) 分支不会被触发，UI 一直显示 loading。',
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // --- 1. 默认 retry ---
            _RetrySection(
              title: '① 默认 Retry（指数退避）',
              subtitle: 'throw 后持续 loading，重试计数递增',
              chipLabel: 'retry: 默认',
              chipColor: Colors.orange,
              asyncValue: withRetry,
              retryCount: withRetryNotifier.retryCount,
              controls: _FailToggle(
                shouldFail: withRetryNotifier.shouldFail,
                onToggle: (v) => withRetryNotifier.setFail(value: v),
                onReset: () => withRetryNotifier.setFail(value: false),
              ),
            ),
            SizedBox(height: 16.h),

            // --- 2. 禁用 retry ---
            _RetrySection(
              title: '② 禁用 Retry',
              subtitle: 'throw 后直接显示 error 态',
              chipLabel: 'retry: (_,_)=>null',
              chipColor: Colors.green,
              asyncValue: noRetry,
              controls: _FailToggle(
                shouldFail: noRetryNotifier.shouldFail,
                onToggle: (v) => noRetryNotifier.setFail(value: v),
                onReset: () => noRetryNotifier.setFail(value: false),
              ),
            ),
            SizedBox(height: 16.h),

            // --- 3. 自定义 retry ---
            _RetrySection(
              title: '③ 自定义 Retry',
              subtitle: '最多 3 次、间隔 1 秒、仅对 TimeoutException 重试',
              chipLabel: 'retry: 自定义',
              chipColor: Colors.blue,
              asyncValue: customRetry,
              retryCount: customNotifier.retryCount,
              controls: _CustomRetryControls(
                errorType: customNotifier.errorType,
                onChanged: customNotifier.setErrorType,
              ),
            ),
            SizedBox(height: 16.h),

            // 代码示例
            _buildCodeExample(theme),
            SizedBox(height: 16.h),

            // 要点总结
            Card(
              color: theme.colorScheme.surfaceContainerLow,
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('要点总结', style: theme.textTheme.titleSmall),
                    SizedBox(height: 8.h),
                    const Text(
                      '• 默认 retry 适用于：网络抖动、临时故障等可自动恢复的场景\n'
                      '• 禁用 retry 适用于：需要立即展示错误 UI 让用户手动重试的场景\n'
                      '• 自定义 retry 适用于：仅对特定错误重试，并控制次数和间隔\n'
                      '• Error 类型（AssertionError 等）默认不会触发 retry\n'
                      '• 返回 Duration → 等待后重试；返回 null → 停止重试，进入 AsyncError',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeExample(ThemeData theme) {
    return Card(
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('自定义 Retry 代码示例', style: theme.textTheme.titleSmall),
            SizedBox(height: 8.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: const Text(
                '// 自定义函数签名：\n'
                '// Duration? Function(int retryCount, Object error)\n'
                '\n'
                'Duration? _customRetry(int retryCount, Object error) {\n'
                '  if (retryCount >= 3) return null;     // 最多 3 次\n'
                '  if (error is! TimeoutException)        // 仅超时\n'
                '    return null;\n'
                '  return const Duration(seconds: 1);    // 固定 1s\n'
                '}\n'
                '\n'
                '@Riverpod(keepAlive: true, retry: _customRetry)\n'
                'class MyProvider extends _\$MyProvider { ... }',
                style: TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// 通用 Section 组件
// ─────────────────────────────────────────

class _RetrySection extends StatelessWidget {
  const _RetrySection({
    required this.title,
    required this.subtitle,
    required this.chipLabel,
    required this.chipColor,
    required this.asyncValue,
    required this.controls,
    this.retryCount,
  });

  final String title;
  final String subtitle;
  final String chipLabel;
  final Color chipColor;
  final AsyncValue<String> asyncValue;
  final Widget controls;
  final int? retryCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      SizedBox(height: 2.h),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(chipLabel, style: theme.textTheme.labelSmall),
                  backgroundColor: chipColor.withValues(alpha: 0.15),
                  side: BorderSide(color: chipColor.withValues(alpha: 0.4)),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // 状态展示
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Column(
                children: [
                  _buildStatusIndicator(context),
                  if (retryCount != null && retryCount! > 0) ...[
                    SizedBox(height: 8.h),
                    Text(
                      '已重试 $retryCount 次',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 12.h),

            controls,
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(BuildContext context) {
    final theme = Theme.of(context);

    return asyncValue.when(
      data: (value) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          SizedBox(width: 8.w),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
      loading: () => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8.w),
          Text(
            'Loading...（重试中）',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
      error: (error, _) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              error.toString(),
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// 控制组件：简单开关
// ─────────────────────────────────────────

class _FailToggle extends StatelessWidget {
  const _FailToggle({
    required this.shouldFail,
    required this.onToggle,
    required this.onReset,
  });

  final bool shouldFail;
  final ValueChanged<bool> onToggle;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text('模拟失败', style: Theme.of(context).textTheme.bodyMedium),
            value: shouldFail,
            onChanged: onToggle,
          ),
        ),
        FilledButton.tonal(
          onPressed: onReset,
          child: const Text('加载成功'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────
// 控制组件：自定义 retry 错误类型选择
// ─────────────────────────────────────────

class _CustomRetryControls extends StatelessWidget {
  const _CustomRetryControls({
    required this.errorType,
    required this.onChanged,
  });

  final DemoErrorType errorType;
  final ValueChanged<DemoErrorType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('选择错误类型：', style: Theme.of(context).textTheme.bodyMedium),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          children: [
            ChoiceChip(
              label: const Text('TimeoutException'),
              selected: errorType == DemoErrorType.timeout,
              onSelected: (_) => onChanged(DemoErrorType.timeout),
            ),
            ChoiceChip(
              label: const Text('其他 Exception'),
              selected: errorType == DemoErrorType.auth,
              onSelected: (_) => onChanged(DemoErrorType.auth),
            ),
            ChoiceChip(
              label: const Text('无错误'),
              selected: errorType == DemoErrorType.generic,
              onSelected: (_) => onChanged(DemoErrorType.generic),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Text(
          switch (errorType) {
            DemoErrorType.timeout => '→ TimeoutException 匹配自定义规则，将重试最多 3 次',
            DemoErrorType.auth => '→ 非 TimeoutException，不匹配规则，直接进入 error 态',
            DemoErrorType.generic => '→ 无错误，正常返回数据',
          },
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
