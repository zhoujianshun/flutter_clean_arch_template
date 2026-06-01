# PaginationList + PaginationState 分页组件使用指南

## 概述

`PaginationList` 和 `PaginationState` 是项目中通用的分页列表解决方案，基于 `easy_refresh` 实现下拉刷新和上拉加载更多功能，配合 Riverpod Provider 管理分页状态。

## 核心组件

### PaginationState（分页状态模型）

位置：`lib/shared/models/pagination_state.dart`

```dart
@Freezed(genericArgumentFactories: true)
abstract class PaginationState<T> with _$PaginationState<T> {
  const factory PaginationState({
    @Default([]) List<T> items,           // 数据列表
    @Default(1) int currentPage,          // 当前页码
    @Default(false) bool isLoading,       // 是否正在加载（首次/刷新）
    @Default(false) bool isLoadingMore,   // 是否正在加载更多
    @Default(true) bool hasMore,          // 是否有更多数据
    String? error,                        // 错误信息
    @Default(0) int total,                // 总数量
    @Default(0) int refreshTimestamp,     // 刷新状态标记
  }) = _PaginationState<T>;
}
```

**扩展方法：**

| 属性 | 说明 |
|------|------|
| `isEmpty` | 是否为空状态（无数据、未加载中、无错误） |
| `hasError` | 是否为错误状态 |
| `canLoadMore` | 是否可以加载更多（有更多数据 & 未在加载中） |

### PaginationList（分页列表 Widget）

位置：`lib/shared/widgets/pagination_list/pagination_list.dart`

```dart
PaginationList<T>({
  required PaginationState<T> state,       // 分页状态
  required FutureOr Function()? onRefresh, // 下拉刷新回调
  required FutureOr Function()? onLoadMore,// 上拉加载更多回调
  required Widget Function(BuildContext, T) itemBuilder, // 列表项构建器
  required VoidCallback onRetry,           // 错误重试回调
  EasyRefreshController? controller,       // 刷新控制器（可选）
  EdgeInsets? padding,                     // 列表内边距
  WidgetBuilder? emptyBuilder,             // 自定义空状态
  Widget Function(...)? errorBuilder,      // 自定义错误状态
})
```

**内置状态处理：**
- 加载中（首次）→ 显示 `AppLoadingIndicator`
- 错误（无数据时）→ 显示 `AppErrorWidget`
- 空数据 → 显示 `AppEmptyWidget`
- 有数据 → 显示 `ListView.separated` + 下拉刷新/上拉加载

---

## 使用步骤

### Step 1：定义 Provider

在 Provider 中管理 `PaginationState`，提供 `refresh()` 和 `loadMore()` 方法。

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sky_harbor_service_app/core/di/service_locator.dart';
import 'package:sky_harbor_service_app/core/logger/app_logger.dart';
import 'package:sky_harbor_service_app/shared/models/pagination_state.dart';

part 'xxx_list_provider.g.dart';

@riverpod
class XxxList extends _$XxxList {
  late XxxRepository _repository;

  @override
  PaginationState<XxxItemModel> build() {
    _repository = getIt<XxxRepository>();

    // 初始化后异步加载首页数据
    Future.microtask(() => _loadData(isRefresh: true));
    return const PaginationState<XxxItemModel>();
  }

  /// 加载数据（内部方法）
  Future<void> _loadData({bool isRefresh = false, int? page}) async {
    final currentState = state;
    final targetPage = page ?? (isRefresh ? 1 : currentState.currentPage + 1);

    // 设置加载状态
    if (isRefresh) {
      state = currentState.copyWith(isLoading: true, error: null);
    } else {
      state = currentState.copyWith(isLoadingMore: true, error: null);
    }

    final request = GetXxxListRequest(pageNum: targetPage);
    final response = await _repository.getXxxList(request);

    response.fold(
      (failure) {
        state = currentState.copyWith(
          isLoading: false,
          isLoadingMore: false,
          error: failure.message,
        );
      },
      (result) {
        var newItems = result.rows;
        if (!isRefresh) {
          newItems = [...currentState.items, ...result.rows];
        }

        state = currentState.copyWith(
          items: newItems,
          currentPage: targetPage,
          hasMore: result.hasNext,
          isLoading: false,
          isLoadingMore: false,
          total: result.total,
          error: null,
        );
      },
    );
  }

