import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_clean_arch_template/core/di/service_locator.dart';
import 'package:flutter_clean_arch_template/core/env/app_config.dart';
import 'package:flutter_clean_arch_template/core/env/env_config_manager.dart';
import 'package:flutter_clean_arch_template/core/initializers/refresh_init.dart';
import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';
import 'package:flutter_clean_arch_template/shared/utils/responsive_utils.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

/// Handles all application initialization in the correct order.
class AppInitializer {
  static Future<void> initialize(WidgetsBinding widgetsBinding) async {
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

    final timer = AppLogger.startTimer('App initialization');

    // 1. Environment config (must be first, other modules depend on it)
    await EnvConfigManager.initialize();

    // 2. Logger (pass environment params)
    await AppLogger.initialize(
      environment: AppConfig.environment,
      logLevel: AppConfig.logLevel,
    );
    timer.checkpoint('Environment and logger initialized');

    // 3. Screen orientation: tablets allow all directions, phones stay portrait
    final view = PlatformDispatcher.instance.views.first;
    final shortestSide = view.physicalSize.shortestSide / view.devicePixelRatio;
    if (shortestSide >= ResponsiveUtils.compactBreakpoint) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }

    // 4. Dependency injection (GetIt)
    await ServiceLocator.initialize();

    // 5. EasyRefresh global config
    refreshInit();

    timer.stop();
  }
}
