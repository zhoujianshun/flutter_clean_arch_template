import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/features/_riverpod_demo/presentation/providers/demo_dependencies_provider.dart';
import 'package:flutter_clean_arch_template/shared/responsive/content_constraint.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Demo: Riverpod dependencies & ProviderScope 作用域
///
/// 核心演示：每个商品行使用独立的 ProviderScope，
/// override currentProductIdProvider 使子组件自动获取对应 ID 并加载详情。
@RoutePage()
class DependenciesDemoPage extends ConsumerWidget {
  const DependenciesDemoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productListAsync = ref.watch(productListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Dependencies 作用域')),
      body: ContentConstraint(
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            // 原理说明
            Card(
              color: theme.colorScheme.surfaceContainerLow,
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('什么是 dependencies？', style: theme.textTheme.titleSmall),
                    SizedBox(height: 8.h),
                    const Text(
                      'dependencies 用于标记 Provider 可被 ProviderScope 覆盖（scoped）。\n\n'
                      '• dependencies: [] → 此 Provider 可被子树 ProviderScope override\n'
                      '• dependencies: [X] → 此 Provider 依赖了 scoped Provider X，'
                      '自身也必须声明 dependencies',
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12.h),

            // 代码结构
            Card(
              color: theme.colorScheme.surfaceContainerLow,
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('代码结构', style: theme.textTheme.titleSmall),
                    SizedBox(height: 8.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: const Text(
                        '// 1. Scoped Provider（可被 override）\n'
                        '@Riverpod(dependencies: [])\n'
                        'String currentProductId(Ref ref) {\n'
                        '  throw UnimplementedError(...);\n'
                        '}\n'
                        '\n'
                        '// 2. 依赖 scoped Provider 的 Provider\n'
                        '@Riverpod(dependencies: [currentProductId])\n'
                        'Future<Detail> productDetail(Ref ref) {\n'
                        '  final id = ref.watch(currentProductIdProvider);\n'
                        '  return fetchDetail(id);\n'
                        '}\n'
                        '\n'
                        '// 3. 在列表中为每行创建独立作用域\n'
                        'ProviderScope(\n'
                        '  overrides: [\n'
                        '    currentProductIdProvider\n'
                        '      .overrideWithValue(productId),\n'
                        '  ],\n'
                        '  child: ProductCard(),\n'
                        ')',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // 实际效果
            Text('实际效果', style: theme.textTheme.titleMedium),
            Text(
              '下方每个卡片使用独立 ProviderScope，子组件通过 ref.watch 自动获取对应商品详情',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 12.h),

            productListAsync.when(
              data: (productIds) => Column(
                children: [
                  for (final id in productIds) ...[
                    ProviderScope(
                      overrides: [
                        currentProductIdProvider.overrideWithValue(id),
                      ],
                      child: const _ProductCard(),
                    ),
                    SizedBox(height: 8.h),
                  ],
                ],
              ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => Center(child: Text('错误: $error')),
            ),
            SizedBox(height: 16.h),

            // 使用场景
            Card(
              color: theme.colorScheme.surfaceContainerLow,
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('适用场景', style: theme.textTheme.titleSmall),
                    SizedBox(height: 8.h),
                    const Text(
                      '• 列表中每行需要独立的数据上下文（如本示例）\n'
                      '• 嵌套导航中不同页面需要不同的数据源\n'
                      '• 测试中 override Provider 以注入 mock 数据\n'
                      '• 多租户/多账户场景，不同区域使用不同配置\n\n'
                      '注意事项：\n'
                      '• 未标记 dependencies 的 Provider 无法被 override\n'
                      '• 如果 A 依赖了 scoped 的 B，A 也必须声明 dependencies\n'
                      '• Scoped Provider 的 build() 应抛出 UnimplementedError，'
                      '强制外部 override 提供值',
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
}

/// 商品卡片 — 自动从 ProviderScope 中获取商品 ID 并加载详情
class _ProductCard extends ConsumerWidget {
  const _ProductCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = ref.watch(currentProductIdProvider);
    final detailAsync = ref.watch(productDetailProvider);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: detailAsync.when(
          data: (detail) => Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  detail.name.characters.first,
                  style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(detail.name, style: theme.textTheme.titleSmall),
                    SizedBox(height: 2.h),
                    Text(
                      detail.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '¥${detail.price.toStringAsFixed(0)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'ID: $id',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ],
          ),
          loading: () => Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12.w),
              Text('加载 $id...', style: theme.textTheme.bodySmall),
            ],
          ),
          error: (error, _) => Text('错误: $error'),
        ),
      ),
    );
  }
}
