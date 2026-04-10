import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';
import 'package:flutter_clean_arch_template/core/network/token/token_storage.dart';
import 'package:flutter_clean_arch_template/core/network/token/token_strategy.dart';

/// 双 Token 策略
///
/// 管理 access token 和 refresh token，支持自动刷新
///
/// 特点：
/// - 使用短期 access token 和长期 refresh token
/// - 支持 JWT token 解析，获取过期时间
/// - 自动检测即将过期的 token 并提前刷新
/// - 支持无感刷新，提升用户体验
///
/// 刷新策略：
/// - 提前刷新：在 token 过期前 N 分钟自动刷新（默认 5 分钟）
/// - 失败处理：刷新失败时清除 token，触发重新登录
///
/// 适用场景：
/// - 需要高安全性的应用
/// - Token 有效期较短（如 1-2 小时）
/// - 需要无感刷新的用户体验
///
/// 使用示例：
/// ```dart
/// // 必须使用独立的 Dio 实例，不能与业务 Dio 共享，
/// // 否则刷新请求会被 AuthInterceptor 拦截，导致死锁。
/// final strategy = DualTokenStrategy(
///   tokenStorage: getIt<TokenStorage>(),
///   dio: Dio(BaseOptions(baseUrl: 'https://api.example.com')),
///   refreshEndpoint: '/auth/refresh',
///   refreshBeforeExpiry: Duration(minutes: 5),
/// );
/// ```
class DualTokenStrategy implements TokenStrategy {
  DualTokenStrategy({
    required TokenStorage tokenStorage,
    required Dio dio,
    required this.refreshEndpoint,
    this.refreshBeforeExpiry = const Duration(minutes: 5),
    this.accessTokenField = 'access_token',
    this.refreshTokenField = 'refresh_token',
    this.codeField = 'code',
    this.onAuthExpired,
  }) : _tokenStorage = tokenStorage,
       _dio = dio {
    assert(
      dio.interceptors.whereType<InterceptorsWrapper>().isEmpty ||
          !dio.interceptors.any((i) => i.runtimeType.toString().contains('Auth')),
      'DualTokenStrategy 的 Dio 实例不应挂载 AuthInterceptor，'
      '否则刷新请求会被拦截导致死锁',
    );
  }

  final TokenStorage _tokenStorage;
  final Dio _dio;

  /// 刷新 token 的 API 端点
  final String refreshEndpoint;

  /// 提前多久刷新 token（默认提前 5 分钟）
  final Duration refreshBeforeExpiry;

  /// 刷新响应中 access token 的字段名
  final String accessTokenField;

  /// 刷新响应中 refresh token 的字段名
  final String refreshTokenField;

  /// 刷新响应中 code 的字段名
  final String codeField;

  /// 认证过期回调，仅在确认需要重新登录时调用（refresh token 过期/不存在）
  final TokenAuthExpiredCallback? onAuthExpired;

  @override
  String get name => 'DualToken';

  @override
  bool get supportsRefresh => true;

  /// Token 过期时间（从 JWT payload 解析，避免每次都解析 JWT）
  DateTime? _tokenExpiryTime;

