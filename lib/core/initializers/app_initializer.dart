import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/core/di/service_locator.dart';
import 'package:flutter_clean_arch_template/core/env/app_config.dart';
import 'package:flutter_clean_arch_template/core/env/env_config_manager.dart';
import 'package:flutter_clean_arch_template/core/initializers/refresh_init.dart';
import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

/// Handles all application initialization in the correct order.
class AppInitializer {
  /// 应用启动引导：按顺序完成环境、日志、依赖注入、第三方组件配置的初始化。
  ///
  /// 任一环节失败都会抛出异常并中断后续步骤，由调用方（[main] 的 `_bootstrap`）
  /// 捕获后渲染兜底错误页。初始化顺序不可调整——后续模块都依赖前序模块的结果。
  static Future<void> initialize(WidgetsBinding widgetsBinding) async {
    // 保留原生启动图，直到 Flutter 首帧渲染完成，避免白屏/闪屏。
    // 注意：初始化失败时需在 catch 中主动 remove（见下），否则兜底页会被遮挡。
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

    final timer = AppLogger.startTimer('App initialization');

    try {
      // 1. 环境配置（必须最先执行，后续模块均依赖 AppConfig 中的环境参数）
      await EnvConfigManager.initialize();

      // 2. 日志系统（传入环境参数，如日志级别、环境标识）
      await AppLogger.initialize(
        environment: AppConfig.environment,
        logLevel: AppConfig.logLevel,
      );
      timer.checkpoint('Environment and logger initialized');

      // 3. 依赖注入容器（GetIt）：注册各层的仓库、服务等
      await ServiceLocator.initialize();

      // 4. EasyRefresh 全局默认配置（统一刷新/加载样式）
      refreshInit();

      timer.stop();
    } catch (e, stackTrace) {
      timer.stop();
      AppLogger.fatal('应用初始化失败', error: e, stackTrace: stackTrace);
      // 必须移除原生 Splash，否则 main 渲染的兜底错误页会被其遮挡
      FlutterNativeSplash.remove();
      rethrow;
    }
  }

  /// 释放初始化期间创建的全局资源（App 退出时调用，与 [initialize] 对称）。
  ///
  /// 由 `_AppDisposeHookState.dispose()` 触发。注意：移动端系统强杀进程时
  /// 不保证会走到这里，因此这里只做「正常退出/热重载」场景下的显式清理。
  static void dispose() {
    // 当前无需额外清理（GetIt 等资源随进程结束自动释放）。
    // 保留方法签名以兼容调用方，后续若新增需要显式释放的资源可在此补充。
  }
}
