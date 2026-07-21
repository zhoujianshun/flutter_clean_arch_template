import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';

/// 网络状态枚举
enum NetworkStatus {
  connected,
  disconnected,
}

/// 网络服务 - 管理网络连接状态
///
/// 注册为单例，避免多处创建 Connectivity 实例。
@singleton
class NetworkInfo {
  NetworkInfo();

  final Connectivity _connectivity = Connectivity();

  /// 检查当前网络连接状态
  Future<bool> isConnected() async {
    final connectivityResults = await _connectivity.checkConnectivity();
    return !connectivityResults.contains(ConnectivityResult.none);
  }

  /// 监听网络连接状态变化
  Stream<NetworkStatus> get networkStatusStream {
    return _connectivity.onConnectivityChanged.map((results) {
      return !results.contains(ConnectivityResult.none) ? NetworkStatus.connected : NetworkStatus.disconnected;
    });
  }

  /// 获取连接类型
  Future<List<ConnectivityResult>> getConnectionType() async {
    return _connectivity.checkConnectivity();
  }

  /// 判断是否为WiFi连接
  Future<bool> isWiFiConnected() async {
    final connectivityResults = await _connectivity.checkConnectivity();
    return connectivityResults.contains(ConnectivityResult.wifi);
  }

  /// 判断是否为移动网络连接
  Future<bool> isMobileConnected() async {
    final connectivityResults = await _connectivity.checkConnectivity();
    return connectivityResults.contains(ConnectivityResult.mobile);
  }
}
