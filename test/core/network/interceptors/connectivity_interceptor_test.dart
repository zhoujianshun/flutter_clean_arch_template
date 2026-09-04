import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_clean_arch_template/core/network/interceptors/connectivity_interceptor.dart';
import 'package:flutter_clean_arch_template/core/network/network_info.dart';
import 'package:flutter_test/flutter_test.dart';

/// 可编程网络状态假件：按脚本返回检测结果 + 可推送状态变化事件
class FakeNetworkInfo implements NetworkInfo {
  FakeNetworkInfo({required this.connected});

  bool connected;

  int checkCount = 0;

  final _controller = StreamController<NetworkStatus>.broadcast();

  void pushStatus(NetworkStatus status) => _controller.add(status);

  @override
  Future<bool> isConnected() async {
    checkCount++;
    return connected;
  }

  @override
  Stream<NetworkStatus> get networkStatusStream => _controller.stream;

  @override
  Future<List<ConnectivityResult>> getConnectionType() async => [];

  @override
  Future<bool> isWiFiConnected() async => false;

  @override
  Future<bool> isMobileConnected() async => false;
}

RequestOptions _options() => RequestOptions(path: '/test');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('连通性拦截', () {
    test('网络可用 → 放行', () async {
      final net = FakeNetworkInfo(connected: true);
      final interceptor = ConnectivityInterceptor(networkInfo: net);

      var passed = false;
      await interceptor.onRequest(
        _options(),
        _ReqHandler(onNext: () => passed = true),
      );
      expect(passed, isTrue);
      interceptor.dispose();
    });

    test('网络不可用 → 拒绝并带 connectionError 类型', () async {
      final net = FakeNetworkInfo(connected: false);
      final interceptor = ConnectivityInterceptor(networkInfo: net);

      DioException? rejected;
      await interceptor.onRequest(
        _options(),
        _ReqHandler(onReject: (e) => rejected = e),
      );
      expect(rejected?.type, DioExceptionType.connectionError);
      interceptor.dispose();
    });

    test('时间缓存生效：2 秒内多个请求只检测一次', () async {
      final net = FakeNetworkInfo(connected: true);
      final interceptor = ConnectivityInterceptor(networkInfo: net);

      for (var i = 0; i < 5; i++) {
        await interceptor.onRequest(_options(), _ReqHandler(onNext: () {}));
      }
      expect(net.checkCount, 1, reason: '缓存期内不重复平台调用');
      interceptor.dispose();
    });

    test('状态变化事件立即作废缓存：恢复连接后请求被放行（不再被旧 false 拦截）', () async {
      final net = FakeNetworkInfo(connected: false);
      final interceptor = ConnectivityInterceptor(networkInfo: net);

      // 断网 → 拒绝，缓存 false
      await interceptor.onRequest(_options(), _ReqHandler(onReject: (_) {}));

      // 网络恢复（事件 + 状态都变为 true）
      net
        ..connected = true
        ..pushStatus(NetworkStatus.connected);
      await Future<void>.delayed(Duration.zero); // 事件传播

      var passed = false;
      await interceptor.onRequest(
        _options(),
        _ReqHandler(onNext: () => passed = true),
      );

      expect(passed, isTrue, reason: '事件失效缓存后应重新检测并放行');
      expect(net.checkCount, 2, reason: '缓存作废后重新执行平台检测');
      interceptor.dispose();
    });
  });
}

class _ReqHandler extends RequestInterceptorHandler {
  _ReqHandler({this.onNext, this.onReject});
  final void Function()? onNext;
  final void Function(DioException)? onReject;

  @override
  void next(RequestOptions options) => onNext?.call();

  @override
  void reject(
    DioException error, [
    bool callFollowingErrorInterceptor = false,
  ]) => onReject?.call(error);
}
