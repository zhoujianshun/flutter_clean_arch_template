import 'package:talker_flutter/talker_flutter.dart';

/// 敏感信息过滤器
/// 用于屏蔽日志中的敏感数据
class SensitiveFilter {
  /// 敏感关键词列表
  ///
  /// 与 core/network/log_sanitizer.dart 的 _sensitiveBodyKeys 保持并集
  /// （此处偏正则场景，LogSanitizer 偏结构化场景），修改任一侧时同步另一侧。
  static const sensitiveKeys = [
    'password',
    'passwd',
    'pwd',
    'token',
    'access_token',
    'refresh_token',
    'api_key',
    'apikey',
    'secret',
    'api_secret',
    'private_key',
    'authorization',
    'auth',
    'cookie',
    'session',
    'credit_card',
    'card_number',
    'cvv',
    'ssn',
    'id_card',
    // PII（并集补充，来自 LogSanitizer）
    'phone',
    'phone_number',
    'phonenumber',
    'mobile',
    'idcard',
    'idnumber',
    'id_number',
    'email',
    'bank_account',
    'bankaccount',
    'realname',
    'real_name',
    'address',
    // password 族变体（改密码接口常见字段）
    'new_password',
    'old_password',
    'confirm_password',
  ];

  /// 屏蔽占位符
  static const String mask = '***HIDDEN***';

  /// 过滤敏感信息
  static String filterSensitiveData(String data) {
    var result = data;

    for (final key in sensitiveKeys) {
      // 匹配 JSON 格式: "key": "value"
      result = result.replaceAllMapped(
        RegExp('"$key"\\s*:\\s*"[^"]*"', caseSensitive: false),
        (match) => '"$key": "$mask"',
      );

      // 匹配 JSON 格式: 'key': 'value'
      result = result.replaceAllMapped(
        RegExp("'$key'\\s*:\\s*'[^']*'", caseSensitive: false),
        (match) => "'$key': '$mask'",
      );

      // 匹配 URL 参数: key=value
      // 注意：故意不加 \b 词边界——'_' 是单词字符，\b 会导致
      // mobile_phone= / user_email= 等复合 key 匹配失败（漏脱敏）；
      // 而模式要求 key 后紧跟 '='，auth 也匹配不到 author=，
      // 无误匹配风险。宁多遮蔽，不漏遮蔽。
      result = result.replaceAllMapped(
        RegExp('$key=[^&\\s]*', caseSensitive: false),
        (match) => '$key=$mask',
      );

      // 匹配 Header 格式: key: value（同上，不加词边界）
      result = result.replaceAllMapped(
        RegExp('$key\\s*:\\s*[^\\n]*', caseSensitive: false),
        (match) => '$key: $mask',
      );
    }

    return result;
  }

  /// 过滤 TalkerData 中的敏感信息
  static TalkerData filterTalkerData(TalkerData data) {
    // 过滤消息内容
    final message = data.message ?? '';
    final filteredMessage = filterSensitiveData(message);

    // 根据不同类型创建新的 TalkerData
    if (data is TalkerLog) {
      return TalkerLog(
        filteredMessage,
        title: data.title,
        stackTrace: data.stackTrace,
        pen: data.pen,
      );
    } else if (data is TalkerError) {
      final error = data.error;
      if (error == null) return data;
      return TalkerError(
        _SanitizedError(filterSensitiveData(error.toString())),
        stackTrace: data.stackTrace,
        message: filteredMessage,
      );
    } else if (data is TalkerException) {
      final exception = data.exception;
      if (exception == null) return data;
      return TalkerException(
        Exception(filterSensitiveData(exception.toString())),
        stackTrace: data.stackTrace,
        message: filteredMessage,
      );
    }

    // 默认返回原数据
    return data;
  }

  /// 屏蔽 Map 中的敏感信息
  static Map<String, dynamic> maskSensitiveMap(Map<String, dynamic> data) {
    final result = <String, dynamic>{};

    data.forEach((key, value) {
      final lowerKey = key.toLowerCase();
      final isSensitive = sensitiveKeys.any(lowerKey.contains);

      if (isSensitive) {
        result[key] = mask;
      } else if (value is Map<String, dynamic>) {
        result[key] = maskSensitiveMap(value);
      } else if (value is List) {
        result[key] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return maskSensitiveMap(item);
          }
          return item;
        }).toList();
      } else {
        result[key] = value;
      }
    });

    return result;
  }
}

final class _SanitizedError extends Error {
  _SanitizedError(this.message);

  final String message;

  @override
  String toString() => message;
}
