import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'demo_filter_provider.g.dart';

/// 当前选中的筛选分类
@riverpod
class FilterCategory extends _$FilterCategory {
  @override
  String? build() => null;

  void select(String? category) {
    state = category;
  }
}

/// 演示多 Provider 联动（筛选 + 列表）
///
/// build() 内 ref.watch(filterCategoryProvider) 获取筛选条件，
/// 切换筛选时列表自动重新加载。
@riverpod
class DemoFilterList extends _$DemoFilterList {
  static const _allItems = [
    ('手机', '电子产品'),
    ('笔记本电脑', '电子产品'),
    ('耳机', '电子产品'),
    ('平板电视', '电子产品'),
    ('运动鞋', '运动户外'),
    ('瑜伽垫', '运动户外'),
    ('登山包', '运动户外'),
    ('跑步机', '运动户外'),
    ('连衣裙', '服饰箱包'),
    ('牛仔裤', '服饰箱包'),
    ('双肩包', '服饰箱包'),
    ('太阳镜', '服饰箱包'),
    ('咖啡豆', '食品饮料'),
    ('绿茶', '食品饮料'),
    ('巧克力', '食品饮料'),
  ];

  static const categories = ['电子产品', '运动户外', '服饰箱包', '食品饮料'];

  @override
  FutureOr<List<({String name, String category})>> build() async {
    final filter = ref.watch(filterCategoryProvider);

    await Future<void>.delayed(const Duration(milliseconds: 800));

    final items = _allItems
        .where((e) => filter == null || e.$2 == filter)
        .map((e) => (name: e.$1, category: e.$2))
        .toList();

    return items;
  }
}
