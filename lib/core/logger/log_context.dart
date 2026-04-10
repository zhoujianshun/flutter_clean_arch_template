import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

/// 日志上下文信息
/// 包含用户信息、设备信息、会话信息等
class LogContext {
  LogContext({
    this.userId,
    this.deviceId,
    this.sessionId,
    this.appVersion,
    this.buildNumber,
    this.platform,
    this.osVersion,
    this.deviceModel,
    Map<String, dynamic>? custom,
  }) : custom = custom ?? {};

  /// 用户ID
  String? userId;

  /// 设备ID
  String? deviceId;

  /// 会话ID
  String? sessionId;

  /// 应用版本
  String? appVersion;

  /// 构建号
  String? buildNumber;

  /// 平台（iOS/Android）
  String? platform;

  /// 操作系统版本
  String? osVersion;

  /// 设备型号
  String? deviceModel;

  /// 自定义上下文信息
  Map<String, dynamic> custom;

  /// 转换为 Map
  Map<String, dynamic> toMap() {
    return {
      if (userId != null) 'userId': userId,
      if (deviceId != null) 'deviceId': deviceId,
      if (sessionId != null) 'sessionId': sessionId,
      if (appVersion != null) 'appVersion': appVersion,
      if (buildNumber != null) 'buildNumber': buildNumber,
      if (platform != null) 'platform': platform,
      if (osVersion != null) 'osVersion': osVersion,
      if (deviceModel != null) 'deviceModel': deviceModel,
      if (custom.isNotEmpty) ...custom,
    };
  }

  /// 创建日志上下文
  static Future<LogContext> create({
    String? userId,
    Map<String, dynamic>? custom,
  }) async {
    try {
      // 获取应用信息
      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion = packageInfo.version;
      final buildNumber = packageInfo.buildNumber;

      // 获取设备信息
      final deviceInfo = DeviceInfoPlugin();
      String? deviceId;
      String? platform;
      String? osVersion;
      String? deviceModel;

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
        platform = 'Android';
        osVersion = androidInfo.version.release;
        deviceModel = '${androidInfo.manufacturer} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor;
        platform = 'iOS';
        osVersion = iosInfo.systemVersion;
        deviceModel = iosInfo.model;
      }

      // 生成会话ID
      const uuid = Uuid();
      final sessionId = uuid.v4();

      return LogContext(
        userId: userId,
        deviceId: deviceId,
        sessionId: sessionId,
        appVersion: appVersion,
        buildNumber: buildNumber,
        platform: platform,
        osVersion: osVersion,
        deviceModel: deviceModel,
        custom: custom,
      );
    } catch (e) {
      // 如果获取信息失败，返回基本上下文
      return LogContext(
        userId: userId,
        sessionId: const Uuid().v4(),
        custom: custom,
      );
    }
  }

  /// 复制并更新上下文
  LogContext copyWith({
    String? userId,
    String? deviceId,
    String? sessionId,
    String? appVersion,
    String? buildNumber,
    String? platform,
    String? osVersion,
    String? deviceModel,
    Map<String, dynamic>? custom,
  }) {
    return LogContext(
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      sessionId: sessionId ?? this.sessionId,
      appVersion: appVersion ?? this.appVersion,
      buildNumber: buildNumber ?? this.buildNumber,
      platform: platform ?? this.platform,
      osVersion: osVersion ?? this.osVersion,
      deviceModel: deviceModel ?? this.deviceModel,
      custom: custom ?? this.custom,
    );
  }

  @override
  String toString() {
    return 'LogContext(${toMap()})';
  }
}
