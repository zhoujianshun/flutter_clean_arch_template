import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_info_model.freezed.dart';
part 'auth_info_model.g.dart';

@freezed
abstract class AuthInfoModel with _$AuthInfoModel {
  const factory AuthInfoModel({
    @JsonKey(name: 'access_token') required String accessToken,
    @JsonKey(name: 'refresh_token') String? refreshToken,
    @JsonKey(name: 'expires_in') int? expiresIn,
  }) = _AuthInfoModel;

  factory AuthInfoModel.fromJson(Map<String, dynamic> json) => _$AuthInfoModelFromJson(json);
}
