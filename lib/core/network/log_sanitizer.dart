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
    'accesstoken',
    'refresh_token',
    'refreshtoken',
    'password',
    'secret',
    'api_key',
    'apikey',
    'smscode',
    'sms_code',
    'phone',
    'phone_number',
    'phonenumber',
    'idcard',
    'id_card',
    'email',
    'credit_card',
    'creditcard',
    'bank_account',
    'bankaccount',
    'cvv',
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

  /// 脱敏请求/响应体（递归处理 Map/List）
  static dynamic sanitizeBody(dynamic data) {
    return _sanitizeValue(data);
  }

  static dynamic _sanitizeValue(dynamic value) {
    if (value is Map) {
      final sanitized = <String, dynamic>{};
      for (final entry in value.entries) {
        final key = entry.key.toString();
        final entryValue = entry.value;
        if (_isSensitiveBodyKey(key)) {
          sanitized[key] = _mask(entryValue?.toString() ?? '');
        } else {
          sanitized[key] = _sanitizeValue(entryValue);
        }
      }
      return sanitized;
    }

    if (value is List) {
      return value.map(_sanitizeValue).toList(growable: false);
    }

    return value;
  }

  static bool _isSensitiveBodyKey(String key) {
    return _sensitiveBodyKeys.contains(key.toLowerCase());
  }

  /// 遮罩字符串：保留前 3 位和后 2 位，中间用 *** 替代
  static String _mask(String value) {
    if (value.length <= 6) return '***';
    return '${value.substring(0, 3)}***${value.substring(value.length - 2)}';
  }
}
