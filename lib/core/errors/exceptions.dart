/// 抽象异常类
abstract class AppException implements Exception {
  const AppException({
    required this.message,
    this.code,
  });

  final String message;
  final int? code;

  @override
  String toString() => 'AppException(message: $message, code: $code)';
}

/// 服务器异常
class ServerException extends AppException {
  const ServerException({
    required super.message,
    super.code,
  });

  @override
  String toString() => 'ServerException(message: $message, code: $code)';
}

/// 网络异常
class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.code,
  });

  @override
  String toString() => 'NetworkException(message: $message, code: $code)';
}

/// 缓存异常
class CacheException extends AppException {
  const CacheException({
    required super.message,
    super.code,
  });

  @override
  String toString() => 'CacheException(message: $message, code: $code)';
}

/// 验证异常
class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.code,
  });
}

/// 权限异常
class PermissionException extends AppException {
  const PermissionException({
    required super.message,
    super.code,
  });

  @override
  String toString() => 'PermissionException(message: $message, code: $code)';
}

/// 认证异常
class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.code,
  });

  @override
  String toString() => 'AuthException(message: $message, code: $code)';
}

/// 解析异常
class ParsingException extends AppException {
  const ParsingException({
    required super.message,
    super.code,
  });

  @override
  String toString() => 'ParsingException(message: $message, code: $code)';
}

class StorageException extends AppException {
  const StorageException({
    required super.message,
    super.code,
    this.cause,
    this.stackTrace,
  });

  /// Original exception that caused this error
  final Object? cause;

  /// Stack trace of the original error
  final StackTrace? stackTrace;

  @override
  String toString() {
    final buffer = StringBuffer('StorageException(message: $message');
    if (code != null) {
      buffer.write(', code: $code');
    }
    if (cause != null) {
      buffer.write(', cause: $cause');
    }
    buffer.write(')');
    return buffer.toString();
  }
}