  @override
  Future<String?> getAccessToken() async {
    final token = await _tokenStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      _tokenExpiryTime ??= _parseTokenExpiry(token);
      return token;
    }
    return null;
  }

  @override
  Future<void> saveAccessToken({
    required String accessToken,
    String? refreshToken,
  }) async {
    _tokenExpiryTime = _parseTokenExpiry(accessToken);

    if (_tokenExpiryTime != null) {
      final now = DateTime.now();
      final expiresIn = _tokenExpiryTime!.difference(now);
      AppLogger.info(
        '[$name] Token 将在 ${expiresIn.inMinutes} 分钟后过期 '
        '(${_tokenExpiryTime!.toLocal()})',
      );
    }

    await _tokenStorage.saveAccessToken(accessToken);

    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _tokenStorage.saveRefreshToken(refreshToken);
      AppLogger.info('[$name] Access token 和 refresh token 已保存');
    } else {
      AppLogger.warning('[$name] 未提供 refresh token');
    }
  }

  @override
  Future<void> clearToken() async {
    _tokenExpiryTime = null;
    await _tokenStorage.clearAll();
  }

  @override
  Future<bool> isTokenExpired() async {
    if (_tokenExpiryTime == null) {
      final token = await getAccessToken();
      if (token != null) {
        _tokenExpiryTime = _parseTokenExpiry(token);
      }
    }

    if (_tokenExpiryTime == null) {
      AppLogger.debug('[$name] 无法获取 token 过期时间，假设未过期');
      return false;
    }

    final isExpired = DateTime.now().isAfter(_tokenExpiryTime!);
    if (isExpired) {
      AppLogger.warning('[$name] Token 已过期');
    }

    return isExpired;
  }

  @override
  bool shouldRefresh() {
    // _tokenExpiryTime 在 getAccessToken() 中懒初始化，
    // TokenManager.getValidToken() 保证先调用 getAccessToken() 再调用 shouldRefresh()
    if (_tokenExpiryTime == null) {
      return false;
    }

    final refreshTime = _tokenExpiryTime!.subtract(refreshBeforeExpiry);
    final should = DateTime.now().isAfter(refreshTime);

    if (should) {
      final minutesLeft = _tokenExpiryTime!.difference(DateTime.now()).inMinutes;
      AppLogger.info('[$name] Token 将在 $minutesLeft 分钟后过期，需要刷新');
    }

    return should;
  }

  @override
  Future<String?> refreshToken() async {
    AppLogger.info('[$name] 开始刷新 token...');

    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        AppLogger.error('[$name] 未找到 refresh token');
        onAuthExpired?.call('Refresh token 不存在，请重新登录');
        return null;
      }

      final response = await _dio.post<Map<String, dynamic>>(
        refreshEndpoint,
        data: {refreshTokenField: refreshToken},
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode != 200 || response.data == null) {
        AppLogger.error('[$name] 刷新 token 失败: 状态码 ${response.statusCode}');
        return null;
      }

      final data = response.data!;
      final newAccessToken = data[accessTokenField] as String?;
      final newRefreshToken = data[refreshTokenField] as String?;
      final rawCode = data[codeField];
      // final code = switch (rawCode) {
      //   final int v => v,
      //   final String v => int.tryParse(v),
      //   _ => null,
      // };

      // final code = rawCode is int
      //     ? rawCode
      //     : rawCode is String
      //     ? int.tryParse(rawCode)
      //     : null;

      int? code;
      if (rawCode case final int v) {
        code = v;
      } else if (rawCode case final String v) {
        code = int.tryParse(v);
      } else {
        code = null;
      }

      if (code == 401) {
        AppLogger.error('[$name] 刷新响应返回 401，refresh token 已过期');
        await clearToken();
        onAuthExpired?.call('Refresh token 已过期，请重新登录');
        return null;
      }

      if (newAccessToken == null || newAccessToken.isEmpty) {
        AppLogger.error('[$name] 响应中未包含新的 access token');
        return null;
      }

      await saveAccessToken(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken ?? refreshToken,
      );

      AppLogger.info('[$name] Token 刷新成功');
      return newAccessToken;
    } on DioException catch (e) {
      AppLogger.error(
        '[$name] 刷新 token 失败 (DioException): ${e.type} - ${e.message}',
        error: e,
      );

      if (e.response?.statusCode == 401) {
        AppLogger.warning('[$name] Refresh token 已过期，需要重新登录');
        await clearToken();
        onAuthExpired?.call('Refresh token 已过期，请重新登录');
      }

      return null;
    } catch (e, stackTrace) {
      AppLogger.error(
        '[$name] 刷新 token 时发生意外错误',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// 解析 JWT token 获取过期时间
  ///
  /// JWT token 格式：header.payload.signature
  /// payload 中包含 exp 字段（Unix 时间戳，秒）
  DateTime? _parseTokenExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        AppLogger.debug('[$name] Token 格式不正确，不是标准 JWT');
        return null;
      }

      var payload = parts[1];
      switch (payload.length % 4) {
        case 0:
          break;
        case 2:
          payload += '==';
        case 3:
          payload += '=';
        default:
          AppLogger.warning('[$name] Token payload Base64 长度无效');
          return null;
      }

      payload = payload.replaceAll('-', '+').replaceAll('_', '/');

      final jsonString = utf8.decode(base64.decode(payload));
      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      final exp = json['exp'];
      if (exp == null) {
        AppLogger.debug('[$name] Token 中未包含 exp 字段');
        return null;
      }

      final expSeconds = switch (exp) {
        final int value => value,
        final num value => value.toInt(),
        final String value => int.tryParse(value),
        _ => null,
      };

      if (expSeconds == null) {
        AppLogger.debug('[$name] Token exp 字段格式不正确: ${exp.runtimeType}');
        return null;
      }

      final expiryTime = DateTime.fromMillisecondsSinceEpoch(
        expSeconds * 1000,
        isUtc: true,
      );

      return expiryTime;
    } catch (e) {
      AppLogger.warning('[$name] 解析 token 过期时间失败: $e');
      return null;
    }
  }
}
