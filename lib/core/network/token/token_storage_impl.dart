import 'package:injectable/injectable.dart';
import 'package:flutter_clean_arch_template/core/constants/storage_keys.dart';
import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';
import 'package:flutter_clean_arch_template/core/network/token/token_storage.dart';
import 'package:flutter_clean_arch_template/core/storage/local/secure_storage_service.dart' show SecureStorageService;
import 'package:flutter_clean_arch_template/core/storage/storage_service.dart';

/// Token 安全存储实现
///
/// 使用 [SecureStorageService] 安全存储 access token 和 refresh token。
///
/// 内部维护内存缓存，避免每次请求都执行 Secure Storage I/O（约 1-5ms/次）。
/// 缓存在 [saveAccessToken]、[clearAccessToken] 等写操作时同步更新，保证一致性。
/// 首次读取（冷启动）仍从 Secure Storage 加载，后续读取走内存。
@Singleton(as: TokenStorage)
class TokenStorageImpl implements TokenStorage {
  TokenStorageImpl(this._storageService);

  final StorageService _storageService;

  /// 内存缓存，null 表示尚未从 Secure Storage 加载
  String? _cachedAccessToken;
  String? _cachedRefreshToken;
  bool _accessTokenLoaded = false;
  bool _refreshTokenLoaded = false;

  @override
  Future<String?> getAccessToken() async {
    if (_accessTokenLoaded) {
      return _cachedAccessToken;
    }

    try {
      final token = await _storageService.secure.read(StorageKeys.userTokenKey);
      _cachedAccessToken = (token != null && token.isNotEmpty) ? token : null;
      _accessTokenLoaded = true;

      return _cachedAccessToken;
    } catch (e) {
      AppLogger.e('[TokenStorage] 获取 access token 失败', error: e, stackTrace: StackTrace.current);
      return null;
    }
  }

  @override
  Future<void> saveAccessToken(String token) async {
    await _storageService.secure.write(StorageKeys.userTokenKey, token);
    _cachedAccessToken = token;
    _accessTokenLoaded = true;
  }

  @override
  Future<void> clearAccessToken() async {
    await _storageService.secure.delete(StorageKeys.userTokenKey);
    _cachedAccessToken = null;
    _accessTokenLoaded = true;
  }

  @override
  Future<String?> getRefreshToken() async {
    if (_refreshTokenLoaded) {
      return _cachedRefreshToken;
    }

    try {
      final refreshToken = await _storageService.secure.read(StorageKeys.refreshTokenKey);
      _cachedRefreshToken = (refreshToken != null && refreshToken.isNotEmpty) ? refreshToken : null;
      _refreshTokenLoaded = true;

      return _cachedRefreshToken;
    } catch (e) {
      AppLogger.e('[TokenStorage] 获取 refresh token 失败', error: e, stackTrace: StackTrace.current);
      return null;
    }
  }

  @override
  Future<void> saveRefreshToken(String refreshToken) async {
    await _storageService.secure.write(StorageKeys.refreshTokenKey, refreshToken);
    _cachedRefreshToken = refreshToken;
    _refreshTokenLoaded = true;
  }

  @override
  Future<void> clearRefreshToken() async {
    await _storageService.secure.delete(StorageKeys.refreshTokenKey);
    _cachedRefreshToken = null;
    _refreshTokenLoaded = true;
  }

  @override
  Future<void> clearAll() async {
    await clearAccessToken();
    await clearRefreshToken();
  }
}
