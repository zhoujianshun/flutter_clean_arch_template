import 'package:dartz/dartz.dart';
import 'package:flutter_clean_arch_template/core/errors/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Either 常用取值与副作用扩展
///
/// 注意：dartz 自带 `isRight()` / `isLeft()` **方法**（带括号），
/// 本扩展不再提供同名 getter，调用时请使用 dartz 原生方法，避免歧义。
extension EitherExtensions<L, R> on Either<L, R> {
  /// 获取右侧值，如果是左侧则返回 null
  R? get rightOrNull => fold((_) => null, (r) => r);

  /// 获取左侧值，如果是右侧则返回 null
  L? get leftOrNull => fold((l) => l, (_) => null);

  /// 当是右侧值时执行操作（tap 语义：不改变原值）
  Either<L, R> onRight(void Function(R) action) {
    return fold(
      Left.new,
      (r) {
        action(r);
        return Right(r);
      },
    );
  }

  /// 当是左侧值时执行操作（tap 语义：不改变原值）
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

/// Either → Riverpod AsyncValue 转换
extension EitherToAsync<L, R> on Either<L, R> {
  /// 将 Either 转换为 AsyncValue，供 AsyncValueWidget 筍直接消费
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
