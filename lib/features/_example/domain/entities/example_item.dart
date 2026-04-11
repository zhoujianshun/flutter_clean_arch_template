import 'package:freezed_annotation/freezed_annotation.dart';

part 'example_item.freezed.dart';
part 'example_item.g.dart';

/// 示例领域实体
///
/// 纯业务模型，字段类型以业务语义为准（如 [DateTime] 而非 API 的 String）。
/// 与 [ExampleItemDto] 的区别：
/// - DTO 字段名对齐 API JSON 键（snake_case, String 类型时间）
/// - Entity 使用业务友好的 Dart 类型（DateTime、枚举等）
@freezed
abstract class ExampleItem with _$ExampleItem {
  const factory ExampleItem({
    required String id,
    required String title,
    String? description,
    @Default(false) bool isCompleted,
    DateTime? createdAt,
  }) = _ExampleItem;

  factory ExampleItem.fromJson(Map<String, dynamic> json) =>
      _$ExampleItemFromJson(json);
}
