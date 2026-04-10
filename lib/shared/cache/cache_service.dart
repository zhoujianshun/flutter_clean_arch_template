import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';
import 'package:flutter_clean_arch_template/core/storage/local/hive_service.dart';
import 'package:flutter_clean_arch_template/shared/cache/app_cache_managers.dart';

/// 统一缓存服务
///
/// 职责：管理临时数据和文件缓存
/// - API 响应缓存
/// - 列表数据缓存
/// - 图片文件缓存
/// - 文档文件缓存
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
  CacheService(this._hiveService);

  final HiveService _hiveService;

  // ==================== 数据缓存（使用 Hive cache_box）====================

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
    await _hiveService.putCacheWithTTL(
      key,
      data,
      ttl: ttl ?? const Duration(minutes: 5),
    );
    AppLogger.d('Data cached: $key');
  }

  /// 获取缓存数据（通用方法）
  ///
  /// [key] - 缓存键
  /// [defaultValue] - 默认值（缓存不存在或已过期时返回）
  T? getCachedData<T>(String key, {T? defaultValue}) {
    final data = _hiveService.getCacheWithTTL<T>(key, defaultValue: defaultValue);
    if (data != null) {
      AppLogger.d('Cache hit: $key');
    } else {
      AppLogger.d('Cache miss: $key');
    }
    return data;
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

  // ==================== 文件缓存（使用 flutter_cache_manager）====================

  /// 缓存用户头像
  ///
  /// [url] - 头像 URL
  /// [headers] - 可选的 HTTP 请求头（如 token）
  Future<File> cacheAvatar(String url, {Map<String, String>? headers}) async {
    final file = await AppCacheManagers.avatar.getSingleFile(
      url,
      headers: headers,
    );
    AppLogger.d('Avatar cached: $url');
    return file;
  }

  /// 获取缓存的头像文件信息
  Future<FileInfo?> getAvatarFileInfo(String url) async {
    return AppCacheManagers.avatar.getFileFromCache(url);
  }

  /// 缓存服务相关图片
  ///
  /// [url] - 图片 URL
  /// [headers] - 可选的 HTTP 请求头
  Future<File> cacheServiceImage(
    String url, {
    Map<String, String>? headers,
  }) async {
    final file = await AppCacheManagers.service.getSingleFile(
      url,
      headers: headers,
    );
    AppLogger.d('Service image cached: $url');
    return file;
  }

  /// 缓存文档
  ///
  /// [url] - 文档 URL
  /// [headers] - 可选的 HTTP 请求头
  Future<File> cacheDocument(String url, {Map<String, String>? headers}) async {
    final file = await AppCacheManagers.document.getSingleFile(
      url,
      headers: headers,
    );
    AppLogger.d('Document cached: $url');
    return file;
  }

  /// 缓存通用图片
  ///
  /// [url] - 图片 URL
  /// [headers] - 可选的 HTTP 请求头
  Future<File> cacheGeneralImage(
    String url, {
    Map<String, String>? headers,
  }) async {
    final file = await AppCacheManagers.general.getSingleFile(
      url,
      headers: headers,
    );
    AppLogger.d('General image cached: $url');
    return file;
  }

  /// 预加载图片列表
  ///
  /// 适合在进入页面前预加载关键图片
  Future<void> preloadImages(
    List<String> urls, {
    CacheManager? cacheManager,
  }) async {
    final manager = cacheManager ?? AppCacheManagers.general;
    await Future.wait(
      urls.map(manager.downloadFile),
    );
    AppLogger.i('Preloaded ${urls.length} images');
  }

  // ==================== 缓存管理 ====================

  /// 清理所有缓存（包括数据缓存和文件缓存）
  Future<void> clearAllCache() async {
    await _hiveService.clearCache();
    await AppCacheManagers.clearAll();
  }

  /// 清理过期的数据缓存
  Future<int> clearExpiredCache() async {
    return _hiveService.clearExpiredCache();
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

  /// 获取缓存统计信息
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      // 直接从 HiveService 获取缓存信息
      final cacheKeys = _hiveService.getKeys('cache_box').length;
      final fileCacheStats = await AppCacheManagers.getCacheStats();

      return {
        'data_cache': {
          'hive_cache_keys': cacheKeys,
        },
        'file_cache': fileCacheStats,
      };
    } catch (e) {
      AppLogger.e('Failed to get cache stats', error: e);
      return {};
    }
  }
}
