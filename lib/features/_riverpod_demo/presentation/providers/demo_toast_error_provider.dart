import 'dart:async';
import 'dart:math';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'demo_toast_error_provider.g.dart';

/// 演示 ref.listen + Toast 错误提示的 Provider
///
/// 刷新失败时保留旧数据，通过 AsyncError 通知 UI 弹 Toast，
/// 随后恢复到 AsyncData（旧数据）。
@riverpod
class DemoToastError extends _$DemoToastError {
  @override
  FutureOr<List<String>> build() {
    return List.generate(8, (i) => '初始数据 ${i + 1}');
  }

  Future<void> refresh({bool shouldFail = false}) async {
    final previousData = state.value ?? [];

    // 手动设置为 loading 态（Riverpod 会自动合并旧数据）
    state = const AsyncLoading<List<String>>();

    await Future<void>.delayed(const Duration(seconds: 2));

    if (shouldFail) {
      state = AsyncError<List<String>>(
        Exception('刷新失败：请检查网络连接'),
        StackTrace.current,
      );
      // 短暂延迟后恢复旧数据，让 ref.listen 有时间捕获 error
      await Future<void>.delayed(const Duration(milliseconds: 100));
      state = AsyncData(previousData);
      return;
    }

    final random = Random();
    state = AsyncData(
      List.generate(8, (i) => '刷新数据 ${i + 1} — ${random.nextInt(1000)}'),
    );
  }
}
