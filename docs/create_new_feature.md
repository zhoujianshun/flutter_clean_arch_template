# Creating a New Feature

This tutorial adds a fictional **`product`** feature: list products from an API and show a detail page. Replace `flutter_clean_arch_template` with your package name if you ran `tool/setup.dart`.

---

## Step 1: Create Directory Structure

```bash
mkdir -p lib/features/product/{data/{datasources,models,repositories},domain/repositories,presentation/{pages,providers,widgets}}
```

Result:

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

## Step 2: Define Data Models (Freezed)

`lib/features/product/data/models/product_model.dart`:

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

Run codegen after adding files (Step 9). For a single data class, use **`@freezed abstract class`** (Freezed 3+).

Optional request model, `lib/features/product/data/models/get_products_request.dart`:

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

`toJson()` is generated on the Freezed class after running build_runner.

---

## Step 3: Create DataSource

Use `BaseAPI` + `ApiClient` like the auth feature. `lib/features/product/data/datasources/product_remote_datasource.dart`:

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

For paginated APIs, prefer `handlePaginatedApiCall` from `BaseAPI` (see its doc comments).

---

## Step 4: Define Repository Interface

`lib/features/product/domain/repositories/product_repository.dart`:

```dart
import 'package:dartz/dartz.dart';
import 'package:flutter_clean_arch_template/core/errors/failures.dart';
import 'package:flutter_clean_arch_template/features/product/data/models/product_model.dart';

abstract class ProductRepository {
  Future<Either<Failure, List<ProductModel>>> getProducts();
  Future<Either<Failure, ProductModel>> getProduct(String id);
}
```

> The template often reuses **data models** in repository contracts when no extra mapping is required. Introduce a domain **entity** if the API shape and UI needs diverge.

---

## Step 5: Implement Repository

`lib/features/product/data/repositories/product_repository_impl.dart`:

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

## Step 6: Create Provider (Riverpod)

`lib/features/product/presentation/providers/product_list_provider.dart`:

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

For mutable UI state, use `@Riverpod` **class** notifiers (see `auth_provider.dart` in the template).

---

## Step 7: Create Pages and Widgets

`lib/features/product/presentation/pages/product_list_page.dart`:

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
      appBar: AppBar(title: const Text('Products')),
      body: async.when(
        data: (items) => ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, i) => ListTile(
            title: Text(items[i].name),
            subtitle: Text('${items[i].price}'),
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

## Step 8: Register Routes

1. Import the page in `lib/core/router/app_router.dart`.
2. Add an `AutoRoute` entry (path is up to you):

```dart
AutoRoute(
  page: ProductListRoute.page,
  path: '/products',
),
```

3. If the page should live inside the shell, add it under the shell’s `children` instead.

---

## Step 9: Run Code Generation

From the project root:

```bash
just gen
```

This regenerates:

- `product_list_provider.g.dart`
- Freezed/JSON parts for models
- `app_router.gr.dart`
- `service_locator.config.dart` (Injectable)

Then run:

```bash
just dev
```

Fix any analyzer issues, and add tests under `test/` mirroring the feature layout when you stabilize the API contract.
