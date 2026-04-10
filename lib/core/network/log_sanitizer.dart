import 'dart:math';

/// 日志脱敏工具
///
/// 对网络请求/响应中的敏感信息进行脱敏处理，
/// 避免 token、手机号等隐私数据泄漏到日志系统。
class LogSanitizer {
  LogSanitizer._();

  static const _sensitiveHeaderKeys = {
    'authorization',
    'cookie',
    'set-cookie',
    'x-auth-token',
  };

  static const _sensitiveBodyKeys = {
    'token',
    'access_token',
    'accessToken',
    'refresh_token',
    'refreshToken',
    'password',
    'smsCode',
    'phone',
    'phonenumber',
    'idCard',
  };

  static final _random = Random();

  /// 生成请求追踪 ID（8 位十六进制）
  static String generateRequestId() {
    return _random.nextInt(0xFFFFFFFF).toRadixString(16).padLeft(8, '0');
  }

  /// 脱敏请求/响应头
  static Map<String, dynamic> sanitizeHeaders(Map<String, dynamic> headers) {
    return headers.map((key, value) {
      if (_sensitiveHeaderKeys.contains(key.toLowerCase())) {
        final str = value.toString();
        return MapEntry(key, _mask(str));
      }
      return MapEntry(key, value);
    });
  }

  /// 脱敏响应体（仅处理顶层 Map）
  static dynamic sanitizeBody(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data.map((key, value) {
        if (_sensitiveBodyKeys.contains(key)) {
          return MapEntry(key, _mask(value.toString()));
        }
        return MapEntry(key, value);
      });
    }
    return data;
  }

  /// 遮罩字符串：保留前 3 位和后 2 位，中间用 *** 替代
  static String _mask(String value) {
    if (value.length <= 6) return '***';
    return '${value.substring(0, 3)}***${value.substring(value.length - 2)}';
  }
}
