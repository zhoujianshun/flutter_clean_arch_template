import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'demo_form_provider.g.dart';

/// 演示表单提交（Mutation 模式）的 Provider
///
/// 使用 `AsyncValue<String?>` 管理提交状态：
/// - AsyncData(null): 初始/空闲态
/// - AsyncLoading: 提交中
/// - AsyncData('成功消息'): 提交成功
/// - AsyncError: 提交失败
@riverpod
class DemoFormSubmit extends _$DemoFormSubmit {
  @override
  FutureOr<String?> build() {
    return null;
  }

  Future<void> submit({
    required String title,
    required String description,
    bool shouldFail = false,
  }) async {
    state = const AsyncLoading();

    await Future<void>.delayed(const Duration(seconds: 2));

    if (shouldFail) {
      state = AsyncError(
        Exception('提交失败：服务器内部错误 (500)'),
        StackTrace.current,
      );
      return;
    }

    state = AsyncData('「$title」提交成功！');
  }

  void reset() {
    state = const AsyncData(null);
  }
}
