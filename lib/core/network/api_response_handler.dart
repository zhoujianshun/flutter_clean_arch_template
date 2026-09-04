import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_clean_arch_template/core/errors/error_utils.dart';
import 'package:flutter_clean_arch_template/core/errors/failures.dart';
import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';
import 'package:flutter_clean_arch_template/shared/models/api/api_response.dart';

/// API响应处理工具类
///
/// 提供统一的 API 响应处理方法，支持多种数据类型：
/// - 单个对象 (handleObjectResponse)
/// - 列表数据 (handleListResponse)
/// - 分页数据 (handlePageableResponse)
/// - 无返回数据 (handleVoidResponse)
/// - 布尔值 (handleBooleanResponse)
/// - 字符串 (handleStringResponse)
/// - 整数 (handleIntResponse)
/// - 原始数据 (handleRawResponse)
/// - 批量结果 (handleBatchResponse)
///
/// 所有方法都返回 `Either<Failure, T>` 类型，便于函数式错误处理
class ApiResponseHandler {
  /// 处理单个对象响应
  static Either<Failure, T> handleObjectResponse<T>(
    Response<dynamic> response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    try {
      if (response.data == null) {
        return const Left(ServerFailure(message: '响应数据为空'));
      }

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json! as Map<String, dynamic>,
      );

      if (apiResponse.isSuccess && apiResponse.hasData) {
        try {
          final data = fromJson(apiResponse.data!);
          return Right(data);
        } catch (e) {
          AppLogger.error('数据解析失败', error: e);
          return Left(ServerFailure(message: '数据解析失败: $e'));
        }
      } else {
        return Left(_mapApiResponseToFailure(apiResponse));
      }
    } catch (e) {
      AppLogger.error('对象响应处理失败', error: e);
      return Left(ServerFailure(message: '对象响应处理失败: $e'));
    }
  }

  /// 处理列表响应
  static Either<Failure, List<T>> handleListResponse<T>(
    Response<dynamic> response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    try {
      if (response.data == null) {
        return const Left(ServerFailure(message: '响应数据为空'));
      }

      final apiResponse = ApiResponse<List<dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json! as List<dynamic>,
      );

      if (apiResponse.isSuccess && apiResponse.hasData) {
        try {
          final dataList = apiResponse.data!
              .cast<Map<String, dynamic>>()
              .map((json) => fromJson(json))
              .toList();
          return Right(dataList);
        } catch (e) {
          AppLogger.error('列表数据解析失败', error: e);
          return Left(ServerFailure(message: '列表数据解析失败: $e'));
        }
      } else {
        return Left(_mapApiResponseToFailure(apiResponse));
      }
    } catch (e) {
      AppLogger.error('列表响应处理失败', error: e);
      return Left(ServerFailure(message: '列表响应处理失败: $e'));
    }
  }

  /// 处理无返回数据的响应
  static Either<Failure, void> handleVoidResponse(Response<dynamic> response) {
    try {
      if (response.data == null) {
        // 对于void调用，如果状态码是成功的，即使没有数据也认为成功
        if (response.statusCode != null &&
            response.statusCode! >= 200 &&
            response.statusCode! < 300) {
          return const Right(null);
        }
        return const Left(ServerFailure(message: '请求失败'));
      }

      final apiResponse = ApiResponse<dynamic>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json,
      );

      if (apiResponse.isSuccess) {
        return const Right(null);
      } else {
        return Left(_mapApiResponseToFailure(apiResponse));
      }
    } catch (e) {
      AppLogger.error('Void响应处理失败', error: e);
      return Left(ServerFailure(message: '响应处理失败: $e'));
    }
  }

  /// 处理简单的布尔响应（如成功/失败操作）
  static Either<Failure, bool> handleBooleanResponse(
    Response<dynamic> response,
  ) {
    try {
      if (response.data == null) {
        // 如果没有响应体，根据状态码判断
        if (response.statusCode != null &&
            response.statusCode! >= 200 &&
            response.statusCode! < 300) {
          return const Right(true);
        }
        return const Left(ServerFailure(message: '请求失败'));
      }

      final apiResponse = ApiResponse<bool>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as bool? ?? true,
      );

      if (apiResponse.isSuccess) {
        return Right(apiResponse.data ?? true);
      } else {
        return Left(_mapApiResponseToFailure(apiResponse));
      }
    } catch (e) {
      AppLogger.error('布尔响应处理失败', error: e);
      return Left(ServerFailure(message: '响应处理失败: $e'));
    }
  }

  /// 处理字符串响应（如token、消息等）
  static Either<Failure, String> handleStringResponse(
    Response<dynamic> response, {
    String dataKey = 'data',
  }) {
    try {
      if (response.data == null) {
        return const Left(ServerFailure(message: '响应数据为空'));
      }

      final apiResponse = ApiResponse<dynamic>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json,
      );

      if (apiResponse.isSuccess && apiResponse.hasData) {
        String result;
        if (apiResponse.data is String) {
          result = apiResponse.data as String;
        } else if (apiResponse.data is Map<String, dynamic>) {
          final data = apiResponse.data as Map<String, dynamic>;
          result = data[dataKey]?.toString() ?? '';
        } else {
          result = apiResponse.data.toString();
        }

        return Right(result);
      } else {
        return Left(_mapApiResponseToFailure(apiResponse));
      }
    } catch (e) {
      AppLogger.error('字符串响应处理失败', error: e);
      return Left(ServerFailure(message: '响应处理失败: $e'));
    }
  }

  /// 处理数字响应（如ID、计数等）
  static Either<Failure, int> handleIntResponse(
    Response<dynamic> response, {
    String dataKey = 'data',
  }) {
    try {
      if (response.data == null) {
        return const Left(ServerFailure(message: '响应数据为空'));
      }

      final apiResponse = ApiResponse<dynamic>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json,
      );

      if (apiResponse.isSuccess && apiResponse.hasData) {
        final parsed = _tryParseInt(apiResponse.data, dataKey);
        if (parsed != null) {
          return Right(parsed);
        }
        AppLogger.error(
          '数字响应解析失败: 无法从 ${apiResponse.data.runtimeType} 中提取 int',
        );
        return const Left(ServerFailure(message: '数字响应解析失败: 数据类型不匹配'));
      } else {
        return Left(_mapApiResponseToFailure(apiResponse));
      }
    } catch (e) {
      AppLogger.error('数字响应处理失败', error: e);
      return Left(ServerFailure(message: '响应处理失败: $e'));
    }
  }

  /// 处理原始数据响应（不进行ApiResponse包装解析）
  static Either<Failure, T> handleRawResponse<T>(
    Response<dynamic> response,
    T Function(dynamic) fromJson,
  ) {
    try {
      if (response.data == null) {
        return const Left(ServerFailure(message: '响应数据为空'));
      }

      // 检查HTTP状态码
      if (response.statusCode == null ||
          response.statusCode! < 200 ||
          response.statusCode! >= 300) {
        return Left(
          ServerFailure(
            message: '请求失败',
            code: response.statusCode ?? 500,
          ),
        );
      }

      final data = fromJson(response.data);
      return Right(data);
    } catch (e) {
      AppLogger.error('原始响应处理失败', error: e);
      return Left(ServerFailure(message: '响应处理失败: $e'));
    }
  }

  /// 处理分页响应 - 使用新的 PageableData 结构
  static Either<Failure, PaginatedData<T>> handlePageableResponse<T>(
    Response<dynamic> response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    try {
      if (response.data == null) {
        return const Left(ServerFailure(message: '响应数据为空'));
      }

      // 使用智能解析来自动识别分页数据
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json! as Map<String, dynamic>,
      );

      if (apiResponse.isSuccess && apiResponse.hasData) {
        final pageableData = apiResponse.data!;
        final paginatedResponse = PaginatedData<T>.fromJson(
          pageableData,
          (json) => fromJson(json! as Map<String, dynamic>),
        );
        return Right(paginatedResponse);
      } else {
        return Left(_mapApiResponseToFailure(apiResponse));
      }
    } catch (e) {
      AppLogger.error('分页响应处理失败', error: e);
      return Left(ServerFailure(message: '分页响应处理失败: $e'));
    }
  }

  /// 批量处理响应结果
  static Either<Failure, List<Either<Failure, T>>> handleBatchResponse<T>(
    Response<dynamic> response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    try {
      if (response.data == null) {
        return const Left(ServerFailure(message: '批量响应数据为空'));
      }

      final apiResponse = ApiResponse<List<dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json! as List<dynamic>,
      );

      if (apiResponse.isSuccess && apiResponse.hasData) {
        final results = <Either<Failure, T>>[];

        for (final item in apiResponse.data!) {
          try {
            if (item is Map<String, dynamic>) {
              final data = fromJson(item);
              results.add(Right(data));
            } else {
              results.add(const Left(ServerFailure(message: '无效的数据格式')));
            }
          } catch (e) {
            results.add(Left(ServerFailure(message: '数据解析失败: $e')));
          }
        }

        return Right(results);
      } else {
        return Left(_mapApiResponseToFailure(apiResponse));
      }
    } catch (e) {
      AppLogger.error('批量响应处理失败', error: e);
      return Left(ServerFailure(message: '批量响应处理失败: $e'));
    }
  }

  /// 尝试从动态数据中解析出 int 值
  ///
  /// 返回 null 表示解析失败，由调用方决定错误策略。
  static int? _tryParseInt(dynamic data, String dataKey) {
    if (data is int) return data;
    if (data is num) return data.toInt();
    if (data is String) return int.tryParse(data);
    if (data is Map<String, dynamic>) {
      final value = data[dataKey];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
    }
    return null;
  }

  /// 将 ApiResponse 映射为对应的 Failure 类型
  static Failure _mapApiResponseToFailure<T>(ApiResponse<T> apiResponse) {
    return mapApiResponseToFailure(
      code: apiResponse.statusCode,
      message: apiResponse.message,
    );
  }
}
