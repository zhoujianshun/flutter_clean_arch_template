// ignore_for_file: avoid_redundant_argument_values // 测试显式写默认值便于阅读

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_clean_arch_template/core/di/service_locator.dart';
import 'package:flutter_clean_arch_template/core/env/env_config_manager.dart';
import 'package:flutter_clean_arch_template/core/network/auth_config.dart';import 'package:flutter_clean_arch_template/core/network/errors/network_error.dart';
import 'package:flutter_clean_arch_template/core/network/errors/network_error_notifier.dart';
import 'package:flutter_clean_arch_template/core/network/interceptors/auth_interceptor.dart';
import 'package:flutter_clean_arch_template/core/network/interceptors/retry_interceptor.dart';
import 'package:flutter_clean_arch_template/core/network/token/token_manager.dart';
import 'package:flutter_clean_arch_template/core/network/token/token_strategy.dart';
import 'package:flutter_test/flutter_test.dart';

/// 可编程的假策略：token 存内存，refreshToken() 按脚本返回，
/// refreshCallCount 用于断言「401 兜底只刷一次」。
/// 行为对齐真实 DualTokenStrategy：刷新成功写回 token；
/// refresh token 缺失时刷新失败返回 null。
class _FakeDualStrategy implements TokenStrategy {
  _FakeDualStrategy({
    String initialToken = 'token-old',
    String initialRefreshToken = 'refresh-old',
    String? refreshResult,
    Duration refreshDelay = const Duration(milliseconds: 10),
  }) : _token = initialToken,
       _refreshToken = initialRefreshToken,
       _refreshResult = refreshResult,
       _refreshDelay = refreshDelay;

  String _token;
  String? _refreshToken;
  final String? _refreshResult;
  final Duration _refreshDelay;

  int refreshCallCount = 0;

  @override
  String get name => 'FakeDual';

  @override
  bool get supportsRefresh => true;

  @override
  Future<String?> getAccessToken() async => _token;

  @override
  Future<void> saveAccessToken({
    required String accessToken,
    String? refreshToken,
  }) async {
    _token = accessToken;
    if (refreshToken != null) _refreshToken = refreshToken;
  }

  @override
  Future<void> clearToken() async {
    _token = '';
    _refreshToken = null;
  }

  @override
  Future<bool> isTokenExpired() async => false;

  @override
  bool shouldRefresh() => false;

  @override
  Future<String?> refreshToken() async {
    refreshCallCount++;
    await Future<void>.delayed(_refreshDelay);
    // 对齐真实策略：refresh token 不存在 → 刷新失败
    final refreshToken = _refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }
    final result = _refreshResult;
    if (result != null) {
      // 对齐真实策略：成功结果写回存储
      await saveAccessToken(accessToken: result);
    }
    return result;
  }
}

/// 不支持刷新的策略（单 Token 语义）
class _FakeSingleStrategy extends _FakeDualStrategy {
  _FakeSingleStrategy() : super(initialToken: 'single-token');

  @override
  bool get supportsRefresh => false;

