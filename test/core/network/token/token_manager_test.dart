import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_clean_arch_template/core/network/token/token_manager.dart';
import 'package:flutter_clean_arch_template/core/network/token/token_strategy.dart';
import 'package:flutter_test/flutter_test.dart';

/// 可编程的假策略：按脚本决定 token 内容与刷新行为，
/// refreshCallCount 用于断言「并发去重」。
class ScriptedStrategy implements TokenStrategy {
  ScriptedStrategy({
    this.initialToken = 'token-a',
    this.refreshResult,
    this.refreshError,
    this.needRefresh = true,
    this.refreshDelay = const Duration(milliseconds: 50),
    this.strategyName = 'Dual',
  });

  String? initialToken;
  String? refreshResult;
  Exception? refreshError;
  bool needRefresh;
  Duration refreshDelay;
  final String strategyName;

  int refreshCallCount = 0;

  @override
  String get name => strategyName;

  @override
  bool get supportsRefresh => true;

  @override
  Future<String?> getAccessToken() async => initialToken;

  @override
  Future<void> saveAccessToken({
    required String accessToken,
    String? refreshToken,
  }) async {
    initialToken = accessToken;
  }

  @override
  Future<void> clearToken() async {}

  @override
  Future<bool> isTokenExpired() async => false;

  @override
  bool shouldRefresh() => needRefresh;

  @override
  Future<String?> refreshToken() async {
    refreshCallCount++;
    await Future<void>.delayed(refreshDelay);
    if (refreshError != null) {
      throw refreshError!;
    }
    if (refreshResult != null) {
      initialToken = refreshResult;
    }
    return refreshResult;
  }
}

/// 不支持刷新的策略（单 Token 语义）
class NoRefreshStrategy extends ScriptedStrategy {
  NoRefreshStrategy()
    : super(
        initialToken: 'single-token',
        needRefresh: false,
        strategyName: 'Single',
      );

  @override
  bool get supportsRefresh => false;

  @override
  Future<String?> refreshToken() async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('并发刷新锁', () {
    test('并发 5 个 getValidToken 只触发一次真实刷新，全部拿到同一新 token', () async {
      final strategy = ScriptedStrategy(refreshResult: 'token-new');
      final manager = TokenManager(strategy: strategy);

      final results = await Future.wait(
        List.generate(5, (_) => manager.getValidToken()),
      );

      expect(strategy.refreshCallCount, 1, reason: '并发请求必须合并为一次刷新');
      expect(results, everyElement('token-new'));
    });

    test('真实时钟下连续两次调用（间隔远小于 2s）：第二次复用窗口期结果', () async {
      final strategy = ScriptedStrategy(refreshResult: 'token-new');
      final manager = TokenManager(strategy: strategy);

      final first = await manager.getValidToken();
      final second = await manager.getValidToken();
      expect(first, 'token-new');
      expect(second, 'token-new');
      expect(strategy.refreshCallCount, 1, reason: '2s 复用窗口内不应二次刷新');
    });

    test('刷新抛异常时所有并发等待者拿到 null，不抛 unhandled error', () async {
      final strategy = ScriptedStrategy(
        refreshError: Exception('network down'),
      );
      final manager = TokenManager(strategy: strategy);

      final results = await Future.wait(
        List.generate(3, (_) => manager.getValidToken()),
      );

      expect(strategy.refreshCallCount, 1);
      expect(results, everyElement(isNull));
    });

    test('单 Token 策略不刷新，直接返回当前 token', () async {
      final strategy = NoRefreshStrategy();
      final manager = TokenManager(strategy: strategy);

      final token = await manager.getValidToken();

      expect(token, 'single-token');
      expect(strategy.refreshCallCount, 0);
    });
  });

  group('窗口期复用（fakeAsync 驱动 Timer）', () {
    test('2s 窗口内的新请求复用结果不再刷新；窗口过后恢复刷新能力', () {
      final strategy = ScriptedStrategy(refreshResult: 'token-new');
      final manager = TokenManager(strategy: strategy);

      fakeAsync((async) {
        String? r1;
        unawaited(manager.getValidToken().then((v) => r1 = v));
        async.elapse(const Duration(milliseconds: 100)); // 刷新完成
        expect(r1, 'token-new');
        expect(strategy.refreshCallCount, 1);

        // 窗口期内第二个请求：直接复用，不刷新
        String? r2;
        unawaited(manager.getValidToken().then((v) => r2 = v));
        async.elapse(const Duration(milliseconds: 100));
        expect(r2, 'token-new');
        expect(strategy.refreshCallCount, 1, reason: '窗口期内不应再次刷新');

        // 窗口期（2s）过后：恢复刷新能力
        async.elapse(const Duration(seconds: 3));
        strategy.refreshResult = 'token-new-2';
        String? r3;
        unawaited(manager.getValidToken().then((v) => r3 = v));
        async.elapse(const Duration(milliseconds: 100));
        expect(r3, 'token-new-2');
        expect(strategy.refreshCallCount, 2);
      });
    });
  });

