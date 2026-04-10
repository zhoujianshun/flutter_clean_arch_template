import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_clean_arch_template/core/errors/exceptions.dart';
import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';

/// SharedPreferences service for simple key-value storage
class SharedPrefsService {
  SharedPreferences? _prefs;
  static bool _initialized = false;
  static Completer<void>? _initCompleter;

  /// Initialize SharedPreferences
  Future<void> initialize() async {
    // 如果已经初始化完成，直接返回
    if (_initialized && _prefs != null) return;

    // 如果正在初始化，等待完成
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }

    // 创建 Completer 并开始初始化
    _initCompleter = Completer<void>();

    try {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
      AppLogger.i('SharedPrefs service initialized successfully');

      _initCompleter!.complete();
    } catch (e, stackTrace) {
      AppLogger.e('SharedPrefs service initialization failed', error: e, stackTrace: stackTrace);
      _initCompleter!.completeError(e);
      _initCompleter = null;
      throw StorageException(
        message: 'Failed to initialize SharedPreferences',
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get SharedPreferences instance
  SharedPreferences get prefs {
    if (_prefs == null) {
      throw const StorageException(message: 'SharedPreferences is not initialized');
    }
    return _prefs!;
  }

  /// Write string value
  Future<void> setString(String key, String value) async {
    try {
      await prefs.setString(key, value);
      AppLogger.d('SharedPrefs setString successful: $key');
    } catch (e, stackTrace) {
      AppLogger.e('SharedPrefs setString failed: $key', error: e, stackTrace: stackTrace);
      throw StorageException(
        message: 'Failed to set string in SharedPreferences: $key',
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Read string value
  String? getString(String key, {String? defaultValue}) {
    try {
      return prefs.getString(key) ?? defaultValue;
    } catch (e) {
      AppLogger.e('SharedPrefs getString failed: $key', error: e);
      return defaultValue;
    }
  }

  /// Write integer value
  Future<void> setInt(String key, int value) async {
    try {
      await prefs.setInt(key, value);
      AppLogger.d('SharedPrefs setInt successful: $key = $value');
    } catch (e, stackTrace) {
      AppLogger.e('SharedPrefs setInt failed: $key', error: e, stackTrace: stackTrace);
      throw StorageException(
        message: 'Failed to set int in SharedPreferences: $key',
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Read integer value
  int? getInt(String key, {int? defaultValue}) {
    try {
      return prefs.getInt(key) ?? defaultValue;
    } catch (e) {
      AppLogger.e('SharedPrefs getInt failed: $key', error: e);
      return defaultValue;
    }
  }

  /// Write double value
  Future<void> setDouble(String key, double value) async {
    try {
      await prefs.setDouble(key, value);
      AppLogger.d('SharedPrefs setDouble successful: $key = $value');
    } catch (e, stackTrace) {
      AppLogger.e('SharedPrefs setDouble failed: $key', error: e, stackTrace: stackTrace);
      throw StorageException(
        message: 'Failed to set double in SharedPreferences: $key',
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Read double value
  double? getDouble(String key, {double? defaultValue}) {
    try {
      return prefs.getDouble(key) ?? defaultValue;
    } catch (e) {
      AppLogger.e('SharedPrefs getDouble failed: $key', error: e);
      return defaultValue;
    }
  }

  /// Write boolean value
  Future<void> setBool(String key, bool value) async {
    try {
      await prefs.setBool(key, value);
      AppLogger.d('SharedPrefs setBool successful: $key = $value');
    } catch (e, stackTrace) {
      AppLogger.e('SharedPrefs setBool failed: $key', error: e, stackTrace: stackTrace);
      throw StorageException(
        message: 'Failed to set bool in SharedPreferences: $key',
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Read boolean value
  bool? getBool(String key, {bool? defaultValue}) {
    try {
      return prefs.getBool(key) ?? defaultValue;
    } catch (e) {
      AppLogger.e('SharedPrefs getBool failed: $key', error: e);
      return defaultValue;
    }
  }

  /// Write string list value
  Future<void> setStringList(String key, List<String> value) async {
    try {
      await prefs.setStringList(key, value);
      AppLogger.d('SharedPrefs setStringList successful: $key (${value.length} items)');
    } catch (e, stackTrace) {
      AppLogger.e('SharedPrefs setStringList failed: $key', error: e, stackTrace: stackTrace);
      throw StorageException(
        message: 'Failed to set string list in SharedPreferences: $key',
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Read string list value
  List<String>? getStringList(String key, {List<String>? defaultValue}) {
    try {
      return prefs.getStringList(key) ?? defaultValue;
    } catch (e) {
      AppLogger.e('SharedPrefs getStringList failed: $key', error: e);
      return defaultValue;
    }
  }

  /// Remove value by key
  Future<void> remove(String key) async {
    try {
      await prefs.remove(key);
      AppLogger.d('SharedPrefs remove successful: $key');
    } catch (e, stackTrace) {
      AppLogger.e('SharedPrefs remove failed: $key', error: e, stackTrace: stackTrace);
      throw StorageException(
        message: 'Failed to remove from SharedPreferences: $key',
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Check if key exists
  bool containsKey(String key) {
    try {
      final exists = prefs.containsKey(key);
      AppLogger.d('SharedPrefs containsKey: $key = $exists');
      return exists;
    } catch (e) {
      AppLogger.e('SharedPrefs containsKey failed: $key', error: e);
      return false;
    }
  }

  /// Get all keys
  Set<String> getKeys() {
    try {
      final keys = prefs.getKeys();
      AppLogger.d('SharedPrefs getKeys: ${keys.length} keys');
      return keys;
    } catch (e) {
      AppLogger.e('SharedPrefs getKeys failed', error: e);
      return <String>{};
    }
  }

  /// Clear all data
  Future<void> clear() async {
    try {
      await prefs.clear();
      AppLogger.i('SharedPrefs cleared successfully');
    } catch (e, stackTrace) {
      AppLogger.e('SharedPrefs clear failed', error: e, stackTrace: stackTrace);
      throw StorageException(
        message: 'Failed to clear SharedPreferences',
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Reload preferences from storage
  Future<void> reload() async {
    try {
      await prefs.reload();
      AppLogger.d('SharedPrefs reloaded successfully');
    } catch (e, stackTrace) {
      AppLogger.e('SharedPrefs reload failed', error: e, stackTrace: stackTrace);
      throw StorageException(
        message: 'Failed to reload SharedPreferences',
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }
}
