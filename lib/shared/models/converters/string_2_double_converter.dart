import 'package:freezed_annotation/freezed_annotation.dart';

/// 字符串转double
class String2DoubleConverter implements JsonConverter<double, String> {
  const String2DoubleConverter();

  @override
  double fromJson(String string) => double.parse(string);

  @override
  String toJson(double number) => number.toString();
}
