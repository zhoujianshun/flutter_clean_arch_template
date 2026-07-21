import 'package:dio/dio.dart';
import 'package:flutter_clean_arch_template/core/errors/exceptions.dart';
import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';
import 'package:flutter_clean_arch_template/core/network/interceptors/auth_interceptor.dart';
import 'package:flutter_clean_arch_template/core/network/interceptors/connectivity_interceptor.dart';
import 'package:flutter_clean_arch_template/core/network/interceptors/retry_interceptor.dart';
import 'package:flutter_clean_arch_template/core/network/log_sanitizer.dart';
import 'package:flutter_clean_arch_template/core/network/network_info.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';

/// API客户端 - 统一网络请求管理
///
/// 负责所有网络请求的统一管理，包括：
/// - 基础配置（超时、Headers等）
/// - 拦截器管理（认证、日志、连接检测、重试等）
/// - 请求方法封装（GET、POST、PUT、DELETE等）
/// - 文件上传下载
///
/// 配置选项：
/// - enableRetry: 是否启用自动重试机制（默认 false）
/// - maxRetries: 最大重试次数（默认 3）
/// - retryDelay: 基础重试延迟（默认 1 秒）
/// - enableConnectivityCheck: 是否启用网络连接检测（默认 true）
class ApiClient {
  ApiClient(
    BaseOptions options, {
    TalkerDioLogger? dioLogger,
    NetworkInfo? networkInfo,
    this.enableRetry = false,
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
    this.enableConnectivityCheck = true,
  }) : _dioLogger = dioLogger,
       _networkInfo = networkInfo ?? NetworkInfo() {
    _dio = Dio();
    _setupDio(options);
  }

  late final Dio _dio;
  final TalkerDioLogger? _dioLogger;
  final NetworkInfo _networkInfo;

  /// 是否启用自动重试
  final bool enableRetry;

  /// 最大重试次数
  final int maxRetries;

  /// 基础重试延迟
  final Duration retryDelay;

  /// 是否启用网络连接检测
  final bool enableConnectivityCheck;

  Dio get dio => _dio;

  /// 配置Dio实例
  void _setupDio(BaseOptions options) {
    // 基础配置：保留外部传入 options，仅补默认 header
    final mergedHeaders = <String, dynamic>{...options.headers};
    if (!_containsHeaderIgnoreCase(mergedHeaders, 'Content-Type')) {
      mergedHeaders['Content-Type'] = 'application/json';
    }
    if (!_containsHeaderIgnoreCase(mergedHeaders, 'Accept')) {
      mergedHeaders['Accept'] = 'application/json';
    }
    _dio.options = options.copyWith(headers: mergedHeaders);

    // 添加拦截器
    _setupInterceptors();
  }

  bool _containsHeaderIgnoreCase(Map<String, dynamic> headers, String key) {
    final lowerKey = key.toLowerCase();
    return headers.keys.any((headerKey) => headerKey.toLowerCase() == lowerKey);
  }

  /// 设置拦截器
  ///
  /// 拦截器执行顺序（按添加顺序）：
  /// 1. DioInstanceInterceptor - 存储 Dio 实例引用（供 RetryInterceptor 使用）
  /// 2. ConnectivityInterceptor - 检查网络连接状态（可选）
  /// 3. AuthInterceptor - 添加认证信息和处理认证失败
  /// 4. TalkerDioLogger - 记录请求日志（仅开发环境）
  /// 5. RetryInterceptor - 自动重试失败的请求（可选）
  void _setupInterceptors() {
    // 0. 请求预处理拦截器 - 注入 Dio 实例引用和 requestId
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.extra['dio_instance'] = _dio;
          options.extra['requestId'] ??= LogSanitizer.generateRequestId();
          handler.next(options);
        },
      ),
    );

    // 1. 连接检测拦截器 - 请求前检查网络状态（可选）
    if (enableConnectivityCheck) {
      _dio.interceptors.add(
        ConnectivityInterceptor(
          networkInfo: _networkInfo,
        ),
      );
    }

    // 2. 认证拦截器 - 添加认证token和处理认证失败
    _dio.interceptors.add(AuthInterceptor());

    // 3. 日志拦截器 - 使用 TalkerDioLogger（仅开发环境）
    if (_dioLogger != null) {
      _dio.interceptors.add(_dioLogger);
    }

    // 4. 重试拦截器 - 自动重试失败的请求（可选）
    if (enableRetry) {
      _dio.interceptors.add(
        RetryInterceptor(
          maxRetries: maxRetries,
          retryDelay: retryDelay,
        ),
      );
      AppLogger.info('已启用自动重试功能: maxRetries=$maxRetries, retryDelay=${retryDelay.inMilliseconds}ms');
    }
  }

  /// 统一请求执行，集中 DioException → AppException 转换
  Future<Response<T>> _request<T>(
    Future<Response<T>> Function() action,
  ) async {
    try {
      return await action();
    } on DioException catch (e) {
      throw DioErrorHandler.handleDioError(e);
    }
  }

  /// GET请求
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) => _request(() => _dio.get<T>(path, queryParameters: queryParameters, options: options, cancelToken: cancelToken));

  /// POST请求
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) => _request(() => _dio.post<T>(path, data: data, queryParameters: queryParameters, options: options, cancelToken: cancelToken));

  /// PUT请求
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) => _request(() => _dio.put<T>(path, data: data, queryParameters: queryParameters, options: options, cancelToken: cancelToken));

  /// DELETE请求
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) => _request(() => _dio.delete<T>(path, data: data, queryParameters: queryParameters, options: options, cancelToken: cancelToken));

  /// 上传文件
  Future<Response<T>> uploadFile<T>(
    String path,
    String filePath, {
    String? fileName,
    Map<String, dynamic>? data,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) => _request(() async {
    final file = await MultipartFile.fromFile(filePath, filename: fileName);
    final formData = FormData.fromMap({'file': file, ...?data});
    return _dio.post<T>(
      path,
      data: formData,
      onSendProgress: onSendProgress,
      cancelToken: cancelToken,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
    );
  });

  /// 下载文件
  Future<Response<dynamic>> downloadFile(
    String urlPath,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
  }) => _request(() => _dio.download(urlPath, savePath, onReceiveProgress: onReceiveProgress, cancelToken: cancelToken));
}

