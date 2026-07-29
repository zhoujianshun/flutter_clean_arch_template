import 'dart:async';

import 'package:flutter_clean_arch_template/features/_riverpod_demo/presentation/providers/demo_optimistic_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'demo_pessimistic_provider.g.dart';

/// 演示悲观更新（Pessimistic Update）的 Provider
///
/// 与乐观更新相反：先发起异步请求，成功后才更新 UI。
/// 操作期间通过 [pendingIds] 告知 UI 哪些 item 正在处理中。
@riverpod
class DemoPessimistic extends _$DemoPessimistic {
  final Set<String> _pendingIds = {};

  @override
  List<FavoriteItem> build() {
    return List.generate(
      10,
      (i) => FavoriteItem(
        id: 'pess_$i',
        title: '商品 ${i + 1}',
        isFavorited: i % 3 == 0,
      ),
    );
  }

  /// 当前正在执行异步操作的 item ID 集合
  Set<String> get pendingIds => Set.unmodifiable(_pendingIds);

  /// 悲观更新：先等待异步完成，再更新 UI
  ///
  /// [shouldFail] 为 true 时模拟 API 失败
  Future<void> toggleFavorite(String id, {bool shouldFail = false}) async {
    _pendingIds.add(id);
    // 触发 UI 刷新以展示单项 loading
    ref.notifyListeners();

    try {
      await Future<void>.delayed(const Duration(seconds: 1));

      if (shouldFail) {
        throw Exception('收藏操作失败：服务端拒绝');
      }

      // 成功后才更新数据
      state = [
        for (final item in state)
          if (item.id == id)
            item.copyWith(isFavorited: !item.isFavorited)
          else
            item,
      ];
    } finally {
      _pendingIds.remove(id);
      ref.notifyListeners();
    }
  }
}
