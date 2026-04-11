import 'package:flutter_clean_arch_template/features/_example/data/models/example_item_dto.dart';
import 'package:flutter_clean_arch_template/features/_example/domain/entities/example_item.dart';

/// DTO → Domain Entity 映射扩展
extension ExampleItemDtoMapper on ExampleItemDto {
  ExampleItem toEntity() {
    return ExampleItem(
      id: id,
      title: title,
      description: description,
      isCompleted: isCompleted,
      createdAt: createdAt != null ? DateTime.tryParse(createdAt!) : null,
    );
  }
}

extension ExampleItemDtoListMapper on List<ExampleItemDto> {
  List<ExampleItem> toEntities() => map((dto) => dto.toEntity()).toList();
}
