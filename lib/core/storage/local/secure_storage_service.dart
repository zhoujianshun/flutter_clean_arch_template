import 'package:flutter_clean_arch_template/core/errors/exceptions.dart';
import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage service for sensitive data
class SecureStorageService {
  SecureStorageService({
    FlutterSecureStorage? storage,
    this.maxReadAttempts = 3,
    this.readRetryDelay = const Duration(milliseconds: 100),
  }) : assert(maxReadAttempts > 0, 'maxReadAttempts must be greater than zero'),
       // v10 起 encryptedSharedPreferences 已废弃（Jetpack Security 停止维护），
       // 库默认使用自带 custom cipher 加密，且首次访问自动迁移旧数据，
       // 仅显式配置 iOS Keychain 可访问性即可。
       _storage =
           storage ??
           const FlutterSecureStorage(
             iOptions: IOSOptions(
               accessibility: KeychainAccessibility.first_unlock_this_device,
             ),
           );

  final FlutterSecureStorage _storage;

  /// 安全存储读取失败时的最大尝试次数。
  final int maxReadAttempts;

  /// 安全存储读取重试间隔。
  final Duration readRetryDelay;

  /// Write data to secure storage
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      AppLogger.d('Secure storage write successful: $key');
    } catch (e, stackTrace) {
      AppLogger.e(
        'Secure storage write failed: $key',
        error: e,
        stackTrace: stackTrace,
      );
      throw StorageException(
        message: 'Failed to write to secure storage: $key',
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Read data from secure storage
  ///
  /// Returns null only when the key does not exist.
  ///
  /// Transient platform failures are retried. If all attempts fail, throws a
  /// [StorageException] so callers do not mistake an I/O failure for logout.
  Future<String?> read(String key) async {
    Object? lastError;
    StackTrace? lastStackTrace;

    for (var attempt = 1; attempt <= maxReadAttempts; attempt++) {
      try {
        final value = await _storage.read(key: key);
        AppLogger.d(
          'Secure storage read: $key ${value != null ? '[EXISTS]' : '[NULL]'}',
        );
        return value;
      } catch (error, stackTrace) {
        lastError = error;
        lastStackTrace = stackTrace;
        AppLogger.w(
          'Secure storage read failed: $key '
          '(attempt $attempt/$maxReadAttempts)',
          error: error,
          stackTrace: stackTrace,
        );

        if (attempt < maxReadAttempts) {
          await Future<void>.delayed(readRetryDelay);
        }
      }
    }

    throw StorageException(
      message: 'Failed to read from secure storage: $key',
      cause: lastError,
      stackTrace: lastStackTrace,
    );
  }

  /// Delete data from secure storage
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
      AppLogger.d('Secure storage delete successful: $key');
    } catch (e, stackTrace) {
      AppLogger.e(
        'Secure storage delete failed: $key',
        error: e,
        stackTrace: stackTrace,
      );
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
      AppLogger.e(
        'Secure storage readAll failed',
        error: e,
        stackTrace: stackTrace,
      );
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
      AppLogger.e(
        'Secure storage getAllKeys failed',
        error: e,
        stackTrace: stackTrace,
      );
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
      AppLogger.e(
        'Secure storage deleteAll failed',
        error: e,
        stackTrace: stackTrace,
      );
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
      AppLogger.d(
        'Secure storage writeAll successful: ${data.keys.length} items',
      );
    } catch (e, stackTrace) {
      AppLogger.e(
        'Secure storage writeAll failed',
        error: e,
        stackTrace: stackTrace,
      );
      throw StorageException(
        message: 'Failed to write all to secure storage',
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }
}
