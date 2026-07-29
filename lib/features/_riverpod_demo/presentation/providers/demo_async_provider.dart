import 'dart:async';
import 'dart:math';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'demo_async_provider.g.dart';

/// 禁用自动重试：返回 null 表示不重试
Duration? _noRetry(int _, Object __) => null;

/// 演示 AsyncValue.when 三态切换的 Provider
///
/// - `keepAlive: true`：invalidate 后保留 notifier 实例，_shouldFail 不被重置
/// - `retry: _noRetry`：禁用 Riverpod 3.x 默认的指数退避重试，
///   否则 throw Exception 后框架会自动重试最多 10 次，无法展示 error 态
@Riverpod(keepAlive: true, retry: _noRetry)
class DemoAsync extends _$DemoAsync {
  bool _shouldFail = false;

  @override
  FutureOr<List<String>> build() async {
    await Future<void>.delayed(const Duration(seconds: 2));

    if (_shouldFail) {
      throw Exception('模拟网络错误：服务器无响应 (code: -1001)');
    }

    final random = Random();
    return List.generate(
      10,
      (i) => '项目 ${i + 1} — 随机值 ${random.nextInt(1000)}',
    );
  }

  bool get shouldFail => _shouldFail;

  void toggleFailMode({required bool value}) {
    _shouldFail = value;
  }
}
