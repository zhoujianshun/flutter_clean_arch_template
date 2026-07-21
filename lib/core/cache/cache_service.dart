import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_clean_arch_template/core/cache/app_cache_managers.dart';
import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// 统一缓存服务
///
/// 职责：管理所有临时数据和文件缓存（可随时清除不影响核心功能）
/// - API 响应数据缓存（带 TTL）
/// - 列表数据缓存
/// - 图片/文档文件缓存
///
/// ⚠️ 注意：持久化重要数据（用户信息、Token、设置）请使用 StorageService
///
/// 使用示例：
/// ```dart
/// final cacheService = getIt<CacheService>();
///
/// // 缓存 API 响应
/// await cacheService.cacheApiResponse('orders/list', ordersData);
///
/// // 获取缓存
/// final cached = cacheService.getCachedApiResponse<List>('orders/list');
///
/// // 缓存图片
/// final file = await cacheService.cacheAvatar(avatarUrl);
/// ```
class CacheService {
  CacheService(this._cacheBox);

  final Box<dynamic> _cacheBox;

  // ==================== 数据缓存（带 TTL） ====================

  /// 缓存数据（通用方法）
  ///
  /// [key] - 缓存键
  /// [data] - 要缓存的数据
  /// [ttl] - 过期时间，默认 5 分钟
  Future<void> cacheData(
    String key,
    dynamic data, {
    Duration? ttl,
  }) async {
    final now = DateTime.now();
    final effectiveTtl = ttl ?? const Duration(minutes: 5);
    final cacheEntry = {
      'value': data,
      'createdAt': now.millisecondsSinceEpoch,
      'expiresAt': now.add(effectiveTtl).millisecondsSinceEpoch,
    };
    await _cacheBox.put(key, cacheEntry);
    AppLogger.d('Data cached: $key (ttl: ${effectiveTtl.inSeconds}s)');
  }

  /// 获取缓存数据（自动检查过期）
  ///
  /// [key] - 缓存键
  /// [defaultValue] - 默认值（缓存不存在或已过期时返回）
  T? getCachedData<T>(String key, {T? defaultValue}) {
    try {
      final cacheEntry = _cacheBox.get(key);
      if (cacheEntry == null || cacheEntry is! Map) return defaultValue;

      final expiresAt = cacheEntry['expiresAt'] as int?;

      if (expiresAt != null) {
        final expiryTime = DateTime.fromMillisecondsSinceEpoch(expiresAt);
        if (DateTime.now().isAfter(expiryTime)) {
          _cacheBox.delete(key).ignore();
          AppLogger.d('Cache expired: $key');
          return defaultValue;
        }
      }

      AppLogger.d('Cache hit: $key');
      return cacheEntry['value'] as T?;
    } catch (e) {
      AppLogger.e('Cache read failed: $key', error: e);
      return defaultValue;
    }
  }

  /// 缓存 API 响应数据（语义化封装）
  ///
  /// [endpoint] - API 端点标识
  /// [data] - 要缓存的数据
  /// [ttl] - 过期时间，默认 5 分钟
  Future<void> cacheApiResponse(
    String endpoint,
    dynamic data, {
    Duration? ttl,
  }) async {
    await cacheData('api_$endpoint', data, ttl: ttl);
  }

  /// 获取 API 缓存数据
  ///
  /// [endpoint] - API 端点标识
  /// 返回缓存的数据，如果不存在或已过期则返回 null
  T? getCachedApiResponse<T>(String endpoint) {
    return getCachedData<T>('api_$endpoint');
  }

  /// 缓存列表数据
  ///
  /// [key] - 缓存键
  /// [data] - 列表数据
  /// [ttl] - 过期时间，默认 10 分钟
  Future<void> cacheList(
    String key,
    List<dynamic> data, {
    Duration? ttl,
  }) async {
    await cacheData('list_$key', data, ttl: ttl ?? const Duration(minutes: 10));
  }

  /// 获取缓存的列表数据
  List<T>? getCachedList<T>(String key) {
    final data = getCachedData<List<dynamic>>('list_$key');
    return data?.cast<T>();
  }

