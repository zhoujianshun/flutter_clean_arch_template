// ignore_for_file: avoid_redundant_argument_values // 测试显式写默认值便于阅读

import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_clean_arch_template/core/network/interceptors/retry_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';

/// 固定 jitter 的随机源（nextInt 返回 max ~/ 3），使退避断言确定性
class FixedRandom implements Random {
  @override
  int nextInt(int max) => max ~/ 3;

  @override
  bool nextBool() => true;

  @override
  double nextDouble() => 0.5;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('重试判定与次数（走真实 Dio 拦截链）', () {
    test('GET 超时重试至成功，计数正确', () async {
      final dio = Dio();
      final adapter = _ScriptedAdapter([
        _AsyncResult<DioException Function(RequestOptions)>(
          (options) => DioException(
            requestOptions: options,
            type: DioExceptionType.connectionTimeout,
          ),
        ),
      ]);
      dio.httpClientAdapter = adapter;
      dio.interceptors.add(_InjectDioInterceptor(dio));
      dio.interceptors.add(
        RetryInterceptor(
          maxRetries: 3,
          retryDelay: const Duration(milliseconds: 1),
          random: FixedRandom(),
        ),
      );

      final resp = await dio.get<String>('/test');

      expect(resp.statusCode, 200);
      expect(adapter.callCount, 2, reason: '首发失败 + 1 次重试成功');
    });

    test('达到 maxRetries 后放弃，错误沿链传播', () async {
      final dio = Dio();
      final adapter = _ScriptedAdapter.failForever(
        DioExceptionType.connectionTimeout,
      );
      dio.httpClientAdapter = adapter;
      dio.interceptors.add(_InjectDioInterceptor(dio));
      dio.interceptors.add(
        RetryInterceptor(
          maxRetries: 2,
          retryDelay: const Duration(milliseconds: 1),
          random: FixedRandom(),
        ),
      );

      await expectLater(
        dio.get<String>('/test'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.callCount, 3, reason: '首发 + 2 次重试');
    });

    test('POST（非幂等）失败不重试', () async {
      final dio = Dio();
      final adapter = _ScriptedAdapter.failForever(
        DioExceptionType.connectionTimeout,
      );
      dio.httpClientAdapter = adapter;
      dio.interceptors.add(_InjectDioInterceptor(dio));
      dio.interceptors.add(
        RetryInterceptor(
          maxRetries: 3,
          retryDelay: const Duration(milliseconds: 1),
          random: FixedRandom(),
        ),
      );

      await expectLater(
        dio.post<String>('/test'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.callCount, 1, reason: 'POST 未标记 retryable 不应重试');
    });

    test('重试请求的 401 仍能经过拦截链（错误传播不递归吞掉）', () async {
      final dio = Dio();
      // 首发：超时（可重试）；重试：401（应沿链传播，而非被 retry 递归消化）
      final adapter = _ScriptedAdapter([
        _AsyncResult<DioException Function(RequestOptions)>(
          (options) => DioException(
            requestOptions: options,
            type: DioExceptionType.connectionTimeout,
          ),
        ),
        _AsyncResult<int>(401),
      ]);
      dio.httpClientAdapter = adapter;
      dio.interceptors.add(_InjectDioInterceptor(dio));

      var authErrorSeen = false;
      dio.interceptors.add(_Auth401Sniffer(() => authErrorSeen = true));
      dio.interceptors.add(
        RetryInterceptor(
          maxRetries: 3,
          retryDelay: const Duration(milliseconds: 1),
          random: FixedRandom(),
        ),
      );

      // 401 在 retryableStatusCodes 之外（401 不可重试），重试一次后：
      // fetch 返回 401 → Dio 抛 badResponse → handler.next 沿链传播
      // → Auth401Sniffer 在 Retry 之前的 onError 中看到它
      await expectLater(dio.get<String>('/test'), throwsA(isA<DioException>()));

      expect(authErrorSeen, isTrue, reason: '重试产生的 401 必须沿链传播给上游认证拦截器');
      expect(adapter.callCount, 2, reason: '401 不可重试，只重试了超时那一次');
    });
  });

  group('退避延迟计算', () {
    test('指数退避 + 固定 jitter', () {
      final i = RetryInterceptor(
        retryDelay: const Duration(seconds: 1),
        random: FixedRandom(),
      );

      // attempt 0: 1000 * 1 + 100；attempt 1: 1000 * 2 + 100；attempt 2: 1000 * 4 + 100
      expect(i.calculateDelayForTest(0), const Duration(milliseconds: 1100));
      expect(i.calculateDelayForTest(1), const Duration(milliseconds: 2100));
      expect(i.calculateDelayForTest(2), const Duration(milliseconds: 4100));
    });
  });
}

/// 把 dio 实例注入 extra，模拟 ApiClient 的预处理拦截器
class _InjectDioInterceptor extends Interceptor {
  _InjectDioInterceptor(this._dio);
  final Dio _dio;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[RetryInterceptor.kDioInstanceKey] = _dio;
    handler.next(options);
  }
}

/// 认证 401 探针：模拟 AuthInterceptor 在 Retry 之前的 onError 行为
class _Auth401Sniffer extends Interceptor {
  _Auth401Sniffer(this.onSeen);
  final void Function() onSeen;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      onSeen();
    }
    handler.next(err);
  }
}

/// 脚本化 Adapter：按队列返回预设结果
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this._script);
  _ScriptedAdapter.failForever(DioExceptionType type)
    : _script = List.generate(
        20,
        (_) => _AsyncResult<DioException Function(RequestOptions)>(
          (options) => DioException(requestOptions: options, type: type),
        ),
      );

  final List<Object> _script;
  int callCount = 0;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    callCount++;
    if (_script.isEmpty) {
      // 默认成功
      return ResponseBody.fromString(
        '{"ok":true}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    final item = _script.removeAt(0);
    if (item is _AsyncResult<DioException Function(RequestOptions)>) {
      // 用真实 options 构造异常，保留 extra（dio_instance 等）
      throw item.value(options);
    }
    if (item is _AsyncResult<int>) {
      // 直接以指定 HTTP 状态码响应，Dio 转 badResponse
      return ResponseBody.fromString('', item.value);
    }
    return ResponseBody.fromString('{"ok":true}', 200);
  }
}

class _AsyncResult<T> {
  _AsyncResult(this.value);
  final T value;
}