  @override
  Future<String?> refreshToken() async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // onRequest 无条件读取 AppConfig.clientId → EnvConfigManager，
    // 走其测试入口注入配置（内部委托 flutter_dotenv 官方 API）
    EnvConfigManager.loadFromString('CLIENT_ID=test-client-id');
  });

  late NetworkErrorNotifier errorNotifier;
  late List<NetworkError> notifiedErrors;

  setUp(() async {
    await getIt.reset();
    final errors = <NetworkError>[];
    notifiedErrors = errors;
    errorNotifier = NetworkErrorNotifier()..stream.listen(errors.add);
    getIt
      ..registerSingleton<NetworkErrorNotifier>(errorNotifier)
      ..registerSingleton<AuthConfig>(
        const AuthConfig(publicPaths: ['/auth/login']),
      );
  });

  tearDown(() async {
    await getIt.reset();
    errorNotifier.dispose();
  });

  Dio buildDio(_ScriptedAdapter adapter, TokenManager tokenManager) {
    final dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
    dio
      ..httpClientAdapter = adapter
      // 模拟 ApiClient 的预处理拦截器：注入 Dio 实例引用
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            options.extra[RetryInterceptor.kDioInstanceKey] = dio;
            handler.next(options);
          },
        ),
      );
    getIt.registerSingleton<TokenManager>(tokenManager);
    dio.interceptors.add(AuthInterceptor());
    return dio;
  }

  group('业务层 401（onResponse）刷新重放', () {
    test('刷新成功 → 重放成功：拿到新数据，无登出通知', () async {
      final strategy = _FakeDualStrategy(refreshResult: 'token-new');
      final manager = TokenManager(strategy: strategy);

      // 首发：业务 401（HTTP 200 + code=401）；重放：成功
      final adapter = _ScriptedAdapter([
        _Scenario.business401('登录已过期'),
        _Scenario.success({'code': 200, 'data': 'fresh-data'}),
      ]);
      final dio = buildDio(adapter, manager);

      final resp = await dio.get<dynamic>('/business/data');
      final body = resp.data as Map<String, dynamic>;

      expect(body['data'], 'fresh-data');
      expect(strategy.refreshCallCount, 1, reason: '401 兜底只刷一次');
      expect(adapter.callCount, 2, reason: '首发 + 1 次重放');
      expect(notifiedErrors, isEmpty, reason: '恢复成功不应登出');
    });

    test('刷新失败 → 维持原响应，无登出通知（临时失败不登出）', () async {
      final strategy = _FakeDualStrategy(refreshResult: null);
      final manager = TokenManager(strategy: strategy);

      final adapter = _ScriptedAdapter([_Scenario.business401('登录已过期')]);
      final dio = buildDio(adapter, manager);

      final resp = await dio.get<dynamic>('/business/data');

      expect((resp.data as Map<String, dynamic>)['code'], 401);
      expect(adapter.callCount, 1, reason: '刷新失败不重放');
      expect(
        notifiedErrors,
        isEmpty,
        reason: '刷新临时失败（返回 null）不触发登出',
      );
    });

    test('重放后仍业务 401 → 通知登出（终态）', () async {
      final strategy = _FakeDualStrategy(refreshResult: 'token-new');
      final manager = TokenManager(strategy: strategy);

      // 首发 401 → 刷新成功 → 重放仍 401（新 token 也被拒）
      final adapter = _ScriptedAdapter([
        _Scenario.business401('登录已过期'),
        _Scenario.business401('仍无效'),
      ]);
      final dio = buildDio(adapter, manager);

      final resp = await dio.get<dynamic>('/business/data');

      expect((resp.data as Map<String, dynamic>)['code'], 401);
      expect(adapter.callCount, 2);
      final authErrors = notifiedErrors.whereType<NetworkAuthError>().toList();
      expect(authErrors, hasLength(1), reason: '重放后仍 401 必须通知终态登出');
      expect(
        authErrors.single.runtimeType,
        AuthenticationFailedError,
        reason: '终态通知类型为 authenticationFailed',
      );
    });
  });

  group('HTTP 401（onError）刷新重放', () {
    test('刷新成功 → 重放成功：请求恢复正常', () async {
      final strategy = _FakeDualStrategy(refreshResult: 'token-new');
      final manager = TokenManager(strategy: strategy);

      final adapter = _ScriptedAdapter([
        _Scenario.http401(),
        _Scenario.success({'code': 200, 'data': 'fresh-data'}),
      ]);
      final dio = buildDio(adapter, manager);

      final resp = await dio.get<dynamic>('/business/data');
      final body = resp.data as Map<String, dynamic>;

      expect(body['data'], 'fresh-data');
      expect(strategy.refreshCallCount, 1);
      expect(adapter.callCount, 2);
      expect(notifiedErrors, isEmpty);
    });

    test('刷新失败 → 原错误沿链传播，无登出通知', () async {
      final strategy = _FakeDualStrategy(refreshResult: null);
      final manager = TokenManager(strategy: strategy);

      final adapter = _ScriptedAdapter([_Scenario.http401()]);
      final dio = buildDio(adapter, manager);

      await expectLater(
        dio.get<dynamic>('/business/data'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'status',
            401,
          ),
        ),
      );
      expect(adapter.callCount, 1);
      expect(notifiedErrors, isEmpty);
    });

    test('单 Token 模式 401 → 不刷新不重放，通知登出', () async {
      final strategy = _FakeSingleStrategy();
      final manager = TokenManager(strategy: strategy);

      final adapter = _ScriptedAdapter([_Scenario.http401()]);
      final dio = buildDio(adapter, manager);

      await expectLater(
        dio.get<dynamic>('/business/data'),
        throwsA(isA<DioException>()),
      );
      expect(strategy.refreshCallCount, 0, reason: '单 Token 不应刷新');
      expect(adapter.callCount, 1);
      expect(
        notifiedErrors.whereType<NetworkAuthError>(),
        isNotEmpty,
        reason: '单 Token 401 通知登出（历史行为保持）',
      );
    });

    test('并发多个 401 请求 → 单飞锁合并为一次刷新', () async {
      final strategy = _FakeDualStrategy(
        refreshResult: 'token-new',
        refreshDelay: const Duration(milliseconds: 50),
      );
      final manager = TokenManager(strategy: strategy);

      // 3 个并发请求全部首发 401，重放全部成功
      final adapter = _ScriptedAdapter([
        _Scenario.http401(),
        _Scenario.http401(),
        _Scenario.http401(),
        _Scenario.success({'code': 200, 'data': 'd1'}),
        _Scenario.success({'code': 200, 'data': 'd2'}),
        _Scenario.success({'code': 200, 'data': 'd3'}),
      ]);
      final dio = buildDio(adapter, manager);

      final results = await Future.wait([
        dio.get<dynamic>('/business/a'),
        dio.get<dynamic>('/business/b'),
        dio.get<dynamic>('/business/c'),
      ]);

      expect(
        results.map((r) => (r.data as Map<String, dynamic>)['data']),
        ['d1', 'd2', 'd3'],
      );
      expect(
        strategy.refreshCallCount,
        1,
        reason: '并发 401 兜底刷新必须单飞合并',
      );
    });
  });

  group('防死循环', () {
    test('重放后仍 HTTP 401 → 不再二次刷新重放', () async {
      final strategy = _FakeDualStrategy(refreshResult: 'token-new');
      final manager = TokenManager(strategy: strategy);

      // 首发 401 → 刷新成功 → 重放仍 401 → 必须停止（auth_retried）
      final adapter = _ScriptedAdapter([
        _Scenario.http401(),
        _Scenario.http401(),
      ]);
      final dio = buildDio(adapter, manager);

      await expectLater(
        dio.get<dynamic>('/business/data'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.callCount, 2, reason: '只重放一次');
      expect(strategy.refreshCallCount, 1, reason: '只刷新一次');
    });

    test('重放后仍 HTTP 401 → 通知终态登出（恰好一次）', () async {
      final strategy = _FakeDualStrategy(refreshResult: 'token-new');
      final manager = TokenManager(strategy: strategy);

      final adapter = _ScriptedAdapter([
        _Scenario.http401(),
        _Scenario.http401(),
      ]);
      final dio = buildDio(adapter, manager);

      await expectLater(
        dio.get<dynamic>('/business/data'),
        throwsA(isA<DioException>()),
      );
      final authErrors = notifiedErrors.whereType<NetworkAuthError>().toList();
      expect(
        authErrors,
        hasLength(1),
        reason: 'inner/outer 双检查点不得产生双登出通知',
      );
      expect(authErrors.single, isA<AuthenticationFailedError>());
    });

    test('刷新端点自身 401 → 不进恢复流程（防御纵深）', () async {
      final strategy = _FakeDualStrategy(refreshResult: 'token-new');
      final manager = TokenManager(strategy: strategy);

      final adapter = _ScriptedAdapter([_Scenario.http401()]);
      final dio = buildDio(adapter, manager);

      await expectLater(
        dio.get<dynamic>('/auth/refresh'),
        throwsA(isA<DioException>()),
      );
      expect(strategy.refreshCallCount, 0, reason: '刷新端点 401 不触发刷新');
      expect(adapter.callCount, 1);
      expect(notifiedErrors, isEmpty);
    });

    test('公共路径（登录）401 → 不刷新不重放不通知', () async {
      final strategy = _FakeDualStrategy(refreshResult: 'token-new');
      final manager = TokenManager(strategy: strategy);

      final adapter = _ScriptedAdapter([_Scenario.http401()]);
      final dio = buildDio(adapter, manager);

      await expectLater(
        dio.get<dynamic>('/auth/login'),
        throwsA(isA<DioException>()),
      );
      expect(strategy.refreshCallCount, 0);
      expect(adapter.callCount, 1);
      expect(notifiedErrors, isEmpty);
    });

    test('已取消的请求 401 → 不重放', () async {
      final strategy = _FakeDualStrategy(refreshResult: 'token-new');
      final manager = TokenManager(strategy: strategy);

      final adapter = _ScriptedAdapter([_Scenario.http401()]);
      final dio = buildDio(adapter, manager);
      final cancelToken = CancelToken();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            // 拦在重放路径上：进入重放即取消（模拟"刷新期间用户离开页面"）
            if (options.extra[AuthInterceptor.kAuthRetriedKey] == true) {
              cancelToken.cancel();
            }
            handler.next(options);
          },
        ),
      );

      await expectLater(
        dio.get<dynamic>('/business/data', cancelToken: cancelToken),
        throwsA(isA<DioException>()),
      );
      expect(adapter.callCount, 1, reason: '取消的请求不重放');
    });
  });

  group('路径精确匹配', () {
    test('带前缀的相似路径不跳过认证（/admin/auth/login）', () async {
      final strategy = _FakeDualStrategy(refreshResult: 'token-new');
      final manager = TokenManager(strategy: strategy);

      String? capturedAuthHeader;
      final adapter = _ScriptedAdapter([
        _Scenario.success({'code': 200, 'data': 'protected'}),
      ]);
      final dio = buildDio(adapter, manager);
      // 捕获请求头，验证 Authorization 确实被注入（未跳过认证）
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedAuthHeader = options.headers['Authorization'] as String?;
            handler.next(options);
          },
        ),
      );

      final resp = await dio.get<dynamic>('/admin/auth/login');
      final body = resp.data as Map<String, dynamic>;

      expect(body['data'], 'protected');
      expect(adapter.callCount, 1);
      expect(
        capturedAuthHeader,
        'Bearer token-old',
        reason: '/admin/auth/login 不在 publicPaths 内，必须带 token',
      );
    });

    test('精确匹配的公共路径跳过认证（/auth/login）', () async {
      final strategy = _FakeDualStrategy(refreshResult: 'token-new');
      await strategy.clearToken();
      final manager = TokenManager(strategy: strategy);

      final adapter = _ScriptedAdapter([
        _Scenario.success({'code': 200, 'data': 'public'}),
      ]);
      final dio = buildDio(adapter, manager);

      // 无 token 但公共路径 → 请求应正常发出（不被 onRequest 拒绝）
      final resp = await dio.get<dynamic>('/auth/login');
      final body = resp.data as Map<String, dynamic>;

      expect(body['data'], 'public');
      expect(adapter.callCount, 1, reason: '公共路径无 token 也应放行');
    });
  });

  group('AuthConfig 运行时重注册（时序回归）', () {
    test('先有请求、后重注册带 publicPaths 的配置：公共路径仍被正确识别', () async {
      // 模拟真实启动时序：DI 只注册了空 AuthConfig → 发生首个请求
      // （缓存风险点）→ AuthProvider 重注册带 publicPaths 的配置
      final strategy = _FakeDualStrategy(refreshResult: 'token-new');
      final manager = TokenManager(strategy: strategy);

      final adapter = _ScriptedAdapter([
        _Scenario.success({'code': 200, 'data': 'protected'}),
        _Scenario.success({'code': 200, 'data': 'public'}),
      ]);
      final dio = buildDio(adapter, manager);

      // 1) 配置重注册前：业务路径正常带 token 请求（此时解析到的是
      //    setUp 注册的 ['/auth/login'] 配置，业务路径不受影响）
      final resp1 = await dio.get<dynamic>('/business/data');
      expect((resp1.data as Map<String, dynamic>)['data'], 'protected');

      // 2) 模拟 AuthProvider 启动：unregister 后重注册新的 publicPaths
      getIt
        ..unregister<AuthConfig>()
        ..registerSingleton<AuthConfig>(
          const AuthConfig(publicPaths: ['/auth/login', '/resource/sms/code']),
        );

      // 3) 重注册后：新配置中的公共路径必须生效（getter 实时解析，
      //    若被 late final 缓存，此处会拿旧配置判定为需认证而拒绝请求）
      final resp2 = await dio.get<dynamic>('/resource/sms/code');
      expect(
        (resp2.data as Map<String, dynamic>)['data'],
        'public',
        reason: 'AuthConfig 重注册后拦截器必须感知新配置',
      );
    });
  });

  group('无 token 场景（onRequest 拒绝）', () {
    test('双 Token 无 token → 拒绝且不通知（等待登录后重试）', () async {
      final strategy = _FakeDualStrategy(refreshResult: 'token-new');
      await strategy.clearToken();
      final manager = TokenManager(strategy: strategy);

      final adapter = _ScriptedAdapter([]);
      final dio = buildDio(adapter, manager);

      await expectLater(
        dio.get<dynamic>('/business/data'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.callCount, 0, reason: '请求根本不该发出');
      expect(
        notifiedErrors,
        isEmpty,
        reason: '双 Token 模式无 token 不触发登出通知',
      );
    });

    test('单 Token 无 token → 拒绝并通知登出', () async {
      final strategy = _FakeSingleStrategy();
      await strategy.clearToken();
      final manager = TokenManager(strategy: strategy);

      final adapter = _ScriptedAdapter([]);
      final dio = buildDio(adapter, manager);

      await expectLater(
        dio.get<dynamic>('/business/data'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.callCount, 0);
      expect(notifiedErrors.whereType<NetworkAuthError>(), isNotEmpty);
    });
  });
}

/// 场景脚本：Adapter 按顺序消费
class _Scenario {
  _Scenario.business401(String msg)
    : _status = 200,
      _body = '{"code":401,"msg":"$msg"}';

  _Scenario.http401()
    : _status = 401,
      _body = '';

  _Scenario.success(Map<String, dynamic> body)
    : _status = 200,
      _body = jsonEncode(body);

  final int _status;
  final String _body;

  ResponseBody toResponseBody() {
    return ResponseBody.fromString(
      _body,
      _status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

/// 脚本化 Adapter：按队列返回预设结果
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this._script);

  final List<_Scenario> _script;
  int callCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    callCount++;
    if (_script.isEmpty) {
      return _Scenario.success({'code': 200, 'data': 'default'})
          .toResponseBody();
    }
    return _script.removeAt(0).toResponseBody();
  }

  @override
  void close({bool force = false}) {}
}