  /// 刷新数据
  Future<void> refresh() async {
    await _loadData(isRefresh: true);
  }

  /// 加载更多数据
  Future<void> loadMore() async {
    if (state.canLoadMore) {
      await _loadData();
    }
  }
}
```

### Step 2：在 Widget 中使用 PaginationList

#### 方式一：简单用法（ConsumerWidget）

适用于不需要手动控制 `EasyRefreshController` 的场景。

```dart
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sky_harbor_service_app/shared/widgets/pagination_list/pagination_list.dart';
import 'package:sky_harbor_service_app/shared/widgets/states/app_empty_widget.dart';

class XxxListWidget extends ConsumerWidget {
  const XxxListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(xxxListProvider);

    return PaginationList<XxxItemModel>(
      state: state,
      onRefresh: () async {
        await ref.read(xxxListProvider.notifier).refresh();
      },
      onLoadMore: () async {
        await ref.read(xxxListProvider.notifier).loadMore();
        final newState = ref.read(xxxListProvider);
        if (!newState.hasMore) {
          return IndicatorResult.noMore;
        } else if (newState.hasError) {
          return IndicatorResult.fail;
        } else {
          return IndicatorResult.success;
        }
      },
      itemBuilder: (context, item) => XxxListItem(item: item),
      onRetry: () {
        ref.invalidate(xxxListProvider);
      },
      emptyBuilder: (context) => const AppEmptyWidget(inScrollView: true),
    );
  }
}
```

#### 方式二：带 Controller 的用法（ConsumerStatefulWidget）

适用于需要外部触发刷新（如 TabView 切换、WebSocket 推送等）场景。

```dart
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sky_harbor_service_app/shared/widgets/pagination_list/pagination_list.dart';

class XxxListWidget extends ConsumerStatefulWidget {
  const XxxListWidget({super.key});

  @override
  ConsumerState<XxxListWidget> createState() => _XxxListWidgetState();
}

class _XxxListWidgetState extends ConsumerState<XxxListWidget> {
  final refreshController = EasyRefreshController(
    controlFinishRefresh: true,
    controlFinishLoad: true,
  );

  @override
  void dispose() {
    refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 监听 refreshTimestamp 变化，自动完成刷新控制器状态
    ref.listen(xxxListProvider, (previous, next) {
      if (previous != null &&
          previous.refreshTimestamp != next.refreshTimestamp &&
          next.refreshTimestamp > previous.refreshTimestamp) {
        refreshController
          ..finishRefresh()
          ..resetFooter();
      }
    });

    final paginationState = ref.watch(xxxListProvider);

    return PaginationList<XxxItemModel>(
      state: paginationState,
      controller: refreshController,
      onRefresh: () async {
        await ref.read(xxxListProvider.notifier).refresh();
      },
      onLoadMore: () async {
        await ref.read(xxxListProvider.notifier).loadMore();
        final newState = ref.read(xxxListProvider);
        if (!newState.hasMore) {
          refreshController.finishLoad(IndicatorResult.noMore);
        } else if (newState.hasError) {
          refreshController.finishLoad(IndicatorResult.fail);
        } else {
          refreshController.finishLoad();
        }
      },
      itemBuilder: (context, item) => XxxListItem(item: item),
      onRetry: () {
        ref.invalidate(xxxListProvider);
      },
    );
  }
}
```

### Step 3：带参数的 Provider（Family）

当列表需要根据不同参数加载数据时，使用带参数的 Provider。

```dart
// Provider 定义
@riverpod
class OrderList extends _$OrderList {
  late ServiceOrderRepository _repository;

  @override
  PaginationState<ServiceOrderItemModel> build(ServiceOrderStatus orderStatus) {
    _repository = getIt<ServiceOrderRepository>();
    Future.microtask(() => _loadData(isRefresh: true));
    return const PaginationState<ServiceOrderItemModel>();
  }

