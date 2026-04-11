import 'package:freezed_annotation/freezed_annotation.dart';

part 'example_item_dto.freezed.dart';
part 'example_item_dto.g.dart';

/// API 响应的原始数据传输对象 (DTO)
///
/// 字段名与 API JSON 键一一对应。
/// 在 Repository 层转换为 Domain Entity [ExampleItem]。
@freezed
abstract class ExampleItemDto with _$ExampleItemDto {
  const factory ExampleItemDto({
    required String id,
    required String title,
    String? description,
    @JsonKey(name: 'is_completed') @Default(false) bool isCompleted,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _ExampleItemDto;

  factory ExampleItemDto.fromJson(Map<String, dynamic> json) =>
      _$ExampleItemDtoFromJson(json);
}
