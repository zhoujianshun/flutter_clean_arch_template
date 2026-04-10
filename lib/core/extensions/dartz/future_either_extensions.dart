import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_clean_arch_template/core/errors/failures.dart';

extension FutureEitherExtensions<L, R> on Future<Either<L, R>> {
  /// 异步 map 操作
  Future<Either<L, T>> mapAsync<T>(Future<T> Function(R) mapper) async {
    final result = await this;
    return result.fold(
      Left.new,
      (r) async => Right(await mapper(r)),
    );
  }

  /// 转换为 AsyncValue
  Future<AsyncValue<R>> toAsyncValue() async {
    try {
      final result = await this;
      return result.fold(
        (failure) {
          if (failure is Object) {
            return AsyncValue.error(failure, StackTrace.current);
          }
          return AsyncValue.error(UnknownFailure(message: 'Unknown error: $failure'), StackTrace.current);
        },
        AsyncValue.data,
      );
    } catch (error, stackTrace) {
      return AsyncValue.error(error, stackTrace);
    }
  }

  /// 异步 flatMap
  Future<Either<L, T>> flatMapAsync<T>(
    Future<Either<L, T>> Function(R) mapper,
  ) async {
    final result = await this;
    return result.fold(
      Left.new,
      (value) => mapper(value),
    );
  }
}
