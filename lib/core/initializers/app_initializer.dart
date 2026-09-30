import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/core/device/orientation_policy.dart';
import 'package:flutter_clean_arch_template/core/di/service_locator.dart';
import 'package:flutter_clean_arch_template/core/env/app_config.dart';
import 'package:flutter_clean_arch_template/core/env/env_config_manager.dart';
import 'package:flutter_clean_arch_template/core/initializers/refresh_init.dart';
import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

/// Handles all application initialization in the correct order.
class AppInitializer {
  /// 活跃的方向策略实例（供 [dispose] 移除监听）。
  static OrientationPolicy? _orientationPolicy;

  static Future<void> initialize(WidgetsBinding widgetsBinding) async {
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

    final timer = AppLogger.startTimer('App initialization');

    try {
      // 1. Environment config (must be first, other modules depend on it)
      await EnvConfigManager.initialize();

      // 2. Logger (pass environment params)
      await AppLogger.initialize(
        environment: AppConfig.environment,
        logLevel: AppConfig.logLevel,
      );
      timer.checkpoint('Environment and logger initialized');

      // 3. Orientation policy（applyAndObserve 同时注册折叠/展开监听）
      // 重试时先释放旧实例，防止观察者泄漏
      _orientationPolicy?.dispose();
      final view = PlatformDispatcher.instance.views.first;
      _orientationPolicy = OrientationPolicy(
        lockPhonePortrait: AppConfig.lockPhonePortrait,
      );
      await _orientationPolicy!.applyAndObserve(view);

      // 4. Dependency injection (GetIt)
      await ServiceLocator.initialize();

      // 5. EasyRefresh global config
      refreshInit();

      timer.stop();
    } catch (e, stackTrace) {
      timer.stop();
      // 释放可能已注册的观察者，避免重试时泄漏
      _orientationPolicy?.dispose();
      _orientationPolicy = null;
      AppLogger.fatal('应用初始化失败', error: e, stackTrace: stackTrace);
      // 必须移除原生 Splash，否则 main 渲染的兜底错误页会被其遮挡
      FlutterNativeSplash.remove();
      rethrow;
    }
  }

  /// 释放初始化期间创建的全局资源（App 退出时调用）。
  static void dispose() {
    _orientationPolicy?.dispose();
    _orientationPolicy = null;
  }
}
