import 'package:flutter_clean_arch_template/core/constants/storage_keys.dart';
import 'package:flutter_clean_arch_template/core/errors/exceptions.dart';
import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';
import 'package:flutter_clean_arch_template/core/storage/local/hive_service.dart';
import 'package:flutter_clean_arch_template/core/storage/local/secure_storage_service.dart';
import 'package:flutter_clean_arch_template/core/storage/local/shared_prefs_service.dart';
import 'package:flutter_clean_arch_template/shared/cache/cache_service.dart' show CacheService;

/// Unified storage service that manages persistent data
///
/// 职责：管理需要持久化保存的重要数据
/// - 用户数据（User Data）
/// - 应用设置（Settings）
/// - 安全令牌（Tokens）
///
/// ⚠️ 注意：临时数据和缓存请使用 [CacheService]
///
/// 使用示例：
/// ```dart
/// final storageService = getIt<StorageService>();
///
/// // 保存用户数据
/// await storageService.setUserData('user_info', userInfo);
///
/// // 保存设置
/// await storageService.setSetting('theme_mode', 'dark');
///
/// // 保存 Token
/// await storageService.setUserToken(token);
/// ```
class StorageService {
  StorageService({
    required HiveService hiveService,
    required SharedPrefsService sharedPrefsService,
    required SecureStorageService secureStorageService,
  }) : _hiveService = hiveService,
       _sharedPrefsService = sharedPrefsService,
       _secureStorageService = secureStorageService;

  final HiveService _hiveService;
  final SharedPrefsService _sharedPrefsService;
  final SecureStorageService _secureStorageService;

  /// Initialize all storage services
  Future<void> initialize() async {
    try {
      AppLogger.i('Initializing storage services...');

      await Future.wait([
        _hiveService.initialize(),
        _sharedPrefsService.initialize(),
      ]);

      AppLogger.i('All storage services initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.e('Storage service initialization failed', error: e, stackTrace: stackTrace);
      throw StorageException(
        message: 'Failed to initialize storage services',
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Close all storage services
  Future<void> close() async {
    try {
      await _hiveService.close();
      AppLogger.i('Storage services closed successfully');
    } catch (e) {
      AppLogger.e('Storage service close failed', error: e);
    }
  }

  // Hive Service Delegation
  HiveService get hive => _hiveService;

  // SharedPreferences Service Delegation
  SharedPrefsService get prefs => _sharedPrefsService;

  // Secure Storage Service Delegation
  SecureStorageService get secure => _secureStorageService;

  /// Clear all storage data (use with caution)
  Future<void> clearAll() async {
    try {
      AppLogger.w('Clearing all storage data...');

      await Future.wait([
        _hiveService.clearUserData(),
        _hiveService.clearSettings(),
        _hiveService.clearCache(),
        _sharedPrefsService.clear(),
        _secureStorageService.deleteAll(),
      ]);

      AppLogger.i('All storage data cleared successfully');
    } catch (e, stackTrace) {
      AppLogger.e('Failed to clear all storage data', error: e, stackTrace: stackTrace);
      throw StorageException(
        message: 'Failed to clear all storage',
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get storage information for debugging
  Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final hiveUserKeys = _hiveService.getKeys('user_box').length;
      final hiveSettingsKeys = _hiveService.getKeys('settings_box').length;
      final hiveCacheKeys = _hiveService.getKeys('cache_box').length;
      final prefsKeys = _sharedPrefsService.getKeys().length;
      // 使用 getAllKeys 替代 readAll，避免加载所有敏感数据到内存
      final secureKeys = (await _secureStorageService.getAllKeys()).length;

      return {
        'hive': {
          'user_keys': hiveUserKeys,
          'settings_keys': hiveSettingsKeys,
          'cache_keys': hiveCacheKeys,
        },
        'shared_preferences': {
          'keys': prefsKeys,
        },
        'secure_storage': {
          'keys': secureKeys,
        },
      };
    } catch (e) {
      AppLogger.e('Failed to get storage info', error: e);
      return {};
    }
  }

  // ==================== Hive 操作 ====================

  /// 用户数据操作
  Future<void> setUserData(String key, dynamic value) async {
    await hive.userBox.put(key, value);
  }

  T? getUserData<T>(String key) {
    return hive.userBox.get(key) as T?;
  }

  Future<void> removeUserData(String key) async {
    await hive.userBox.delete(key);
  }

  Future<void> clearUserData() async {
    await hive.userBox.clear();
  }

  // ==================== 缓存操作（已过时，请使用 CacheService）====================

  /// 存储缓存数据（带过期时间）
  ///
  /// ⚠️ 已过时：此方法将在未来版本中移除
  ///
  /// 请使用 [CacheService.cacheData()] 或 [CacheService.cacheApiResponse()] 代替：
  /// ```dart
  /// final cacheService = getIt<CacheService>();
  /// await cacheService.cacheData('key', value, ttl: Duration(minutes: 5));
  /// ```
  @Deprecated('请使用 CacheService.cacheData() 代替。此方法将在未来版本中移除。')
  Future<void> setCacheWithTTL(
    String key,
    dynamic value, {
    Duration? ttl,
  }) async {
    await hive.putCacheWithTTL(key, value, ttl: ttl);
  }

  /// 获取缓存数据（自动检查过期）
  ///
  /// ⚠️ 已过时：此方法将在未来版本中移除
  ///
  /// 请使用 [CacheService.getCachedData()] 或 [CacheService.getCachedApiResponse()] 代替：
  /// ```dart
  /// final cacheService = getIt<CacheService>();
  /// final data = cacheService.getCachedData<T>('key');
  /// ```
  @Deprecated('请使用 CacheService.getCachedData() 代替。此方法将在未来版本中移除。')
  T? getCacheWithTTL<T>(String key, {T? defaultValue}) {
    return hive.getCacheWithTTL<T>(key, defaultValue: defaultValue);
  }

  /// 清理所有过期的缓存
  ///
  /// ⚠️ 已过时：此方法将在未来版本中移除
  ///
  /// 请使用 [CacheService.clearExpiredCache()] 代替：
  /// ```dart
  /// final cacheService = getIt<CacheService>();
  /// await cacheService.clearExpiredCache();
  /// ```
  @Deprecated('请使用 CacheService.clearExpiredCache() 代替。此方法将在未来版本中移除。')
  Future<int> clearExpiredCache() async {
    return hive.clearExpiredCache();
  }

  // ==================== 用户令牌操作 ====================

  /// 存储用户令牌
  Future<void> setUserToken(String token) async {
    await secure.write(StorageKeys.userTokenKey, token);
  }

  /// 获取用户令牌
  Future<String?> getUserToken() async {
    return secure.read(StorageKeys.userTokenKey);
  }

  /// 移除用户令牌
  Future<void> removeUserToken() async {
    await secure.delete(StorageKeys.userTokenKey);
  }

  /// 检查是否登录
  Future<bool> isLoggedIn() async {
    final token = await getUserToken();
    return token != null && token.isNotEmpty;
  }
}
