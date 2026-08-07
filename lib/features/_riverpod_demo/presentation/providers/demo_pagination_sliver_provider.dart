import 'dart:async';

import 'package:flutter_clean_arch_template/shared/models/pagination_action_result.dart';
import 'package:flutter_clean_arch_template/shared/models/pagination_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'demo_pagination_sliver_provider.g.dart';

/// 演示 PaginationSliverView 的分页 Provider
///
/// 模拟每页 12 条、共 48 条数据，并返回 [PaginationActionResult]
/// 以便组件内部正确结束 refresh/load 指示器。
@riverpod
class DemoPaginationSliver extends _$DemoPaginationSliver {
  static const _pageSize = 12;
  static const _totalItems = 48;

  @override
  PaginationState<String> build() {
    unawaited(Future(fetchFirstPage));
    return const PaginationState<String>(isLoading: true);
  }

  Future<PaginationActionResult> fetchFirstPage() async {
    state = state.copyWith(
      isLoading: true,
      isLoadingMore: false,
      error: null,
    );
    return _loadPage(1, isRefresh: false);
  }

  Future<PaginationActionResult> refresh() async {
    state = state.copyWith(
      isLoading: true,
      isLoadingMore: false,
      error: null,
    );
    return _loadPage(1, isRefresh: true);
  }

  Future<PaginationActionResult> loadMore() async {
    if (state.isLoading || state.isLoadingMore) {
      return const PaginationActionResult.success();
    }
    if (!state.hasMore) {
      return const PaginationActionResult.noMore();
    }

    state = state.copyWith(isLoadingMore: true, error: null);
    return _loadPage(state.currentPage + 1, isRefresh: false);
  }

  Future<PaginationActionResult> _loadPage(
    int page, {
    required bool isRefresh,
  }) async {
    try {
      await Future<void>.delayed(const Duration(milliseconds: 900));

      final pageItems = _generateItems(page);
      final allItems = page == 1 ? pageItems : [...state.items, ...pageItems];
      final hasMore = allItems.length < _totalItems;

      state = state.copyWith(
        items: allItems,
        currentPage: page,
        isLoading: false,
        isLoadingMore: false,
        hasMore: hasMore,
        total: _totalItems,
        error: null,
        refreshTimestamp: isRefresh
            ? DateTime.now().millisecondsSinceEpoch
            : state.refreshTimestamp,
      );

      return hasMore
          ? const PaginationActionResult.success()
          : const PaginationActionResult.noMore();
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: error.toString(),
      );
      return PaginationActionResult.fail(message: error.toString());
    }
  }

  List<String> _generateItems(int page) {
    final start = (page - 1) * _pageSize;
    final end = start + _pageSize;
    final actualEnd = end > _totalItems ? _totalItems : end;

    return List.generate(actualEnd - start, (i) {
      final globalIndex = start + i + 1;
      final section = ((globalIndex - 1) ~/ 6) + 1;
      return '分组 $section · 第 $globalIndex 条数据（页码 $page）';
    });
  }
}
