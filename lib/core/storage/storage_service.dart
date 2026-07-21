import 'package:flutter_clean_arch_template/core/constants/storage_keys.dart';
import 'package:flutter_clean_arch_template/core/errors/exceptions.dart';
import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';
import 'package:flutter_clean_arch_template/core/storage/local/hive_service.dart';
import 'package:flutter_clean_arch_template/core/storage/local/secure_storage_service.dart';
import 'package:flutter_clean_arch_template/core/storage/local/shared_prefs_service.dart';

/// Unified storage service that manages persistent data
///
/// 职责：管理需要持久化保存的重要数据
/// - 用户数据（User Data）
/// - 应用设置（Settings）
/// - 安全令牌（Tokens）
///
/// ⚠️ 注意：临时数据和缓存请使用 CacheService（位于 core/cache/）
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

  /// Clear all storage data (use with caution)
  Future<void> clearAll() async {
    try {
      AppLogger.w('Clearing all storage data...');

      await Future.wait([
        _hiveService.clearUserData(),
        _hiveService.clearSettings(),
        _hiveService.clear(HiveService.cacheBoxName),
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
      final hiveUserKeys = _hiveService.getKeys(HiveService.userBoxName).length;
      final hiveSettingsKeys = _hiveService.getKeys(HiveService.settingsBoxName).length;
      final hiveCacheKeys = _hiveService.getKeys(HiveService.cacheBoxName).length;
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
    await _hiveService.putUser(key, value);
  }

  T? getUserData<T>(String key) {
    return _hiveService.getUser<T>(key);
  }

  Future<void> removeUserData(String key) async {
    await _hiveService.deleteUser(key);
  }

  Future<void> clearUserData() async {
    await _hiveService.clearUserData();
  }

  // ==================== 设置操作 ====================

  /// 存储字符串配置
  Future<void> setSetting(String key, String value) async {
    await _sharedPrefsService.setString(key, value);
  }

  /// 获取字符串配置
  String? getSetting(String key, {String? defaultValue}) {
    return _sharedPrefsService.getString(key, defaultValue: defaultValue);
  }

  /// 移除配置
  Future<void> removeSetting(String key) async {
    await _sharedPrefsService.remove(key);
  }

  /// 清空所有配置
  Future<void> clearAllSettings() async {
    await _sharedPrefsService.clear();
  }

  // ==================== 用户令牌操作 ====================

  /// 存储用户令牌
  Future<void> setUserToken(String token) async {
    await _secureStorageService.write(StorageKeys.userTokenKey, token);
  }

  /// 获取用户令牌
  Future<String?> getUserToken() async {
    return _secureStorageService.read(StorageKeys.userTokenKey);
  }

  /// 移除用户令牌
  Future<void> removeUserToken() async {
    await _secureStorageService.delete(StorageKeys.userTokenKey);
  }

  /// 存储刷新令牌
  Future<void> setRefreshToken(String refreshToken) async {
    await _secureStorageService.write(StorageKeys.refreshTokenKey, refreshToken);
  }

  /// 获取刷新令牌
  Future<String?> getRefreshToken() async {
    return _secureStorageService.read(StorageKeys.refreshTokenKey);
  }

  /// 移除刷新令牌
  Future<void> removeRefreshToken() async {
    await _secureStorageService.delete(StorageKeys.refreshTokenKey);
  }

  /// 检查是否登录
  Future<bool> isLoggedIn() async {
    final token = await getUserToken();
    return token != null && token.isNotEmpty;
  }
}
