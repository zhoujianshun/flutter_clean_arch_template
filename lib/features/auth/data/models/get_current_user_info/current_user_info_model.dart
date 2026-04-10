import 'package:freezed_annotation/freezed_annotation.dart';

part 'current_user_info_model.freezed.dart';
part 'current_user_info_model.g.dart';

@freezed
abstract class CurrentUserInfoModel with _$CurrentUserInfoModel {
  const factory CurrentUserInfoModel({
    String? userId,
    String? nickName,
    String? phonenumber,
    String? avatar,
  }) = _CurrentUserInfoModel;

  factory CurrentUserInfoModel.fromJson(Map<String, dynamic> json) => _$CurrentUserInfoModelFromJson(json);
}
