import 'dart:async';

import 'package:flutter_clean_arch_template/shared/models/pagination_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
// ignore_for_file: avoid_redundant_argument_values

part 'demo_pagination_provider.g.dart';

/// 演示 PaginationList 分页加载的 Provider
///
/// 模拟每页 15 条、共 50 条数据的分页场景。
@riverpod
class DemoPagination extends _$DemoPagination {
  static const _pageSize = 15;
  static const _totalItems = 50;

  @override
  PaginationState<String> build() {
    // 初始化时自动加载第一页
    unawaited(Future(fetchFirstPage));
    return const PaginationState<String>(isLoading: true);
  }

  Future<void> fetchFirstPage() async {
    state = state.copyWith(isLoading: true, error: null);

    await Future<void>.delayed(const Duration(milliseconds: 1200));

    final items = _generateItems(1);
    state = state.copyWith(
      items: items,
      currentPage: 1,
      isLoading: false,
      hasMore: items.length < _totalItems,
      total: _totalItems,
    );
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);

    await Future<void>.delayed(const Duration(milliseconds: 1000));

    final items = _generateItems(1);
    state = PaginationState<String>(
      items: items,
      currentPage: 1,
      hasMore: items.length < _totalItems,
      total: _totalItems,
      refreshTimestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;

    state = state.copyWith(isLoadingMore: true);

    await Future<void>.delayed(const Duration(milliseconds: 1000));

    final nextPage = state.currentPage + 1;
    final newItems = _generateItems(nextPage);
    final allItems = [...state.items, ...newItems];

    state = state.copyWith(
      items: allItems,
      currentPage: nextPage,
      isLoadingMore: false,
      hasMore: allItems.length < _totalItems,
    );
  }

  List<String> _generateItems(int page) {
    final start = (page - 1) * _pageSize;
    final end = start + _pageSize;
    final actualEnd = end > _totalItems ? _totalItems : end;
    return List.generate(
      actualEnd - start,
      (i) => '第 ${start + i + 1} 条数据 — 页码 $page',
    );
  }
}
