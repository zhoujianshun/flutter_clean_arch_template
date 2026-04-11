import 'dart:async';

import 'package:flutter_clean_arch_template/core/errors/exceptions.dart';
import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Hive service for local data storage
class HiveService {
  static const String _userBoxName = 'user_box';
  static const String _settingsBoxName = 'settings_box';
  static const String _cacheBoxName = 'cache_box';

  Box<dynamic>? _userBox;
  Box<dynamic>? _settingsBox;
  Box<dynamic>? _cacheBox;

  static bool _initialized = false;
  static Completer<void>? _initCompleter;

  /// Initialize Hive database
  Future<void> initialize() async {
    // 如果已经初始化完成，直接返回
    if (_initialized) return;

    // 如果正在初始化，等待完成
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }

    // 创建 Completer 并开始初始化
    _initCompleter = Completer<void>();

    try {
      await Hive.initFlutter();

      // Register adapters here if needed
      // Hive.registerAdapter(UserModelAdapter());

      // Open boxes
      _userBox = await Hive.openBox(_userBoxName);
      _settingsBox = await Hive.openBox(_settingsBoxName);
      _cacheBox = await Hive.openBox(_cacheBoxName);

      _initialized = true;
      AppLogger.i('Hive service initialized successfully');

      _initCompleter!.complete();
    } catch (e, stackTrace) {
      AppLogger.e('Hive service initialization failed', error: e, stackTrace: stackTrace);
      _initCompleter!.completeError(e);
      _initCompleter = null;
      throw StorageException(
        message: 'Failed to initialize Hive',
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get user data box
  Box<dynamic> get userBox {
    if (_userBox == null || !_userBox!.isOpen) {
      throw const StorageException(message: 'User box is not initialized or closed');
    }
    return _userBox!;
  }

  /// Get settings box
  Box<dynamic> get settingsBox {
    if (_settingsBox == null || !_settingsBox!.isOpen) {
      throw const StorageException(message: 'Settings box is not initialized or closed');
    }
    return _settingsBox!;
  }

  /// Get cache box
  Box<dynamic> get cacheBox {
    if (_cacheBox == null || !_cacheBox!.isOpen) {
      throw const StorageException(message: 'Cache box is not initialized or closed');
    }
    return _cacheBox!;
  }

  /// Store data in specific box
  Future<void> put(String boxName, String key, dynamic value) async {
    try {
      final box = await _getBox(boxName);
      await box.put(key, value);
      AppLogger.d('Hive put successful: $boxName.$key');
    } catch (e, stackTrace) {
      AppLogger.e('Hive put failed: $boxName.$key', error: e, stackTrace: stackTrace);
      throw StorageException(
        message: 'Failed to put data in Hive: $boxName.$key',
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get data from specific box
  T? get<T>(String boxName, String key, {T? defaultValue}) {
    try {
      final box = _getBoxSync(boxName);
      if (box == null) return defaultValue;

      final value = box.get(key, defaultValue: defaultValue);
      AppLogger.d('Hive get: $boxName.$key ${value != null ? '[EXISTS]' : '[NULL]'}');
      return value as T?;
    } catch (e) {
      AppLogger.e('Hive get failed: $boxName.$key', error: e);
      return defaultValue;
    }
  }

  /// Delete data from specific box
  Future<void> delete(String boxName, String key) async {
    try {
      final box = await _getBox(boxName);
      await box.delete(key);
      AppLogger.d('Hive delete successful: $boxName.$key');
    } catch (e, stackTrace) {
      AppLogger.e('Hive delete failed: $boxName.$key', error: e, stackTrace: stackTrace);
      throw StorageException(
        message: 'Failed to delete data from Hive: $boxName.$key',
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Check if key exists in specific box
  bool containsKey(String boxName, String key) {
    try {
      final box = _getBoxSync(boxName);
      return box?.containsKey(key) ?? false;
    } catch (e) {
      AppLogger.e('Hive containsKey failed: $boxName.$key', error: e);
      return false;
    }
  }

  /// Get all keys from specific box
  Iterable<dynamic> getKeys(String boxName) {
    try {
      final box = _getBoxSync(boxName);
      return box?.keys ?? [];
    } catch (e) {
      AppLogger.e('Hive getKeys failed: $boxName', error: e);
      return [];
    }
  }

  /// Get all values from specific box
  Iterable<dynamic> getValues(String boxName) {
    try {
      final box = _getBoxSync(boxName);
      return box?.values ?? [];
    } catch (e) {
      AppLogger.e('Hive getValues failed: $boxName', error: e);
      return [];
    }
  }

  /// Clear all data from specific box
  Future<void> clear(String boxName) async {
    try {
      final box = await _getBox(boxName);
      await box.clear();
      AppLogger.i('Hive box cleared: $boxName');
    } catch (e, stackTrace) {
      AppLogger.e('Hive clear failed: $boxName', error: e, stackTrace: stackTrace);
      throw StorageException(
        message: 'Failed to clear Hive box: $boxName',
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Close all boxes and clean up
  Future<void> close() async {
    try {
      await _userBox?.close();
      await _settingsBox?.close();
      await _cacheBox?.close();

      _userBox = null;
      _settingsBox = null;
      _cacheBox = null;
      _initialized = false;
      _initCompleter = null;

      AppLogger.i('Hive service closed successfully');
    } catch (e) {
      AppLogger.e('Hive service close failed', error: e);
    }
  }

  /// Get box by name (async)
  Future<Box<dynamic>> _getBox(String boxName) async {
    switch (boxName) {
      case _userBoxName:
        if (_userBox == null || !_userBox!.isOpen) {
          AppLogger.w('User box is not properly initialized, attempting to reopen...');
          _userBox = await Hive.openBox(_userBoxName);
        }
        return _userBox!;
      case _settingsBoxName:
        if (_settingsBox == null || !_settingsBox!.isOpen) {
          AppLogger.w('Settings box is not properly initialized, attempting to reopen...');
          _settingsBox = await Hive.openBox(_settingsBoxName);
        }
        return _settingsBox!;
      case _cacheBoxName:
        if (_cacheBox == null || !_cacheBox!.isOpen) {
          AppLogger.w('Cache box is not properly initialized, attempting to reopen...');
          _cacheBox = await Hive.openBox(_cacheBoxName);
        }
        return _cacheBox!;
      default:
        AppLogger.w('Opening non-standard box: $boxName');
        return Hive.openBox(boxName);
    }
  }

  /// Get box by name (sync)
  Box<dynamic>? _getBoxSync(String boxName) {
    switch (boxName) {
      case _userBoxName:
        return _userBox;
      case _settingsBoxName:
        return _settingsBox;
      case _cacheBoxName:
        return _cacheBox;
      default:
        return Hive.isBoxOpen(boxName) ? Hive.box(boxName) : null;
    }
  }

  /// User data convenience methods
  Future<void> putUser(String key, dynamic value) => put(_userBoxName, key, value);
  T? getUser<T>(String key, {T? defaultValue}) => get<T>(_userBoxName, key, defaultValue: defaultValue);
  Future<void> deleteUser(String key) => delete(_userBoxName, key);
  Future<void> clearUserData() => clear(_userBoxName);

  /// Settings convenience methods
  Future<void> putSetting(String key, dynamic value) => put(_settingsBoxName, key, value);
  T? getSetting<T>(String key, {T? defaultValue}) => get<T>(_settingsBoxName, key, defaultValue: defaultValue);
  Future<void> deleteSetting(String key) => delete(_settingsBoxName, key);
  Future<void> clearSettings() => clear(_settingsBoxName);

  /// Cache convenience methods
  Future<void> putCache(String key, dynamic value) => put(_cacheBoxName, key, value);
  T? getCache<T>(String key, {T? defaultValue}) => get<T>(_cacheBoxName, key, defaultValue: defaultValue);
  Future<void> deleteCache(String key) => delete(_cacheBoxName, key);
  Future<void> clearCache() => clear(_cacheBoxName);

  // ==================== 缓存管理（带过期时间）====================

  /// Put value in cache with optional TTL (Time To Live)
  ///
  /// [key] - Cache key
  /// [value] - Value to cache
  /// [ttl] - Time to live duration, null means no expiration
  Future<void> putCacheWithTTL(
    String key,
    dynamic value, {
    Duration? ttl,
  }) async {
    final now = DateTime.now();
    final cacheData = {
      'value': value,
      'createdAt': now.millisecondsSinceEpoch,
      'expiresAt': ttl != null ? now.add(ttl).millisecondsSinceEpoch : null,
    };
    await putCache(key, cacheData);
  }

  /// Get value from cache, returns null if expired or not found
  ///
  /// [key] - Cache key
  /// [defaultValue] - Default value if cache miss or expired
  T? getCacheWithTTL<T>(String key, {T? defaultValue}) {
    try {
      final cacheData = getCache<Map<dynamic, dynamic>>(key);
      if (cacheData == null) return defaultValue;

      final expiresAt = cacheData['expiresAt'] as int?;

      // Check expiration
      if (expiresAt != null) {
        final expiryTime = DateTime.fromMillisecondsSinceEpoch(expiresAt);
        if (DateTime.now().isAfter(expiryTime)) {
          // Cache expired, delete it
          deleteCache(key).ignore();
          AppLogger.d('Cache expired and deleted: $key');
          return defaultValue;
        }
      }

      return cacheData['value'] as T?;
    } catch (e) {
      AppLogger.e('Failed to get cache with TTL: $key', error: e);
      return defaultValue;
    }
  }

  /// Clear expired cache entries
  Future<int> clearExpiredCache() async {
    try {
      AppLogger.i('Clearing expired cache...');
      final box = cacheBox;
      final keys = box.keys.toList();
      var deletedCount = 0;

      for (final key in keys) {
        try {
          final cacheData = box.get(key);
          if (cacheData is Map) {
            final expiresAt = cacheData['expiresAt'] as int?;
            if (expiresAt != null) {
              final expiryTime = DateTime.fromMillisecondsSinceEpoch(expiresAt);
              if (DateTime.now().isAfter(expiryTime)) {
                await box.delete(key);
                deletedCount++;
              }
            }
          }
        } catch (e) {
          AppLogger.e('Failed to check cache expiration for key: $key', error: e);
        }
      }

      AppLogger.i('Cleared $deletedCount expired cache entries');
      return deletedCount;
    } catch (e) {
      AppLogger.e('Failed to clear expired cache', error: e);
      return 0;
    }
  }
}
