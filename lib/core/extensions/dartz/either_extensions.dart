import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_clean_arch_template/core/errors/failures.dart';

extension EitherExtensions<L, R> on Either<L, R> {
  /// 获取右侧值，如果是左侧则返回 null
  R? get rightOrNull => fold((_) => null, (r) => r);

  /// 获取左侧值，如果是右侧则返回 null
  L? get leftOrNull => fold((l) => l, (_) => null);

  /// 是否是成功结果
  bool get isRight => fold((_) => false, (_) => true);

  /// 是否是失败结果
  bool get isLeft => fold((_) => true, (_) => false);

  /// 当是右侧值时执行操作
  Either<L, R> onRight(void Function(R) action) {
    return fold(
      Left.new,
      (r) {
        action(r);
        return Right(r);
      },
    );
  }

  /// 当是左侧值时执行操作
  Either<L, R> onLeft(void Function(L) action) {
    return fold(
      (l) {
        action(l);
        return Left(l);
      },
      Right.new,
    );
  }
}

extension EitherToAsync<L, R> on Either<L, R> {
  /// 将 Either 转换为 AsyncValue
  /// 修复：确保 error 的参数类型为 Object
  AsyncValue<R> toAsyncValue() {
    return fold(
      (failure) {
        if (failure is Object) {
          return AsyncValue.error(failure, StackTrace.current);
        }
        return AsyncValue.error(UnknownFailure(message: 'Unknown error: $failure'), StackTrace.current);
      },
      AsyncValue.data,
    );
  }
}
