import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'demo_retry_provider.g.dart';

Duration? _noRetry(int _, Object __) => null;

/// 自定义 retry 策略：最多 3 次，每次间隔 1 秒，仅重试 TimeoutException
///
/// ```dart
/// @Riverpod(keepAlive: true, retry: _customRetry)
/// ```
///
/// 函数签名：`Duration? Function(int retryCount, Object error)`
/// - 返回 Duration → 等待该时长后重试
/// - 返回 null   → 停止重试，进入 AsyncError
Duration? _customRetry(int retryCount, Object error) {
  // 最多重试 3 次
  if (retryCount >= 3) return null;

  // 仅对 TimeoutException 进行重试
  if (error is! TimeoutException) return null;

  return const Duration(seconds: 1);
}

// ─────────────────────────────────────────
// Provider 1: 默认 retry（指数退避）
// ─────────────────────────────────────────

/// 使用默认 retry 策略的 Provider（指数退避，200ms → 400ms → ... → 6400ms）
///
/// Riverpod 3.x 中，build() 抛出 Exception 后框架会自动重试。
/// 重试期间状态为 AsyncLoading（而非 AsyncError），UI 看到的是持续 loading。
@Riverpod(keepAlive: true)
class DemoRetryWithDefault extends _$DemoRetryWithDefault {
  int _retryCount = 0;
  bool _shouldFail = true;

  @override
  FutureOr<String> build() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (_shouldFail) {
      _retryCount++;
      throw Exception('第 $_retryCount 次请求失败');
    }

    _retryCount = 0;
    return '加载成功！';
  }

  int get retryCount => _retryCount;
  bool get shouldFail => _shouldFail;

  void setFail({required bool value}) {
    _shouldFail = value;
    _retryCount = 0;
    ref.invalidateSelf();
  }
}

// ─────────────────────────────────────────
// Provider 2: 禁用 retry
// ─────────────────────────────────────────

/// 禁用 retry 策略的 Provider — 同样的 throw，但直接进入 AsyncError
///
/// 对比上方 Provider，此 Provider throw 后立即展示错误 UI，不会自动重试。
@Riverpod(keepAlive: true, retry: _noRetry)
class DemoRetryDisabled extends _$DemoRetryDisabled {
  bool _shouldFail = true;

  @override
  FutureOr<String> build() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (_shouldFail) {
      throw Exception('请求失败（无重试）');
    }

    return '加载成功！';
  }

  bool get shouldFail => _shouldFail;

  void setFail({required bool value}) {
    _shouldFail = value;
    ref.invalidateSelf();
  }
}

// ─────────────────────────────────────────
// Provider 3: 自定义 retry
// ─────────────────────────────────────────

/// 错误类型枚举，用于演示自定义 retry 仅对特定错误重试
enum DemoErrorType { timeout, auth, generic }

/// 自定义 retry 策略：最多 3 次、间隔 1 秒、仅 TimeoutException 重试
///
/// 用法示例：
/// ```dart
/// Duration? _customRetry(int retryCount, Object error) {
///   if (retryCount >= 3) return null;              // 最多 3 次
///   if (error is! TimeoutException) return null;   // 仅超时错误
///   return const Duration(seconds: 1);             // 固定 1 秒间隔
/// }
///
/// @Riverpod(keepAlive: true, retry: _customRetry)
/// class MyProvider extends _$MyProvider { ... }
/// ```
@Riverpod(keepAlive: true, retry: _customRetry)
class DemoRetryCustom extends _$DemoRetryCustom {
  int _retryCount = 0;
  DemoErrorType _errorType = DemoErrorType.timeout;

  @override
  FutureOr<String> build() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    switch (_errorType) {
      case DemoErrorType.timeout:
        _retryCount++;
        throw TimeoutException('连接超时（第 $_retryCount 次）', const Duration(seconds: 10));
      case DemoErrorType.auth:
        _retryCount++;
        throw Exception('认证失败 (401)');
      case DemoErrorType.generic:
        return '加载成功！（无错误）';
    }
  }

  int get retryCount => _retryCount;
  DemoErrorType get errorType => _errorType;

  void setErrorType(DemoErrorType type) {
    _errorType = type;
    _retryCount = 0;
    ref.invalidateSelf();
  }
}