  group('失败冷却', () {
    test('刷新失败后 30s 内跳过刷新，直接返回当前 token；冷却过后恢复', () {
      final strategy = ScriptedStrategy()..refreshResult = null; // 刷新失败
      final manager = TokenManager(strategy: strategy);

      fakeAsync((async) {
        String? r1;
        unawaited(manager.getValidToken().then((v) => r1 = v));
        async.elapse(const Duration(milliseconds: 100));
        expect(r1, isNull);
        expect(strategy.refreshCallCount, 1);

        // 冷却期内：不再发起刷新，直接返回旧 token
        String? r2;
        unawaited(manager.getValidToken().then((v) => r2 = v));
        async.elapse(const Duration(milliseconds: 100));
        expect(r2, 'token-a');
        expect(strategy.refreshCallCount, 1, reason: '冷却期内不应刷新');

        // 冷却期过后：恢复刷新（仍失败 → 返回 null）
        async.elapse(const Duration(seconds: 31));
        String? r3;
        unawaited(manager.getValidToken().then((v) => r3 = v));
        async.elapse(const Duration(milliseconds: 100));
        expect(r3, isNull, reason: '出冷却后应恢复刷新，刷新仍失败返回 null');
        expect(strategy.refreshCallCount, 2);
      });
    });
  });

  group('登出/切策略竞态（P0 回归）', () {
    test('刷新进行中 clearToken：等待者立即被唤醒拿到 null，迟到结果不复活 token', () async {
      final strategy = ScriptedStrategy(refreshResult: 'token-late');
      final manager = TokenManager(strategy: strategy);

      final waiter = manager.getValidToken(); // 进入等待刷新
      await Future<void>.delayed(Duration.zero); // 让 waiter 挂到 completer 上

      await manager.clearToken(); // 刷新仍在"网络"中 → 中止

      expect(await waiter, isNull, reason: '等待者必须被唤醒且不拿到过期结果');

      // 迟到的刷新返回：Manager 已通过代际校验拦截广播；
      // 这里断言刷新确实只发生了一次，且不抛异常
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(strategy.refreshCallCount, 1);
      expect(manager.strategy, same(strategy));
    });

    test('刷新进行中 setStrategy：旧刷新结果不污染新策略', () async {
      final oldStrategy = ScriptedStrategy(
        refreshResult: 'token-late',
        strategyName: 'Old',
      );
      final newStrategy = NoRefreshStrategy();
      final manager = TokenManager(strategy: oldStrategy);

      final waiter = manager.getValidToken();
      await Future<void>.delayed(Duration.zero);

      manager.setStrategy(newStrategy);

      expect(await waiter, isNull);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      // 旧刷新结果被代际校验拦截，新策略的 token 不受污染
      expect(newStrategy.initialToken, 'single-token');
      expect(manager.strategy, same(newStrategy));
    });

    test('clearToken 后 2s 窗口 Timer 不误清新刷新的锁', () {
      final strategy = ScriptedStrategy(refreshResult: 'token-new');
      final manager = TokenManager(strategy: strategy);

      fakeAsync((async) {
        // 第一轮刷新完成，进入窗口期
        String? r1;
        unawaited(manager.getValidToken().then((v) => r1 = v));
        async.elapse(const Duration(milliseconds: 100));
        expect(r1, 'token-new');

        // 登出清锁 → 立刻再刷（模拟重新登录后的请求）
        unawaited(manager.clearToken());
        String? r2;
        unawaited(manager.getValidToken().then((v) => r2 = v));
        async.elapse(const Duration(milliseconds: 100));
        expect(r2, 'token-new');
        expect(strategy.refreshCallCount, 2);

        // 第一轮的 2s 窗口 Timer 若未防护，会把第二轮的 completer 置 null
        async.elapse(const Duration(seconds: 3));
        expect(strategy.refreshCallCount, 2, reason: '窗口 Timer 不得影响后续刷新');
      });
    });
  });

  group('forceRefresh', () {
    test('不支持刷新的策略返回当前 token 且不抛异常', () async {
      final strategy = NoRefreshStrategy();
      final manager = TokenManager(strategy: strategy);

      final token = await manager.forceRefresh();

      expect(token, 'single-token');
    });

    test('支持刷新的策略强制走刷新路径', () async {
      final strategy = ScriptedStrategy(refreshResult: 'token-forced');
      final manager = TokenManager(strategy: strategy);

      final token = await manager.forceRefresh();

      expect(token, 'token-forced');
      expect(strategy.refreshCallCount, 1);
    });

    test('冷却期内强制刷新直接返回 null（401 兜底防刷新风暴）', () {
      // 第一次刷新失败 → 进入 30s 冷却
      final strategy = ScriptedStrategy()..refreshResult = null;
      final manager = TokenManager(strategy: strategy);

      fakeAsync((async) {
        String? r1;
        unawaited(manager.forceRefresh().then((v) => r1 = v));
        async.elapse(const Duration(milliseconds: 100));
        expect(r1, isNull);
        expect(strategy.refreshCallCount, 1);

        // 冷却期内：连续到来的 401 兑底刷新不真实发起（单飞锁只防
        // "同时"的并发，冷却防"连续"的风暴）
        String? r2;
        unawaited(manager.forceRefresh().then((v) => r2 = v));
        async.elapse(const Duration(milliseconds: 100));
        expect(r2, isNull, reason: '冷却期内强制刷新返回 null 走登出');
        expect(strategy.refreshCallCount, 1, reason: '不应真实发起刷新');

        // 冷却期过后：恢复
        async.elapse(const Duration(seconds: 31));
        String? r3;
        unawaited(manager.forceRefresh().then((v) => r3 = v));
        async.elapse(const Duration(milliseconds: 100));
        expect(r3, isNull, reason: '出冷却恢复刷新，仍失败返回 null');
        expect(strategy.refreshCallCount, 2, reason: '出冷却后恢复强制刷新');
      });
    });
  });
}
