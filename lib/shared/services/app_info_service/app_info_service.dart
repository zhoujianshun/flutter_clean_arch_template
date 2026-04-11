import 'dart:async';

import 'package:flutter_clean_arch_template/shared/services/app_info_service/app_info_model.dart';
import 'package:injectable/injectable.dart';
import 'package:package_info_plus/package_info_plus.dart';

export 'package:flutter_clean_arch_template/shared/services/app_info_service/app_info_model.dart';

/// 应用信息服务
/// 提供获取应用版本、构建号等信息的功能（懒加载+安全初始化）
@singleton
class AppInfoService {
  PackageInfo? _packageInfo;
  Completer<void>? _initCompleter;

  // 缓存AppInfoModel，避免重复创建
  late AppInfoModel? _appInfoCache;

  /// 【懒加载初始化】自动初始化，无需外部手动调用
  Future<void> _init() async {
    if (_packageInfo != null) return;
    if (_initCompleter != null) return _initCompleter!.future;

    _initCompleter = Completer<void>();
    try {
      _packageInfo = await PackageInfo.fromPlatform();
      // 初始化成功后缓存模型
      _appInfoCache = AppInfoModel(
        appName: _packageInfo!.appName,
        packageName: _packageInfo!.packageName,
        version: _packageInfo!.version,
        buildNumber: _packageInfo!.buildNumber,
      );
      _initCompleter!.complete();
    } catch (e) {
      _initCompleter!.completeError('应用信息初始化失败: $e');
      rethrow;
    } finally {
      _initCompleter = null;
    }
  }

  /// 【公开初始化方法】手动调用也安全
  Future<void> initialize() async {
    await _init();
  }

  /// 检查是否已初始化完成
  bool get isInitialized => _packageInfo != null;

  /// 【安全获取应用信息】自动初始化，保证非空
  Future<AppInfoModel> get appInfo async {
    await _init();
    // 此时一定初始化完成，直接返回缓存
    return _appInfoCache!;
  }

  /// 【同步快捷获取】仅在已初始化后使用（如UI展示）
  AppInfoModel get appInfoSync {
    assert(
      isInitialized,
      'AppInfoService 未初始化！请先等待 appInfo 完成',
    );
    return _appInfoCache!;
  }
}
