/// 数字转字符串转换器
library;

import 'package:freezed_annotation/freezed_annotation.dart';

/// 数字转字符串转换器
class Number2StringConverter implements JsonConverter<String, dynamic> {
  const Number2StringConverter();

  @override
  String fromJson(dynamic number) {
    return '$number';
  }

  @override
  dynamic toJson(String string) => string;
}
