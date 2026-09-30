import 'package:freezed_annotation/freezed_annotation.dart';

part 'failures.freezed.dart';

/// 失败类型的联合类型
@freezed
sealed class Failure with _$Failure {
  /// 服务器错误
  const factory Failure.server({
    required String message,
    @Default(500) int code,
  }) = ServerFailure;

  /// 网络错误
  const factory Failure.network({
    required String message,
    @Default(-1) int code,
  }) = NetworkFailure;

  /// 缓存错误
  const factory Failure.cache({
    required String message,
    @Default(-2) int code,
  }) = CacheFailure;

  /// 验证错误
  const factory Failure.validation({
    required String message,
    @Default(400) int code,
  }) = ValidationFailure;

  /// 认证错误
  const factory Failure.auth({
    required String message,
    @Default(401) int code,
  }) = AuthFailure;

  /// 权限错误
  const factory Failure.permission({
    required String message,
    @Default(403) int code,
  }) = PermissionFailure;

  /// 未知错误
  const factory Failure.unknown({
    required String message,
    @Default(-999) int code,
  }) = UnknownFailure;
}
