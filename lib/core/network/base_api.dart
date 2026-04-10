import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_clean_arch_template/core/errors/error_utils.dart';
import 'package:flutter_clean_arch_template/core/errors/exceptions.dart';
import 'package:flutter_clean_arch_template/core/errors/failures.dart';
import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';
import 'package:flutter_clean_arch_template/core/network/api_client.dart';
import 'package:flutter_clean_arch_template/core/network/api_response_handler.dart';
import 'package:flutter_clean_arch_template/shared/models/api/api_response.dart';

/// 为请求参数添加时间戳
///
/// 用途：
/// - 防止缓存
/// - 确保请求的唯一性
void addTimestampToQueryParameters(Map<String, dynamic> data) {
  data['timestamp'] = DateTime.now().millisecondsSinceEpoch;
}

/// 基础 API 类
///
/// 提供统一的 API 调用模板方法，所有数据源类应继承此类
///
/// 功能：
/// - 统一的错误处理和转换
/// - 支持多种响应类型（对象、列表、分页、void等）
/// - 自动日志记录
/// - Either<Failure, T> 函数式错误处理
///
/// 使用示例：
/// ```dart
/// @Injectable()
/// class UserRemoteDataSource extends BaseAPI {
///   UserRemoteDataSource(super.apiClient);
///
///   // 获取用户信息（返回单个对象）
///   Future<Either<Failure, User>> getUser(String id) async {
///     return handleApiCall(
///       apiClient.get('/users/$id'),
///       User.fromJson,
///       logTag: 'UserRemoteDataSource.getUser',
///     );
///   }
///
///   // 获取用户列表
///   Future<Either<Failure, List<User>>> getUsers() async {
///     return handleApiListCall(
///       apiClient.get('/users'),
///       User.fromJson,
///       logTag: 'UserRemoteDataSource.getUsers',
///     );
///   }
///
///   // 删除用户（无返回数据）
///   Future<Either<Failure, void>> deleteUser(String id) async {
///     return handleApiVoidCall(
///       apiClient.delete('/users/$id'),
///       logTag: 'UserRemoteDataSource.deleteUser',
///     );
///   }
///
///   // 获取分页数据
///   Future<Either<Failure, PaginatedData<User>>> getUsersPaginated({
///     int page = 1,
///     int pageSize = 20,
///   }) async {
///     return handlePaginatedApiCall(
///       apiClient.get('/users', queryParameters: {
///         'page': page,
///         'pageSize': pageSize,
///       }),
///       User.fromJson,
///       logTag: 'UserRemoteDataSource.getUsersPaginated',
///     );
///   }
/// }
/// ```
abstract class BaseAPI {
  BaseAPI(this.apiClient);

  final ApiClient apiClient;

  /// 当前活跃的请求取消令牌映射
  final Map<String, CancelToken> _cancelTokens = {};

  /// 创建并存储一个请求取消令牌
  ///
  /// 用于需要取消功能的长时间请求
  /// ```dart
  /// final token = createCancelToken('upload_image');
  /// // ... 执行请求 ...
  /// // 需要取消时：cancelRequest('upload_image');
  /// ```
  CancelToken createCancelToken(String key) {
    final token = CancelToken();
    _cancelTokens[key] = token;
    return token;
  }

  /// 取消指定的请求
  ///
  /// [key] 请求标识，与 createCancelToken 中的 key 对应
  /// [reason] 取消原因（可选）
  void cancelRequest(String key, [String? reason]) {
    final token = _cancelTokens[key];
    if (token != null && !token.isCancelled) {
      token.cancel(reason ?? '请求已取消');
      _cancelTokens.remove(key);
      AppLogger.info('已取消请求: $key${reason != null ? " - $reason" : ""}');
    }
  }

  /// 取消所有活跃的请求
  void cancelAllRequests([String? reason]) {
    for (final entry in _cancelTokens.entries) {
      if (!entry.value.isCancelled) {
        entry.value.cancel(reason ?? '批量取消请求');
      }
    }
    _cancelTokens.clear();
    AppLogger.info('已取消所有活跃请求${reason != null ? ": $reason" : ""}');
  }

  /// 清理已完成的请求令牌
  void cleanupCancelToken(String key) {
    _cancelTokens.remove(key);
  }

