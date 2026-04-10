import 'package:freezed_annotation/freezed_annotation.dart';

part 'example_item.freezed.dart';
part 'example_item.g.dart';

@freezed
abstract class ExampleItem with _$ExampleItem {
  const factory ExampleItem({
    required String id,
    required String title,
    String? description,
    @Default(false) bool isCompleted,
    DateTime? createdAt,
  }) = _ExampleItem;

  factory ExampleItem.fromJson(Map<String, dynamic> json) => _$ExampleItemFromJson(json);
}
