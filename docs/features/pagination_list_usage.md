# Pagination 组件使用指南

## 概述

项目分页能力由三部分组成：

- `PaginationState<T>`：分页状态模型
- `PaginationList<T>`：普通 `ListView` 场景
- `PaginationSliverView<T>`：`CustomScrollView + Sliver` 场景

当前实现采用**结果驱动**而非状态推断：

- UI 回调必须返回 `PaginationActionResult`
- 组件内部根据结果调用 `finishRefresh` / `finishLoad`
- 刷新成功后由 EasyRefresh 自动 `resetFooter`

这样可以避免 `EasyRefresh` 指示器悬挂。

---

## 核心模型

### PaginationState

位置：`lib/shared/models/pagination_state.dart`

主要字段：

- `items`
- `currentPage`
- `isLoading`
- `isLoadingMore`
- `hasMore`
- `error`
- `total`

扩展：

- `isEmpty`
- `hasError`
- `canLoadMore`

### PaginationActionResult

位置：`lib/shared/models/pagination_action_result.dart`

```dart
enum PaginationActionStatus { success, noMore, fail }

class PaginationActionResult {
  const PaginationActionResult.success();
  const PaginationActionResult.noMore();
  const PaginationActionResult.fail({String? message});
}
```

语义：

- `success`：本次请求成功
- `noMore`：没有更多数据
- `fail`：请求失败

---

## 组件 API

### PaginationList

位置：`lib/shared/widgets/pagination_list/pagination_list.dart`

```dart
PaginationList<T>(
  state: state,
  onRefresh: () => Future<PaginationActionResult>,
  onLoadMore: () => Future<PaginationActionResult>,
  itemBuilder: (context, item, index) => Widget,
  onRetry: ...,
)
```

### PaginationSliverView

位置：`lib/shared/widgets/pagination_list/pagination_sliver_view.dart`

```dart
PaginationSliverView<T>(
  state: state,
  onRefresh: () => Future<PaginationActionResult>,
  onLoadMore: () => Future<PaginationActionResult>,
  slivers: [...],
  scrollController: ...,
)
```

---

## 升级迁移说明（旧版 -> 新版）

如果你之前用的是旧版 `PaginationList`，请注意这 3 处变更：

1. 移除 `controller` 参数  
   组件内部已统一管理 `EasyRefreshController`。
2. `onRefresh` / `onLoadMore` 必须返回 `PaginationActionResult`  
   不再在页面手动调用 `finishRefresh` / `finishLoad`。
3. `itemBuilder` 签名更新为三参数  
   `itemBuilder: (context, item, index) => ...`

---

## Provider 规范

### 1. build 中异步拉首屏

```dart
@override
PaginationState<Item> build() {
  Future.microtask(() => _fetchPage(1));
  return const PaginationState(isLoading: true);
}
```

### 2. 统一返回 PaginationActionResult

```dart
Future<PaginationActionResult> _fetchPage(int page) async {
  final result = await repository.getList(pageNum: page);
  return result.fold(
    (failure) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: failure.message,
      );
      return PaginationActionResult.fail(message: failure.message);
    },
    (data) {
      final newItems = page == 1
          ? data.rows
          : [...state.items, ...data.rows];
      state = state.copyWith(
        items: newItems,
        currentPage: page,
        hasMore: data.hasNext,
        total: data.total,
        isLoading: false,
        isLoadingMore: false,
        error: null,
      );
      return data.hasNext
          ? const PaginationActionResult.success()
          : const PaginationActionResult.noMore();
    },
  );
}

Future<PaginationActionResult> loadMore() async {
  if (!state.canLoadMore) {
    return state.hasMore
        ? const PaginationActionResult.success()
        : const PaginationActionResult.noMore();
  }
  state = state.copyWith(isLoadingMore: true);
  return _fetchPage(state.currentPage + 1);
}

Future<PaginationActionResult> refresh() async {
  state = state.copyWith(isLoading: true, error: null);
  return _fetchPage(1);
}
```

---

## 页面接入示例

### 普通列表

```dart
return PaginationList<ItemModel>(
  state: state,
  onRefresh: () => ref.read(listProvider.notifier).refresh(),
  onLoadMore: () => ref.read(listProvider.notifier).loadMore(),
  onRetry: () => ref.invalidate(listProvider),
  itemBuilder: (context, item, index) => ItemCell(item: item),
);
```

### Sliver 列表

```dart
return PaginationSliverView<ItemModel>(
  state: state,
  scrollController: _scrollController,
  onRefresh: () => ref.read(listProvider.notifier).refresh(),
  onLoadMore: () => ref.read(listProvider.notifier).loadMore(),
  slivers: [
    SliverToBoxAdapter(child: Header()),
    SliverList(...),
  ],
);
```

可参考项目中的完整示例：
`lib/features/_riverpod_demo/presentation/pages/pagination_sliver_demo_page.dart`

---

## 实践建议

1. 不要在页面里手动调用 `finishRefresh/finishLoad`，统一交给组件处理。
2. 不要让 `loadMore` 返回 `void`，必须返回明确的动作结果。
3. `loadMore` 早退时也要返回结果（`success` 或 `noMore`），避免 footer 卡住。
4. 新分页页面优先使用 `PaginationSliverView`，避免复制 `EasyRefresh.builder` 样板代码。
5. 页面空/错/首屏 loading 可在外层根据 `state` 处理，以满足业务视觉需求。
