import 'package:dartz/dartz.dart';
import 'package:flutter_clean_arch_template/core/errors/failures.dart';
import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';

/// Repository 层日志 Mixin
///
/// 提供两种调用包装，按需使用：
/// - [loggedCall] 纯日志，不带 try-catch（DataSource 已由 BaseAPI 处理异常）
/// - [safeCall] 日志 + try-catch 安全网（本地存储等可能抛异常的场景）
mixin RepositoryLoggerMixin {
  /// 纯日志包装，不带 try-catch
  ///
  /// 适用于直接调用 DataSource 的场景，因为 BaseAPI 已将异常转为 Either
  Future<Either<Failure, T>> loggedCall<T>(
    String operationName,
    Future<Either<Failure, T>> Function() action,
  ) async {
    AppLogger.d('[$operationName] 开始执行');
    final result = await action();
    result.fold(
      (failure) => AppLogger.w('[$operationName] 失败: ${failure.message}'),
      (_) => AppLogger.d('[$operationName] 成功'),
    );
    return result;
  }

  /// 带 try-catch 安全网的日志包装
  ///
  /// 适用于包含本地存储（Hive/SharedPrefs）等可能抛异常操作的场景
  Future<Either<Failure, T>> safeCall<T>(
    String operationName,
    Future<Either<Failure, T>> Function() action,
  ) async {
    try {
      AppLogger.d('[$operationName] 开始执行');
      final result = await action();
      result.fold(
        (failure) => AppLogger.w('[$operationName] 失败: ${failure.message}'),
        (_) => AppLogger.d('[$operationName] 成功'),
      );
      return result;
    } catch (e, stackTrace) {
      AppLogger.e('[$operationName] 未预期异常', error: e, stackTrace: stackTrace);
      return Left(UnknownFailure(message: '$operationName失败: $e'));
    }
  }
}
