# 创建新功能模块

本教程以虚构的 **`product`（商品）** 功能为例：从 API 获取商品列表并展示详情页。如果你已运行 `tool/setup.dart`，请将 `flutter_clean_arch_template` 替换为你的包名。

---

## 第一步：创建目录结构

```bash
mkdir -p lib/features/product/{data/{datasources,models,repositories},domain/repositories,presentation/{pages,providers,widgets}}
```

结果：

```text
lib/features/product/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   └── repositories/
└── presentation/
    ├── pages/
    ├── providers/
    └── widgets/
```

---

## 第二步：定义数据模型（Freezed）

`lib/features/product/data/models/product_model.dart`：

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_model.freezed.dart';
part 'product_model.g.dart';

@freezed
abstract class ProductModel with _$ProductModel {
  const factory ProductModel({
    required String id,
    required String name,
    @Default(0) double price,
  }) = _ProductModel;

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);
}
```

添加文件后执行代码生成（第九步）。单一数据类使用 **`@freezed abstract class`**（Freezed 3+）。

可选的请求模型 `lib/features/product/data/models/get_products_request.dart`：

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'get_products_request.freezed.dart';
part 'get_products_request.g.dart';

@freezed
abstract class GetProductsRequest with _$GetProductsRequest {
  const factory GetProductsRequest({
    @Default(1) int pageNum,
    @Default(20) int pageSize,
  }) = _GetProductsRequest;

  factory GetProductsRequest.fromJson(Map<String, dynamic> json) =>
      _$GetProductsRequestFromJson(json);
}
```

---

## 第三步：创建 DataSource

使用 `BaseAPI` + `ApiClient`。`lib/features/product/data/datasources/product_remote_datasource.dart`：

```dart
import 'package:dartz/dartz.dart';
import 'package:flutter_clean_arch_template/core/errors/failures.dart';
import 'package:flutter_clean_arch_template/core/network/base_api.dart';
import 'package:flutter_clean_arch_template/features/product/data/models/product_model.dart';
import 'package:injectable/injectable.dart';

class ProductApiEndpoints {
  static const String products = '/products';
  static String productById(String id) => '/products/$id';
}

@Injectable()
class ProductRemoteDataSource extends BaseAPI {
  ProductRemoteDataSource(super.apiClient);

  Future<Either<Failure, List<ProductModel>>> getProducts() async {
    return handleApiListCall(
      apiClient.get(ProductApiEndpoints.products),
      ProductModel.fromJson,
      logTag: 'ProductRemoteDataSource.getProducts',
    );
  }

  Future<Either<Failure, ProductModel>> getProduct(String id) async {
    return handleApiCall(
      apiClient.get(ProductApiEndpoints.productById(id)),
      ProductModel.fromJson,
      logTag: 'ProductRemoteDataSource.getProduct',
    );
  }
}
```

分页 API 可使用 `BaseAPI` 的 `handlePaginatedApiCall`（参见其文档注释）。

---

## 第四步：定义 Repository 接口

`lib/features/product/domain/repositories/product_repository.dart`：

```dart
import 'package:dartz/dartz.dart';
import 'package:flutter_clean_arch_template/core/errors/failures.dart';
import 'package:flutter_clean_arch_template/features/product/data/models/product_model.dart';

abstract class ProductRepository {
  Future<Either<Failure, List<ProductModel>>> getProducts();
  Future<Either<Failure, ProductModel>> getProduct(String id);
}
```

> 当无需额外映射时，本模版推荐在 Repository 接口中直接复用 **数据层 Model**。当 API 数据结构与 UI 需求不一致时，可引入领域层 **Entity**。

---

## 第五步：实现 Repository

`lib/features/product/data/repositories/product_repository_impl.dart`：

```dart
import 'package:dartz/dartz.dart';
import 'package:flutter_clean_arch_template/core/errors/failures.dart';
import 'package:flutter_clean_arch_template/features/product/data/datasources/product_remote_datasource.dart';
import 'package:flutter_clean_arch_template/features/product/data/models/product_model.dart';
import 'package:flutter_clean_arch_template/features/product/domain/repositories/product_repository.dart';
import 'package:injectable/injectable.dart';

@Singleton(as: ProductRepository)
class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl(this._remote);

  final ProductRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<ProductModel>>> getProducts() {
    return _remote.getProducts();
  }

  @override
  Future<Either<Failure, ProductModel>> getProduct(String id) {
    return _remote.getProduct(id);
  }
}
```

---

## 第六步：创建 Provider（Riverpod）

`lib/features/product/presentation/providers/product_list_provider.dart`：

```dart
import 'package:flutter_clean_arch_template/core/di/service_locator.dart';
import 'package:flutter_clean_arch_template/features/product/data/models/product_model.dart';
import 'package:flutter_clean_arch_template/features/product/domain/repositories/product_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'product_list_provider.g.dart';

@riverpod
Future<List<ProductModel>> productList(Ref ref) async {
  final repository = getIt<ProductRepository>();
  final result = await repository.getProducts();
  return result.fold(
    (failure) => throw failure,
    (list) => list,
  );
}
```

需要可变 UI 状态时，使用 `@Riverpod` **class** Notifier（参见模版中的 `auth_provider.dart`）。

---

## 第七步：创建页面和组件

`lib/features/product/presentation/pages/product_list_page.dart`：

```dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_clean_arch_template/features/product/presentation/providers/product_list_provider.dart';

@RoutePage()
class ProductListPage extends ConsumerWidget {
  const ProductListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(productListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('商品列表')),
      body: async.when(
        data: (items) => ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, i) => ListTile(
            title: Text(items[i].name),
            subtitle: Text('¥${items[i].price}'),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
```

---

## 第八步：注册路由

1. 在 `lib/core/router/app_router.dart` 中导入页面
2. 添加 `AutoRoute` 条目：

```dart
AutoRoute(
  page: ProductListRoute.page,
  path: '/products',
),
```

3. 如果页面应在 Shell 内展示，将其添加到 Shell 的 `children` 中

---

## 第九步：运行代码生成

在项目根目录执行：

```bash
just gen
```

这将重新生成：

- `product_list_provider.g.dart`
- Freezed/JSON 相关文件
- `app_router.gr.dart`
- `service_locator.config.dart`（Injectable）

然后运行：

```bash
just dev
```

修复所有分析器问题，并在 API 接口稳定后在 `test/` 下添加对应测试。
