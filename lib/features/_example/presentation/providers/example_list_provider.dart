import 'dart:async';

import 'package:flutter_clean_arch_template/core/di/service_locator.dart';
import 'package:flutter_clean_arch_template/features/_example/domain/entities/example_item.dart';
import 'package:flutter_clean_arch_template/features/_example/domain/repositories/example_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'example_list_provider.g.dart';

@riverpod
class ExampleList extends _$ExampleList {
  late final ExampleRepository _repository = getIt<ExampleRepository>();

  int _currentPage = 1;
  bool _hasMore = true;
  final List<ExampleItem> _items = [];

  @override
  FutureOr<List<ExampleItem>> build() async {
    _currentPage = 1;
    _items.clear();
    _hasMore = true;
    return _loadPage(1);
  }

  Future<List<ExampleItem>> _loadPage(int page) async {
    final result = await _repository.getList(pageNum: page);

    return result.fold(
      (failure) => throw failure,
      (data) {
        _hasMore = _items.length + data.rows.length < data.total;
        _items.addAll(data.rows);
        return List.unmodifiable(_items);
      },
    );
  }

  Future<void> loadMore() async {
    if (!_hasMore) return;
    _currentPage++;
    state = AsyncValue.data(await _loadPage(_currentPage));
  }

  Future<void> refresh() async {
    _currentPage = 1;
    _items.clear();
    _hasMore = true;
    state = AsyncValue.data(await _loadPage(1));
  }

  bool get hasMore => _hasMore;
}
