import 'package:flutter_clean_arch_template/core/errors/exceptions.dart';
import 'package:flutter_clean_arch_template/core/errors/failures.dart';

/// 将异常映射为失败
Failure mapExceptionToFailure(AppException exception) {
  return switch (exception) {
    NetworkException() => NetworkFailure(
      message: exception.message,
      code: exception.code ?? -1,
    ),
    AuthException() => AuthFailure(
      message: exception.message,
      code: exception.code ?? 401,
    ),
    PermissionException() => PermissionFailure(
      message: exception.message,
      code: exception.code ?? 403,
    ),
    ValidationException() => ValidationFailure(
      message: exception.message,
      code: exception.code ?? 400,
    ),
    CacheException() => CacheFailure(
      message: exception.message,
      code: exception.code ?? -2,
    ),
    ServerException() => ServerFailure(
      message: exception.message,
      code: exception.code ?? 500,
    ),
    _ => UnknownFailure(
      message: exception.message,
      code: exception.code ?? -999,
    ),
  };
}

/// 将 ApiResponse 映射为对应的 Failure 类型
Failure mapApiResponseToFailure({required int code, required String message}) {
  switch (code) {
    case 400:
      return ValidationFailure(message: message, code: code);
    case 401:
      return AuthFailure(message: message, code: code);
    case 403:
      return PermissionFailure(message: message, code: code);
    case 404:
    case 422:
      return ValidationFailure(message: message, code: code);
    case 500:
    case 502:
    case 503:
    case 504:
      return ServerFailure(message: message, code: code);
    default:
      return ServerFailure(message: message, code: code);
  }
}
