import 'package:talker_flutter/talker_flutter.dart';

/// 敏感信息过滤器
/// 用于屏蔽日志中的敏感数据
class SensitiveFilter {
  /// 敏感关键词列表
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
      result = result.replaceAllMapped(
        RegExp('$key=[^&\\s]*', caseSensitive: false),
        (match) => '$key=$mask',
      );

      // 匹配 Header 格式: key: value
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
        error,
        stackTrace: data.stackTrace,
        message: filteredMessage,
      );
    } else if (data is TalkerException) {
      final exception = data.exception;
      if (exception == null) return data;
      if (exception is! Exception) {
        // 如果不是Exception类型，包装成Exception
        return TalkerException(
          Exception(exception.toString()),
          stackTrace: data.stackTrace,
          message: filteredMessage,
        );
      }
      return TalkerException(
        exception,
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