/// Dio错误处理
class DioErrorHandler {
  /// 处理Dio错误
  static AppException handleDioError(DioException error) {
    final requestId = error.requestOptions.extra['requestId'] as String? ?? 'unknown';
    final sanitizedHeaders = LogSanitizer.sanitizeHeaders(error.requestOptions.headers);
    final sanitizedBody = LogSanitizer.sanitizeBody(error.response?.data);

    AppLogger.error(
      '[$requestId] Dio错误 '
      '[${error.requestOptions.method}] ${error.requestOptions.uri} '
      '| type=${error.type} '
      '| status=${error.response?.statusCode} '
      '| message=${error.message}',
    );
    AppLogger.debug('[$requestId] 请求头: $sanitizedHeaders');
    AppLogger.debug('[$requestId] 响应数据: $sanitizedBody');

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          message: '网络连接超时，请检查网络设置',
          code: error.response?.statusCode,
        );

      case DioExceptionType.badResponse:
        return _handleResponseError(error);

      case DioExceptionType.cancel:
        return NetworkException(
          message: '请求已取消',
          code: error.response?.statusCode,
        );

      case DioExceptionType.connectionError:
        return NetworkException(
          message: '网络连接失败，请检查网络设置',
          code: error.response?.statusCode,
        );

      case DioExceptionType.badCertificate:
        return NetworkException(
          message: '证书验证失败',
          code: error.response?.statusCode,
        );

      case DioExceptionType.unknown:
        return NetworkException(
          message: '未知网络错误: ${error.message}',
          code: error.response?.statusCode,
        );
    }
  }

  /// 处理响应错误
  static AppException _handleResponseError(DioException error) {
    final statusCode = error.response?.statusCode;
    final message = _getErrorMessage(error.response?.data);

    switch (statusCode) {
      case 400:
        return ValidationException(
          message: message ?? '请求参数错误',
          code: statusCode,
        );

      case 401:
        return AuthException(
          message: message ?? '未授权访问，请重新登录',
          code: statusCode,
        );

      case 403:
        return PermissionException(
          message: message ?? '权限不足，无法访问',
          code: statusCode,
        );

      case 404:
        return ServerException(
          message: message ?? '请求的资源不存在',
          code: statusCode,
        );

      case 422:
        return ValidationException(
          message: message ?? '数据验证失败',
          code: statusCode,
        );

      case 500:
        return ServerException(
          message: message ?? '服务器内部错误',
          code: statusCode,
        );

      case 502:
      case 503:
      case 504:
        return ServerException(
          message: message ?? '服务器暂时不可用，请稍后重试',
          code: statusCode,
        );

      default:
        return ServerException(
          message: message ?? '服务器错误 ($statusCode)',
          code: statusCode,
        );
    }
  }

  /// 从响应数据中提取错误信息
  ///
  /// 仅从 Map 结构中提取已知字段，避免将完整响应体（可能含敏感数据）暴露到错误消息。
  static String? _getErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['message']?.toString() ?? data['error']?.toString() ?? data['msg']?.toString();
    }
    if (data is String && data.length <= 200) {
      return data;
    }
    return null;
  }
}
