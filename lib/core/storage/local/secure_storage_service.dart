import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_clean_arch_template/core/errors/exceptions.dart';
import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';

/// Secure storage service for sensitive data
class SecureStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Write data to secure storage
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      AppLogger.d('Secure storage write successful: $key');
    } catch (e, stackTrace) {
      AppLogger.e('Secure storage write failed: $key', error: e, stackTrace: stackTrace);
      throw StorageException(
        message: 'Failed to write to secure storage: $key',
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Read data from secure storage
  /// 
  /// Returns null if key doesn't exist or read fails (follows consistent error handling)
  Future<String?> read(String key) async {
    try {
      final value = await _storage.read(key: key);
      AppLogger.d('Secure storage read: $key ${value != null ? '[EXISTS]' : '[NULL]'}');
      return value;
    } catch (e, stackTrace) {
      AppLogger.e('Secure storage read failed: $key', error: e, stackTrace: stackTrace);
      return null; // 读操作失败返回 null，不抛出异常（统一错误处理策略）
    }
  }

  /// Delete data from secure storage
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
      AppLogger.d('Secure storage delete successful: $key');
    } catch (e, stackTrace) {
      AppLogger.e('Secure storage delete failed: $key', error: e, stackTrace: stackTrace);
      throw StorageException(
        message: 'Failed to delete from secure storage: $key',
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Check if key exists in secure storage
  Future<bool> containsKey(String key) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (e) {
      AppLogger.e('Secure storage containsKey failed: $key', error: e);
      return false;
    }
  }

  /// Get all keys from secure storage
  /// 
  /// ⚠️ WARNING: This method loads all secure data into memory at once.
  /// Use with caution and only when absolutely necessary.
  /// Consider using [containsKey] and [read] for specific keys instead.
  Future<Map<String, String>> readAll() async {
    try {
      final all = await _storage.readAll();
      AppLogger.d('Secure storage readAll: ${all.keys.length} items');
      AppLogger.w('readAll() was called - all secure data loaded into memory');
      return all;
    } catch (e, stackTrace) {
      AppLogger.e('Secure storage readAll failed', error: e, stackTrace: stackTrace);
      throw StorageException(
        message: 'Failed to read all from secure storage',
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get all keys from secure storage (without values)
  /// 
  /// This is a safer alternative to [readAll] when you only need the keys.
  Future<Set<String>> getAllKeys() async {
    try {
      final all = await _storage.readAll();
      AppLogger.d('Secure storage getAllKeys: ${all.keys.length} keys');
      return all.keys.toSet();
    } catch (e, stackTrace) {
      AppLogger.e('Secure storage getAllKeys failed', error: e, stackTrace: stackTrace);
      throw StorageException(
        message: 'Failed to get all keys from secure storage',
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Clear all data from secure storage
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
      AppLogger.i('Secure storage cleared successfully');
    } catch (e, stackTrace) {
      AppLogger.e('Secure storage deleteAll failed', error: e, stackTrace: stackTrace);
      throw StorageException(
        message: 'Failed to clear secure storage',
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Write multiple key-value pairs
  Future<void> writeAll(Map<String, String> data) async {
    try {
      for (final entry in data.entries) {
        await write(entry.key, entry.value);
      }
      AppLogger.d('Secure storage writeAll successful: ${data.keys.length} items');
    } catch (e, stackTrace) {
      AppLogger.e('Secure storage writeAll failed', error: e, stackTrace: stackTrace);
      throw StorageException(
        message: 'Failed to write all to secure storage',
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }
}
