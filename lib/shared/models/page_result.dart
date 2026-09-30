import 'package:flutter/foundation.dart';

/// 与传输协议无关的领域分页结果。
@immutable
final class PageResult<T> {
  PageResult({
    required List<T> items,
    required this.total,
    required this.hasNext,
    required this.hasPrevious,
    required this.currentPage,
    required this.pageSize,
  }) : items = List<T>.unmodifiable(items);

  /// 当前页数据。
  final List<T> items;

  /// 全部数据总数。
  final int total;

  /// 是否存在下一页。
  final bool hasNext;

  /// 是否存在上一页。
  final bool hasPrevious;

  /// 当前页码。
  final int currentPage;

  /// 每页数量。
  final int pageSize;
}
