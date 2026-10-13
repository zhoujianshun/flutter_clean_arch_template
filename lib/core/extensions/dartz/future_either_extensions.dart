import 'package:dartz/dartz.dart';
import 'package:flutter_clean_arch_template/core/extensions/dartz/either_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

extension FutureEitherExtensions<L, R> on Future<Either<L, R>> {
  /// 异步 map 操作
  Future<Either<L, T>> mapAsync<T>(Future<T> Function(R) mapper) async {
    final result = await this;
    // fold 的 B 被推断为 FutureOr<Either<L, T>>（右分支是 async 闭包），
    // 显式 await 完成展开，避免依赖 async 函数的隐式 flatten
    return await result.fold(Left.new, (r) async => Right(await mapper(r)));
  }

  /// 转换为 AsyncValue
  Future<AsyncValue<R>> toAsyncValue() async {
    try {
      final result = await this;
      // await 确保（若未来闭包变为 async）其错误仍被下方 catch 捕获
      return await result.fold(failureToAsyncError, AsyncValue.data);
    } catch (error, stackTrace) {
      return AsyncValue.error(error, stackTrace);
    }
  }

  /// 异步 flatMap
  Future<Either<L, T>> flatMapAsync<T>(Future<Either<L, T>> Function(R) mapper) async {
    final result = await this;
    return await result.fold(Left.new, mapper);
  }
}
