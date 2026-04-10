import 'package:freezed_annotation/freezed_annotation.dart';

/// 字符串转日期时间
class String2DatetimeConverter implements JsonConverter<DateTime, String> {
  const String2DatetimeConverter();

  @override
  DateTime fromJson(String timestamp) {
    return DateTime.parse(timestamp);
  }

  @override
  String toJson(DateTime date) => date.toIso8601String();
}