  /// 删除特定缓存
  Future<void> removeCache(String key) async {
    await _cacheBox.delete(key);
    AppLogger.d('Cache removed: $key');
  }

  // ==================== 文件缓存（flutter_cache_manager）====================

  /// 缓存用户头像
  Future<File> cacheAvatar(String url, {Map<String, String>? headers}) async {
    final file = await AppCacheManagers.avatar.getSingleFile(url, headers: headers);
    AppLogger.d('Avatar cached: $url');
    return file;
  }

  /// 获取缓存的头像文件信息
  Future<FileInfo?> getAvatarFileInfo(String url) async {
    return AppCacheManagers.avatar.getFileFromCache(url);
  }

  /// 缓存服务相关图片
  Future<File> cacheServiceImage(String url, {Map<String, String>? headers}) async {
    final file = await AppCacheManagers.service.getSingleFile(url, headers: headers);
    AppLogger.d('Service image cached: $url');
    return file;
  }

  /// 缓存文档
  Future<File> cacheDocument(String url, {Map<String, String>? headers}) async {
    final file = await AppCacheManagers.document.getSingleFile(url, headers: headers);
    AppLogger.d('Document cached: $url');
    return file;
  }

  /// 缓存通用图片
  Future<File> cacheGeneralImage(String url, {Map<String, String>? headers}) async {
    final file = await AppCacheManagers.general.getSingleFile(url, headers: headers);
    AppLogger.d('General image cached: $url');
    return file;
  }

  /// 预加载图片列表
  Future<void> preloadImages(List<String> urls, {CacheManager? cacheManager}) async {
    final manager = cacheManager ?? AppCacheManagers.general;
    await Future.wait(urls.map(manager.downloadFile));
    AppLogger.i('Preloaded ${urls.length} images');
  }

  // ==================== 缓存管理 ====================

  /// 清理所有缓存（数据缓存 + 文件缓存）
  Future<void> clearAllCache() async {
    await _cacheBox.clear();
    await AppCacheManagers.clearAll();
    AppLogger.i('All cache cleared');
  }

  /// 清理过期的数据缓存，返回清理数量
  Future<int> clearExpiredCache() async {
    try {
      final keys = _cacheBox.keys.toList();
      var deletedCount = 0;

      for (final key in keys) {
        try {
          final cacheEntry = _cacheBox.get(key);
          if (cacheEntry is Map) {
            final expiresAt = cacheEntry['expiresAt'] as int?;
            if (expiresAt != null) {
              final expiryTime = DateTime.fromMillisecondsSinceEpoch(expiresAt);
              if (DateTime.now().isAfter(expiryTime)) {
                await _cacheBox.delete(key);
                deletedCount++;
              }
            }
          }
        } catch (e) {
          AppLogger.e('Failed to check cache entry: $key', error: e);
        }
      }

      if (deletedCount > 0) {
        AppLogger.i('Cleared $deletedCount expired cache entries');
      }
      return deletedCount;
    } catch (e) {
      AppLogger.e('Failed to clear expired cache', error: e);
      return 0;
    }
  }

  /// 清理特定类型的文件缓存
  Future<void> clearFileCache(String type) async {
    switch (type) {
      case 'avatar':
        await AppCacheManagers.avatar.emptyCache();
      case 'service':
        await AppCacheManagers.service.emptyCache();
      case 'document':
        await AppCacheManagers.document.emptyCache();
      case 'general':
        await AppCacheManagers.general.emptyCache();
      default:
        AppLogger.w('Unknown cache type: $type');
    }
  }

  /// 获取缓存统计信息（用于调试）
  Map<String, dynamic> getCacheStats() {
    try {
      return {
        'data_cache': {
          'total_keys': _cacheBox.keys.length,
        },
        'file_cache': AppCacheManagers.getCacheStats(),
      };
    } catch (e) {
      AppLogger.e('Failed to get cache stats', error: e);
      return {};
    }
  }
}