  /// 处理标准API调用，返回单个数据对象
  Future<Either<Failure, T>> handleApiCall<T>(
    Future<Response<dynamic>> apiCall,
    T Function(Map<String, dynamic>) fromJson, {
    String? logTag,
  }) async {
    try {
      final response = await apiCall;
      return ApiResponseHandler.handleObjectResponse<T>(response, fromJson);
    } on AppException catch (e) {
      AppLogger.error('${logTag ?? runtimeType.toString()}: AppException caught', error: e);
      return Left(mapExceptionToFailure(e));
    } catch (e, stackTrace) {
      AppLogger.error(
        '${logTag ?? runtimeType.toString()}: Unexpected error',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  /// 处理返回列表数据的API调用
  Future<Either<Failure, List<T>>> handleApiListCall<T>(
    Future<Response<dynamic>> apiCall,
    T Function(Map<String, dynamic>) fromJson, {
    String? logTag,
  }) async {
    try {
      final response = await apiCall;

      return ApiResponseHandler.handleListResponse<T>(response, fromJson);
    } on AppException catch (e) {
      AppLogger.error('${logTag ?? runtimeType.toString()}: AppException caught', error: e);
      return Left(mapExceptionToFailure(e));
    } catch (e, stackTrace) {
      AppLogger.error(
        '${logTag ?? runtimeType.toString()}: Unexpected error',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  /// 处理无返回数据的API调用（如删除操作）
  Future<Either<Failure, void>> handleApiVoidCall(
    Future<Response<dynamic>> apiCall, {
    String? logTag,
  }) async {
    try {
      final response = await apiCall;

      return ApiResponseHandler.handleVoidResponse(response);
    } on AppException catch (e) {
      AppLogger.error('${logTag ?? runtimeType.toString()}: AppException caught', error: e);
      return Left(mapExceptionToFailure(e));
    } catch (e, stackTrace) {
      AppLogger.error(
        '${logTag ?? runtimeType.toString()}: Unexpected error',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  /// 处理分页API调用
  Future<Either<Failure, PaginatedData<T>>> handlePaginatedApiCall<T>(
    Future<Response<dynamic>> apiCall,
    T Function(Map<String, dynamic>) fromJson, {
    String? logTag,
    int? pageSize,
    int? page,
  }) async {
    try {
      final response = await apiCall;

      return ApiResponseHandler.handlePageableResponse<T>(response, fromJson);
    } on AppException catch (e) {
      AppLogger.error('${logTag ?? runtimeType.toString()}: AppException caught', error: e);
      return Left(mapExceptionToFailure(e));
    } catch (e, stackTrace) {
      AppLogger.error(
        '${logTag ?? runtimeType.toString()}: Unexpected error',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  /// 处理int响应
  Future<Either<Failure, int>> handleApiIntCall(
    Future<Response<dynamic>> apiCall, {
    String? logTag,
    String dataKey = 'data',
  }) async {
    try {
      final response = await apiCall;

      return ApiResponseHandler.handleIntResponse(response, dataKey: dataKey);
    } on AppException catch (e) {
      AppLogger.error('${logTag ?? runtimeType.toString()}: AppException caught', error: e);
      return Left(mapExceptionToFailure(e));
    } catch (e, stackTrace) {
      AppLogger.error(
        '${logTag ?? runtimeType.toString()}: Unexpected error',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  /// 处理布尔响应
  ///
  /// 适用于返回简单成功/失败状态的 API
  Future<Either<Failure, bool>> handleApiBoolCall(
    Future<Response<dynamic>> apiCall, {
    String? logTag,
  }) async {
    try {
      final response = await apiCall;

      return ApiResponseHandler.handleBooleanResponse(response);
    } on AppException catch (e) {
      AppLogger.error('${logTag ?? runtimeType.toString()}: AppException caught', error: e);
      return Left(mapExceptionToFailure(e));
    } catch (e, stackTrace) {
      AppLogger.error(
        '${logTag ?? runtimeType.toString()}: Unexpected error',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  /// 处理字符串响应
  ///
  /// 适用于返回 token、消息等字符串的 API
  Future<Either<Failure, String>> handleApiStringCall(
    Future<Response<dynamic>> apiCall, {
    String? logTag,
    String dataKey = 'data',
  }) async {
    try {
      final response = await apiCall;

      return ApiResponseHandler.handleStringResponse(response, dataKey: dataKey);
    } on AppException catch (e) {
      AppLogger.error('${logTag ?? runtimeType.toString()}: AppException caught', error: e);
      return Left(mapExceptionToFailure(e));
    } catch (e, stackTrace) {
      AppLogger.error(
        '${logTag ?? runtimeType.toString()}: Unexpected error',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}
