import 'package:freezed_annotation/freezed_annotation.dart';

part 'todo_model.freezed.dart';
part 'todo_model.g.dart';

/// 务实型：Model 直接作为 API 响应模型 + 业务模型共用
///
/// 小型项目中 API 字段与 UI 需求一致时，无需拆分 DTO / Entity。
/// 直接在 Domain Repository 接口中使用此 Model。
@freezed
abstract class TodoModel with _$TodoModel {
  const factory TodoModel({
    required String id,
    required String title,
    String? description,
    @JsonKey(name: 'is_completed') @Default(false) bool isCompleted,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _TodoModel;

  factory TodoModel.fromJson(Map<String, dynamic> json) =>
      _$TodoModelFromJson(json);
}
