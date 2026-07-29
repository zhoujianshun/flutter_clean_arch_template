import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'demo_dependencies_provider.g.dart';

// ──────────────────────────────────────────────────────
// 场景：商品列表页，每行商品有一个独立的「当前商品 ID」Provider。
// 子组件通过 ref.watch(currentProductIdProvider) 获取当前行的 ID，
// 再通过 productDetailProvider 加载详情 —— 而无需手动传参。
//
// 核心概念：
//   dependencies: []        → 标记此 Provider 可被 ProviderScope.overrides 覆盖
//   dependencies: [scopedX] → 此 Provider 依赖了一个 scoped Provider，自身也必须标记
// ──────────────────────────────────────────────────────

/// 当前商品 ID（Scoped Provider）
///
/// 标记 `dependencies: []` 表示该 Provider 可被 ProviderScope 覆盖。
/// 默认 build() 抛出 UnimplementedError，强制要求在 ProviderScope 中 override。
///
/// 使用方式：
/// ```dart
/// ProviderScope(
///   overrides: [currentProductIdProvider.overrideWithValue('product_123')],
///   child: const ProductCard(),
/// )
/// ```
@Riverpod(dependencies: [])
String currentProductId(Ref ref) {
  throw UnimplementedError('currentProductId 必须通过 ProviderScope override 提供');
}

/// 商品详情 Provider — 依赖于 scoped 的 currentProductId
///
/// 因为依赖了 `currentProductIdProvider`（一个 scoped provider），
/// 所以自身也必须声明 `dependencies: [currentProductId]`。
///
/// 当不同的 ProviderScope 提供不同的 productId 时，
/// 此 Provider 会自动使用对应作用域的 ID 加载不同的数据。
@Riverpod(dependencies: [currentProductId])
FutureOr<ProductDetail> productDetail(Ref ref) async {
  final id = ref.watch(currentProductIdProvider);

  await Future<void>.delayed(const Duration(milliseconds: 600));

  return _mockProducts[id] ??
      ProductDetail(id: id, name: '未知商品', price: 0, description: '商品不存在');
}

/// 全局商品列表（非 scoped，不需要 dependencies）
@riverpod
FutureOr<List<String>> productList(Ref ref) async {
  await Future<void>.delayed(const Duration(milliseconds: 500));
  return _mockProducts.keys.toList();
}

// ──────────────────────────────────────────────────────
// 数据模型 & Mock 数据
// ──────────────────────────────────────────────────────

class ProductDetail {
  const ProductDetail({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
  });

  final String id;
  final String name;
  final double price;
  final String description;
}

const _mockProducts = {
  'p001': ProductDetail(
    id: 'p001',
    name: 'MacBook Pro 16"',
    price: 18999,
    description: 'Apple M3 Max 芯片，36GB 内存',
  ),
  'p002': ProductDetail(
    id: 'p002',
    name: 'iPhone 16 Pro',
    price: 8999,
    description: 'A18 Pro 芯片，钛金属设计',
  ),
  'p003': ProductDetail(
    id: 'p003',
    name: 'AirPods Pro 2',
    price: 1899,
    description: 'H2 芯片，自适应降噪',
  ),
  'p004': ProductDetail(
    id: 'p004',
    name: 'iPad Air M2',
    price: 4799,
    description: 'M2 芯片，10.9 英寸 Liquid Retina',
  ),
  'p005': ProductDetail(
    id: 'p005',
    name: 'Apple Watch Ultra 2',
    price: 5999,
    description: 'S9 芯片，钛金属表壳',
  ),
};