  Future<void> _loadData({bool isRefresh = false}) async {
    // ...使用 arg (orderStatus) 作为请求参数
    final request = GetServiceOrderListRequest(
      pageNum: targetPage,
      status: arg, // build 参数自动作为 arg 可用
    );
    // ...
  }
}

// Widget 中使用
final state = ref.watch(orderListProvider(ServiceOrderStatus.pending));
ref.read(orderListProvider(ServiceOrderStatus.pending).notifier).refresh();
```

---

## 关键设计说明

### onLoadMore 返回值

`onLoadMore` 回调返回 `IndicatorResult` 用于告知 `EasyRefresh` 加载状态：

| 返回值 | 含义 |
|--------|------|
| `IndicatorResult.success` / `null` | 加载成功，可继续加载 |
| `IndicatorResult.noMore` | 没有更多数据，显示"没有更多了" |
| `IndicatorResult.fail` | 加载失败，允许重试 |

### refreshTimestamp 的作用

在使用外部 `EasyRefreshController` 时，Provider 通过更新 `refreshTimestamp` 通知 UI 刷新完成。Widget 中通过 `ref.listen` 监听该值变化，自动调用 `controller.finishRefresh()`。

Provider 侧更新方式：

```dart
state = state.copyWith(
  // ...其他字段
  refreshTimestamp: DateTime.now().millisecondsSinceEpoch,
);
```

### 错误重试（onRetry）

推荐使用 `ref.invalidate(provider)` 实现错误重试，它会销毁并重建 Provider，触发 `build()` 重新执行初始加载逻辑。

---

## 自定义空状态和错误状态

```dart
PaginationList<XxxItemModel>(
  // ...
  emptyBuilder: (context) => const AppEmptyWidget(
    type: AppEmptyWidgetType.orderList, // 选择对应的空状态类型
    inScrollView: true,                 // 嵌套在可滚动视图中时设为 true
  ),
  errorBuilder: (context, {String? error, required VoidCallback onRetry}) {
    return MyCustomErrorWidget(error: error, onRetry: onRetry);
  },
)
```

---

## 完整流程图

```
┌─────────────────────────────────────────────────────────┐
│                    PaginationList Widget                  │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  state.isLoading && items.isEmpty → AppLoadingIndicator  │
│  state.hasError && items.isEmpty  → AppErrorWidget       │
│  state.isEmpty                    → AppEmptyWidget       │
│  else                             → EasyRefresh          │
│                                     ├─ onRefresh → Provider.refresh()   │
│                                     └─ onLoad   → Provider.loadMore()   │
│                                                          │
└─────────────────────────────────────────────────────────┘
                          ↕ state
┌─────────────────────────────────────────────────────────┐
│                    Provider (Notifier)                    │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  build() → 初始 PaginationState + microtask 加载首页     │
│                                                          │
│  refresh()  → _loadData(isRefresh: true)                 │
│  loadMore() → _loadData(isRefresh: false)                │
│                                                          │
│  _loadData():                                            │
│    1. 更新 isLoading / isLoadingMore                     │
│    2. 调用 Repository.getList(request)                   │
│    3. fold 处理结果：                                     │
│       - Left  → 设置 error                               │
│       - Right → 合并 items + 更新 currentPage/hasMore    │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

---

## 注意事项

1. **初始加载**：Provider 的 `build()` 中使用 `Future.microtask()` 异步加载首页数据，避免在同步方法中直接 `await`。
2. **数据合并**：`loadMore` 时将新数据追加到已有数据后面；`refresh` 时直接替换为新数据。
3. **防重复请求**：通过 `state.canLoadMore`（`hasMore && !isLoading && !isLoadingMore`）防止重复触发加载。
4. **泛型支持**：`PaginationState<T>` 和 `PaginationList<T>` 都是泛型的，可用于任意数据模型。
5. **列表间距**：默认 padding 为 `EdgeInsets.all(12.w)`，item 间距为 `SizedBox(height: 8.w)`，可通过 `padding` 参数自定义。
