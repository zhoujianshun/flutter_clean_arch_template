import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'demo_optimistic_provider.g.dart';

/// 收藏项数据模型
class FavoriteItem {
  const FavoriteItem({
    required this.id,
    required this.title,
    this.isFavorited = false,
  });

  final String id;
  final String title;
  final bool isFavorited;

  FavoriteItem copyWith({bool? isFavorited}) => FavoriteItem(
        id: id,
        title: title,
        isFavorited: isFavorited ?? this.isFavorited,
      );
}

/// 演示乐观更新（Optimistic Update）的 Provider
///
/// 点击收藏时立即更新 UI，异步操作失败后自动回滚。
@riverpod
class DemoOptimistic extends _$DemoOptimistic {
  @override
  List<FavoriteItem> build() {
    return List.generate(
      10,
      (i) => FavoriteItem(
        id: 'item_$i',
        title: '商品 ${i + 1}',
        isFavorited: i % 3 == 0,
      ),
    );
  }

  /// [shouldFail] 为 true 时模拟 API 失败，触发回滚
  Future<void> toggleFavorite(String id, {bool shouldFail = false}) async {
    final oldState = state;

    // 乐观更新：立即翻转收藏状态
    state = [
      for (final item in state)
        if (item.id == id)
          item.copyWith(isFavorited: !item.isFavorited)
        else
          item,
    ];

    await Future<void>.delayed(const Duration(seconds: 1));

    if (shouldFail) {
      // 回滚到旧状态
      state = oldState;
      throw Exception('收藏操作失败：网络超时');
    }
  }
}
