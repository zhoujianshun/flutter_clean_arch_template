import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// 应用文件缓存管理器配置
///
/// 为不同类型的资源提供专用的缓存管理器实例（单例）。
/// 每个管理器有独立的过期策略和容量限制。
class AppCacheManagers {
  AppCacheManagers._();

  /// 用户头像缓存管理器
  ///
  /// - 长期缓存（30天）
  /// - 较多数量（500个）
  /// - 小文件优化
  static final CacheManager avatar = CacheManager(
    Config(
      'avatar_cache',
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 500,
      repo: JsonCacheInfoRepository(databaseName: 'avatar_cache'),
      fileService: HttpFileService(),
    ),
  );

  /// 服务相关图片缓存管理器
  ///
  /// - 中期缓存（7天）
  /// - 中等数量（200个）
  /// - 适合订单照片、服务现场照片等
  static final CacheManager service = CacheManager(
    Config(
      'service_cache',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 200,
      repo: JsonCacheInfoRepository(databaseName: 'service_cache'),
      fileService: HttpFileService(),
    ),
  );

  /// 文档缓存管理器
  ///
  /// - 长期缓存（30天）
  /// - 较少数量（50个）
  /// - 适合协议、培训文档等
  static final CacheManager document = CacheManager(
    Config(
      'document_cache',
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 50,
      repo: JsonCacheInfoRepository(databaseName: 'document_cache'),
      fileService: HttpFileService(),
    ),
  );

  /// 通用图片缓存管理器
  ///
  /// - 短期缓存（3天）
  /// - 中等数量（100个）
  /// - 适合临时图片、公告图片等
  static final CacheManager general = CacheManager(
    Config(
      'general_cache',
      stalePeriod: const Duration(days: 3),
      maxNrOfCacheObjects: 100,
      repo: JsonCacheInfoRepository(databaseName: 'general_cache'),
      fileService: HttpFileService(),
    ),
  );

  /// 清理所有文件缓存
  static Future<void> clearAll() async {
    await Future.wait([
      avatar.emptyCache(),
      service.emptyCache(),
      document.emptyCache(),
      general.emptyCache(),
    ]);
  }

  /// 获取文件缓存配置信息（用于调试）
  static Map<String, dynamic> getCacheStats() {
    return {
      'avatar': {'max_count': 500, 'stale_period_days': 30},
      'service': {'max_count': 200, 'stale_period_days': 7},
      'document': {'max_count': 50, 'stale_period_days': 30},
      'general': {'max_count': 100, 'stale_period_days': 3},
    };
  }
}
