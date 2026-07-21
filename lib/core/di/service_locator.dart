import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_clean_arch_template/core/cache/cache_service.dart';
import 'package:flutter_clean_arch_template/core/di/service_locator.config.dart';
import 'package:flutter_clean_arch_template/core/env/app_config.dart';
import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';
import 'package:flutter_clean_arch_template/core/network/api_client.dart';
import 'package:flutter_clean_arch_template/core/network/auth_config.dart';
import 'package:flutter_clean_arch_template/core/network/network_info.dart';
import 'package:flutter_clean_arch_template/core/network/token/single_token_strategy.dart';
import 'package:flutter_clean_arch_template/core/network/token/token_manager.dart';
import 'package:flutter_clean_arch_template/core/network/token/token_storage.dart';
import 'package:flutter_clean_arch_template/core/storage/local/hive_service.dart';
import 'package:flutter_clean_arch_template/core/storage/local/secure_storage_service.dart';
import 'package:flutter_clean_arch_template/core/storage/local/shared_prefs_service.dart';
import 'package:flutter_clean_arch_template/core/storage/storage_service.dart';
import 'package:flutter_clean_arch_template/shared/services/app_info_service/app_info_service.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';

/// Global service locator instance
///
/// Access via `getIt<T>()` using GetIt's callable class feature.
final GetIt getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async => getIt.init();

/// Manual dependency registration for classes not using injectable annotations.
@module
abstract class RegisterModule {
  @preResolve
  @singleton
  Future<StorageService> get storageService async {
    final hiveService = HiveService();
    await hiveService.initialize();

    final sharedPrefsService = SharedPrefsService();
    await sharedPrefsService.initialize();

    final secureStorageService = SecureStorageService();

    final service = StorageService(
      hiveService: hiveService,
      sharedPrefsService: sharedPrefsService,
      secureStorageService: secureStorageService,
    );

    // Register default AuthConfig (feature layers can override)
    if (!getIt.isRegistered<AuthConfig>()) {
      getIt.registerSingleton<AuthConfig>(const AuthConfig());
    }

    AppLogger.debug('StorageService initialized');
    return service;
  }

  /// Register TokenManager
  ///
  /// Currently uses SingleTokenStrategy (no refresh).
  /// Switch to DualTokenStrategy for refresh token support:
  /// ```dart
  /// TokenManager tokenManager(
  ///   TokenStorage tokenStorage,
  ///   NetworkErrorNotifier errorNotifier,
  /// ) => TokenManager(
  ///   strategy: DualTokenStrategy(
  ///     tokenStorage: tokenStorage,
  ///     dio: Dio(BaseOptions(baseUrl: AppConfig.baseUrl)),
  ///     refreshEndpoint: '/auth/refresh',
  ///     onAuthExpired: (message) => errorNotifier.notifyAuthError(
  ///       NetworkAuthError.tokenExpired(message),
  ///     ),
  ///   ),
  /// );
  /// ```
  @singleton
  TokenManager tokenManager(
    TokenStorage tokenStorage,
  ) => TokenManager(
    strategy: SingleTokenStrategy(tokenStorage: tokenStorage),
  );

  @singleton
  ApiClient apiClient(NetworkInfo networkInfo) => ApiClient(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: Duration(milliseconds: AppConfig.connectTimeout),
      receiveTimeout: Duration(milliseconds: AppConfig.receiveTimeout),
    ),
    dioLogger: AppLogger.dioLogger,
    networkInfo: networkInfo,
  );
}

class ServiceLocator {
  static Future<void> initialize() async {
    try {
      AppLogger.info('Initializing GetIt dependency injection...');
      await configureDependencies();
      _registerCacheService();
      unawaited(lazyInitialize());
      AppLogger.info('GetIt dependency injection initialized');
    } catch (e) {
      AppLogger.error(
        'GetIt initialization failed',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  static Future<void> lazyInitialize() async {
    try {
      final appInfoService = getIt<AppInfoService>();
      unawaited(appInfoService.initialize());

      final cacheService = getIt<CacheService>();
      unawaited(cacheService.clearExpiredCache());
    } catch (e) {
      AppLogger.error(
        'Lazy initialization failed',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  static Future<void> reset() async {
    await getIt.reset();
    AppLogger.info('GetIt container reset');
  }

  /// 显式注册缓存服务，避免隐藏在 StorageService 构造流程中的副作用注册。
  static void _registerCacheService() {
    if (getIt.isRegistered<CacheService>()) return;
    final cacheBox = Hive.box<dynamic>(HiveService.cacheBoxName);
    getIt.registerSingleton<CacheService>(CacheService(cacheBox));
  }

  static T get<T extends Object>() => getIt<T>();
  static T? getOrNull<T extends Object>() => getIt.isRegistered<T>() ? getIt<T>() : null;
  static bool isRegistered<T extends Object>() => getIt.isRegistered<T>();
  static Future<T> getAsync<T extends Object>() => getIt.getAsync<T>();
}
